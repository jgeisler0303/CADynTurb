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

function sim_json = set_up_acados_sim_json(obj, simulink_opts)
    if ~exist('simulink_opts', 'var')
        simulink_opts= get_acados_simulink_opts;
    end

    model = obj.model_struct;
    % create
    sim_json = acados_sim_json(simulink_opts);

    % general
    sim_json.model.name = model.name;
    
    %% dims
    % path
    sim_json.dims.nx = model.dim_nx;
    sim_json.dims.nu = model.dim_nu;
    sim_json.dims.nz = model.dim_nz;
    sim_json.dims.np = model.dim_np;
    if isfield(model, 'dim_ny')
        sim_json.dims.ny = model.dim_ny;
    end
    
    % parameters
    if model.dim_np > 0
        sim_json.parameter_values = zeros(model.dim_np, 1);
    end

    %% dynamics
    if strcmp(obj.opts_struct.method, 'erk')
        sim_json.model.f_expl_expr = model.dyn_expr_f;
    elseif strcmp(obj.opts_struct.method, 'irk')
        sim_json.model.f_impl_expr = model.dyn_expr_f;
    elseif strcmp(obj.opts_struct.method, 'discrete')
        sim_json.model.dyn_ext_fun_type = model.dyn_ext_fun_type;
        if strcmp(model.ext_fun_type, 'casadi')
            sim_json.model.f_phi_expr = model.dyn_expr_phi;
        elseif strcmp(model.dyn_ext_fun_type, 'generic')
            sim_json.model.dyn_source_discrete = model.dyn_source_discrete;
            if isfield(model, 'dyn_disc_fun_jac_hess')
                sim_json.model.dyn_disc_fun_jac_hess = model.dyn_disc_fun_jac_hess;
            end
            if isfield(model, 'dyn_disc_fun_jac')
                sim_json.model.dyn_disc_fun_jac = model.dyn_disc_fun_jac;
            end
            sim_json.model.dyn_disc_fun = model.dyn_disc_fun;
        end
    elseif strcmp(obj.opts_struct.method, 'irk_gnsf')
        sim_json.model.gnsf.A = model.dyn_gnsf_A;
        sim_json.model.gnsf.B = model.dyn_gnsf_B;
        sim_json.model.gnsf.C = model.dyn_gnsf_C;
        sim_json.model.gnsf.E = model.dyn_gnsf_E;
        sim_json.model.gnsf.c = model.dyn_gnsf_c;
        sim_json.model.gnsf.A_LO = model.dyn_gnsf_A_LO;
        sim_json.model.gnsf.B_LO = model.dyn_gnsf_B_LO;
        sim_json.model.gnsf.E_LO = model.dyn_gnsf_E_LO;
        sim_json.model.gnsf.c_LO = model.dyn_gnsf_c_LO;

        sim_json.model.gnsf.L_x = model.dyn_gnsf_L_x;
        sim_json.model.gnsf.L_u = model.dyn_gnsf_L_u;
        sim_json.model.gnsf.L_xdot = model.dyn_gnsf_L_xdot;
        sim_json.model.gnsf.L_z = model.dyn_gnsf_L_z;

        sim_json.model.gnsf.expr_phi = model.dyn_gnsf_expr_phi;
        sim_json.model.gnsf.expr_f_lo = model.dyn_gnsf_expr_f_lo;

        sim_json.model.gnsf.ipiv_x = model.dyn_gnsf_ipiv_x;
        sim_json.model.gnsf.idx_perm_x = model.dyn_gnsf_idx_perm_x;
        sim_json.model.gnsf.ipiv_z = model.dyn_gnsf_ipiv_z;
        sim_json.model.gnsf.idx_perm_z = model.dyn_gnsf_idx_perm_z;
        sim_json.model.gnsf.ipiv_f = model.dyn_gnsf_ipiv_f;
        sim_json.model.gnsf.idx_perm_f = model.dyn_gnsf_idx_perm_f;

        sim_json.model.gnsf.nontrivial_f_LO = model.dyn_gnsf_nontrivial_f_LO;
        sim_json.model.gnsf.purely_linear = model.dyn_gnsf_purely_linear;

        sim_json.model.gnsf.y = model.sym_gnsf_y;
        sim_json.model.gnsf.uhat = model.sym_gnsf_uhat;
    else
        error(['integrator ', obj.opts_struct.sim_method, ' not support for templating backend.'])
    end

    sim_json.model.x = model.sym_x;
    sim_json.model.u = model.sym_u;
    sim_json.model.z = model.sym_z;
    sim_json.model.xdot = model.sym_xdot;
    sim_json.model.p = model.sym_p;

end