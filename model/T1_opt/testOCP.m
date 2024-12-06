%%
clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
run(fullfile(model_dir, '../../matlab/setupCADynTurb'))

fst_file= '../../5MW_Baseline/5MW_Land_DLL_WTurb.fst';

model_name= 'T1_opt';
gen_dir= fullfile(model_dir, 'generated');

cd(gen_dir)

%% discretization
N = 80;
T = 8; % time horizon length
x0 = [0; 0; 0; 1.2];

nlp_solver = 'sqp'; % sqp, sqp_rti
qp_solver = 'partial_condensing_hpipm'; % full_condensing_hpipm, partial_condensing_hpipm, full_condensing_qpoases
qp_solver_cond_N = 5; % for partial condensing
% integrator type
sim_method = 'irk'; % erk, irk, irk_gnsf

%% model dynamics
model = T1_opt_acados;
nx = model.nx;
nu = model.nu;

%% model to create the solver
ocp_model = acados_ocp_model();

%% acados ocp model
ocp_model.set('name', model.name);
ocp_model.set('T', T);

% symbolics
ocp_model.set('sym_x', model.sym_x);
ocp_model.set('sym_u', model.sym_u);
ocp_model.set('sym_xdot', model.sym_xdot);
ocp_model.set('sym_p', model.sym_p);

% cost
expr_ext_cost_e = (model.sym_x(4)-1.2)^2;
expr_ext_cost = expr_ext_cost_e + model.sym_u(2)^2;
ocp_model.set('cost_type', 'ext_cost');
ocp_model.set('cost_expr_ext_cost', expr_ext_cost);
ocp_model.set('cost_type_e', 'ext_cost');
ocp_model.set('cost_expr_ext_cost_e', expr_ext_cost_e);

% dynamics
if (strcmp(sim_method, 'erk'))
    ocp_model.set('dyn_type', 'explicit');
    ocp_model.set('dyn_expr_f', model.expr_f_expl);
else % irk irk_gnsf
    ocp_model.set('dyn_type', 'implicit');
    ocp_model.set('dyn_expr_f', model.expr_f_impl);
end

% constraints
ocp_model.set('constr_type', 'bgh');
expr_h= model.sym_u;
ocp_model.set('constr_expr_h', expr_h);
ocp_model.set('constr_lh', [0 0]); % lower bound on h
ocp_model.set('constr_uh', [45e3 90]);  % upper bound on h

ocp_model.set('constr_x0', x0);
% ... see ocp_model.model_struct to see what other fields can be set

%% acados ocp set opts
ocp_opts = acados_ocp_opts();
ocp_opts.set('param_scheme_N', N);
ocp_opts.set('nlp_solver', nlp_solver);
ocp_opts.set('sim_method', sim_method);
ocp_opts.set('qp_solver', qp_solver);
ocp_opts.set('qp_solver_cond_N', qp_solver_cond_N);
% ... see ocp_opts.opts_struct to see what other fields can be set

%% create ocp solver
ocp = acados_ocp(ocp_model, ocp_opts);

x_traj_init = zeros(nx, N+1);
u_traj_init = zeros(nu, N);

%% call ocp solver
% update initial state
ocp.set('constr_x0', x0);

% set trajectory initialization
ocp.set('init_x', x_traj_init);
ocp.set('init_u', u_traj_init);
ocp.set('init_pi', zeros(nx, N))

% set parameter
run(fullfile(gen_dir, "model_parameters.m"))
ap= acados_params(parameter_names, param);
ocp.set('p', ap);

% change values for specific shooting node using:
%   ocp.set('field', value, optional: stage_index)
ocp.set('constr_lbx', x0, 0)

% solve
ocp.solve();
% get solution
utraj = ocp.get('u');
xtraj = ocp.get('x');

status = ocp.get('status'); % 0 - success
ocp.print('stat')

%% Plots
run(fullfile(gen_dir, "model_indices.m"))
ts = linspace(0, T, N+1);
clf
States = [dof_names; dof_d_names];
tiledlayout(nx+nu, 1)
for i=1:length(States)
    nexttile
    plot(ts, xtraj(i,:)); grid on;
    ylabel(States{i});
    xlabel('t [s]')
end

for i=1:nu
    nexttile
    plot(ts(1:end-1), utraj(i,:)); grid on;
    ylabel(input_names{i});
    xlabel('t [s]')
end