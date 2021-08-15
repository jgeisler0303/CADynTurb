%
% Copyright 2019 Gianluca Frison, Dimitris Kouzoupis, Robin Verschueren,
% Andrea Zanelli, Niels van Duijkeren, Jonathan Frey, Tommaso Sartor,
% Branimir Novoselnik, Rien Quirynen, Rezart Qelibari, Dang Doan,
% Jonas Koenemann, Yutao Chen, Tobias Schöls, Jonas Schlagenhauf, Moritz Diehl
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

function render_acados_sim_templates(acados_ocp_nlp_json_file)

    acados_root_dir = getenv('ACADOS_INSTALL_DIR');
    acados_template_folder = fullfile(acados_root_dir,...
                          'interfaces', 'acados_template', 'acados_template');

    %% check if t_renderer is available -> download if not
    if ispc()
        t_renderer_location = fullfile(acados_root_dir,'bin','t_renderer.exe');
    else
        t_renderer_location = fullfile(acados_root_dir,'bin','t_renderer');
    end

    if ~exist( t_renderer_location, 'file' )
        set_up_t_renderer( t_renderer_location )
    end

    %% load json data
    % if is_octave()
    acados_ocp = loadjson(fileread(acados_ocp_nlp_json_file));
    % else % Matlab
    %     acados_ocp = jsondecode(fileread(acados_ocp_nlp_json_file));
    % end
    % get model name from json file
    model_name = acados_ocp.model.name;

    %% render templates
    template_dir = fullfile(acados_template_folder, 'c_templates_tera','*');
    json_fullfile = fullfile(pwd, acados_ocp_nlp_json_file);
    main_dir = pwd;
    chdir('c_generated_code');

    % main_sim
    template_file = 'main_sim.in.c';
    out_file = ['main_sim_', model_name, '.c'];
    render_file( json_fullfile, template_dir, template_file, out_file, t_renderer_location )

    % sim_solver
    template_file = 'acados_sim_solver.in.c';
    out_file = ['acados_sim_solver_', model_name, '.c'];
    render_file( json_fullfile, template_dir, template_file, out_file, t_renderer_location )

    template_file = 'acados_sim_solver.in.h';
    out_file = ['acados_sim_solver_', model_name, '.h'];
    render_file( json_fullfile, template_dir, template_file, out_file, t_renderer_location )

    template_file = 'acados_sim_solver_sfun.in.c';
    out_file = ['acados_sim_solver_sfunction_', model_name, '.c'];
    render_file( json_fullfile, template_dir, template_file, out_file, t_renderer_location )

    template_file = 'make_sfun_sim.in.m';
    out_file = 'make_sfun_sim.m';
    render_file( json_fullfile, template_dir, template_file, out_file, t_renderer_location )

    % headers and custom C-code files
    c_dir = pwd;
    chdir([model_name, '_model']);
    template_file = 'model.in.h';
    out_file = [model_name, '_model.h'];
    render_file( json_fullfile, template_dir, template_file, out_file, t_renderer_location )
    cd(c_dir);

    % Makefile
    template_file = 'Makefile_sim.in';
    out_file = 'Makefile';
    render_file( json_fullfile, fullfile(fileparts(mfilename('fullpath')), '*'), template_file, out_file, t_renderer_location )

    fprintf('Successfully rendered acados templates!\n');
    cd(main_dir)

end


%% auxilary functions
function render_file( json_fullfile, template_dir, template_file, out_file, ...
                      t_renderer_location )

    os_cmd = [t_renderer_location, ' "',...
        template_dir, '"', ' ', '"', template_file, '"', ' ', '"',...
        json_fullfile, '"', ' ', '"', out_file, '"'];

    [ status, result ] = system(os_cmd);
    if status
        cd ..
        error('rendering %s failed.\n command: %s\n returned status %d, got result:\n%s\n\n',...
            template_file, os_cmd, status, result);
    end
    % NOTE: this should return status != 0, maybe fix in tera renderer?
    if ~isempty(strfind( result, 'Error' )) % contains not implemented in Octave
        cd ..
        error('rendering %s failed.\n command: %s\n returned status %d, got result: %s',...
            template_file, os_cmd, status, result);
    end
end


function set_up_t_renderer( t_renderer_location )
    message = ['\nDear acados user, we could not find t_renderer binaries,',...
        '\n which are needed to export templated C code from ',...
        'Matlab.\n Press any key to proceed setting up the t_renderer automatically.',...
        '\n Press "n" or "N" to exit, if you wish to set up t_renderer yourself.\n',...
        '\n https://github.com/acados/tera_renderer/releases'];

    In = input(message,'s');

    if strcmpi( In, 'n')
        error('Please set up t_renderer yourself and try again');
    else
        t_renderer_version = 'v0.0.34';
        if isunix()
            suffix = '-linux';
        elseif ismac()
            suffix = '-osx';
        elseif ispc()
            suffix = '-windows';
        end
        acados_root_dir = getenv('ACADOS_INSTALL_DIR');

        tera_url = ['https://github.com/acados/tera_renderer/releases/download/', ...
                t_renderer_version '/t_renderer-', t_renderer_version, suffix];
        destination = fullfile(acados_root_dir, 'bin');
        tmp_file = websave(destination, tera_url);

        if ~exist(destination, 'dir')
            [~,~] = mkdir(destination);
        end

        movefile(tmp_file, t_renderer_location);

        if isunix() || ismac()
            % make executable
            system(['chmod a+x ', t_renderer_location]);
        end
        fprintf('\nSuccessfully set up t_renderer\n')
    end
end
