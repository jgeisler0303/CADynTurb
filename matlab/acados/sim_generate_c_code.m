%
% Copyright 2019 Gianluca Frison, Dimitris Kouzoupis, Robin Verschueren,
% Andrea Zanelli, Niels van Duijkeren, Jonathan Frey, Tommaso Sartor,
% Branimir Novoselnik, Rien Quirynen, Rezart Qelibari, Dang Doan,
% Jonas Koenemann, Yutao Chen, Tobias Schöls, Jonas Schlagenhauf, Moritz Diehl
% Jens Geisler (2021)
%
% This file is part of acados.
%
% The 2-Clause BSD License
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.;
%

function sim_generate_c_code(obj)
    acados_sim_json= set_up_acados_sim_json(obj);
    
    %% create folder
    if ~exist(fullfile(pwd,'c_generated_code'), 'dir')
        mkdir(fullfile(pwd, 'c_generated_code'))
    end
    %% generate C code for CasADi functions / copy external functions
    % dynamics
    if (strcmp(obj.model_struct.dyn_type, 'explicit'))
        generate_c_code_explicit_ode(acados_sim_json.model);
    elseif (strcmp(obj.model_struct.dyn_type, 'implicit'))
        if (strcmp(obj.opts_struct.method, 'irk'))
            opts.sens_hess = 'true';
            generate_c_code_implicit_ode(...
                acados_sim_json.model, opts);
        elseif (strcmp(obj.opts_struct.method, 'irk_gnsf'))
            generate_c_code_gnsf(...
                acados_sim_json.model);
        end
    elseif (strcmp(obj.model_struct.dyn_type, 'discrete'))
        generate_c_code_disc_dyn(acados_sim_json.model);
    end
    if strcmp(acados_sim_json.model.dyn_ext_fun_type, 'generic')
        copyfile( fullfile(pwd, acados_sim_json.model.dyn_source_discrete),...
            fullfile(pwd, 'c_generated_code', [obj.model_struct.name '_model']));
    end

    % set include and lib path
    acados_folder = getenv('ACADOS_INSTALL_DIR');
    acados_sim_json.acados_include_path = [acados_folder, '/include'];
    acados_sim_json.acados_lib_path = [acados_folder, '/lib'];

    %% remove CasADi objects from model
    model.name = acados_sim_json.model.name;
    model.dyn_ext_fun_type = acados_sim_json.model.dyn_ext_fun_type;
    model.dyn_source_discrete = acados_sim_json.model.dyn_source_discrete;
    model.dyn_disc_fun_jac_hess = acados_sim_json.model.dyn_disc_fun_jac_hess;
    model.dyn_disc_fun_jac = acados_sim_json.model.dyn_disc_fun_jac;
    model.dyn_disc_fun = acados_sim_json.model.dyn_disc_fun;
    acados_sim_json.model = model;
    %% post process numerical data (mostly cast scalars to 1-dimensional cells)
    dims = acados_sim_json.dims;

    %% load JSON layout
    acados_folder = getenv('ACADOS_INSTALL_DIR');
    json_layout_filename = fullfile(acados_folder, 'interfaces',...
                                   'acados_template','acados_template','acados_layout.json');
    % if is_octave()
    addpath(fullfile(acados_folder, 'external', 'jsonlab'))

    % parameter values
    acados_sim_json.parameter_values = reshape(num2cell(acados_sim_json.parameter_values), [ 1, dims.np]);

    %% dump JSON file
    % if is_octave()
        % savejson does not work for classes!
        % -> consider making the acados_sim_json properties structs directly.
        sim_json_struct = struct(acados_sim_json);
        disable_last_warning();
        sim_json_struct.dims = struct(sim_json_struct.dims);
        sim_json_struct.solver_options.Tsim= 10;
        sim_json_struct.solver_options.integrator_type= upper(obj.opts_struct.method);
        sim_json_struct.solver_options.sim_method_newton_iter= obj.opts_struct.newton_iter;
        sim_json_struct.solver_options.sim_method_num_stages= obj.opts_struct.num_stages;
        sim_json_struct.solver_options.sim_method_num_steps= obj.opts_struct.num_steps;        
        sim_json_struct.solver_options.sens_forw= obj.opts_struct.sens_forw;
        sim_json_struct.solver_options.sens_adj= obj.opts_struct.sens_adj;
        sim_json_struct.solver_options.sens_algebraic= obj.opts_struct.sens_algebraic;
        sim_json_struct.solver_options.sens_hess= obj.opts_struct.sens_hess;
        sim_json_struct.solver_options.output_z= obj.opts_struct.output_z;
        if isfield(obj.opts_struct, 'hessian_approx')
            sim_json_struct.solver_options.hessian_approx= obj.opts_struct.hessian_approx;
        else
            sim_json_struct.solver_options.hessian_approx= '';
        end
        sim_json_struct.problem_class= 'SIM';
        
        % add compilation information to json
        libs = loadjson(fileread(fullfile(acados_folder, 'lib', 'link_libs.json')));
        sim_json_struct.acados_link_libs = libs;
        if ismac
            sim_json_struct.os = 'mac';
        elseif isunix
            sim_json_struct.os = 'unix';
        else
            sim_json_struct.os = 'pc';
        end

        json_string = savejson('',sim_json_struct, 'ForceRootName', 0);
    % else % Matlab
    %     json_string = jsonencode(acados_sim_json);
    % end
    fid = fopen('acados_sim.json', 'w');
    if fid == -1, error('Cannot create JSON file'); end
    fwrite(fid, json_string, 'char');
    fclose(fid);
    %% render templated code
    render_acados_sim_templates('acados_sim.json')
    %% compile main
    acados_template_mex.compile_main()
end
