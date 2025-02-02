%%
clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
CADynTurb_dir= fullfile(model_dir, '../..');
run(fullfile(CADynTurb_dir, 'matlab/setupCADynTurb'))

model_name= 'T1_opt';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'cpp_direct', 'acados'};

%% generate and compile all source code
clc
cd(model_dir)
genCode([model_name '.mac'], gen_dir, files_to_generate, [], [], [], 1, 0);

%% set parameters
clc
cd(gen_dir)
load('params_config.mat')

model_parameters
[param, precalcNames]= T1_opt_pre_calc(p_);

ap= acados_params([parameter_names; precalcNames'], param);

%% make acados OCP
clc
cd(gen_dir)

% solver settings
N = 80;
T = 8; % time horizon length
x0 = [0; 0; 0; 1.2];


% model dynamics
acados_model_func= str2func([model_name '_acados']);
model= acados_model_func();
model.cost_expr_ext_cost_0= model.u(2)^2;
model.cost_expr_ext_cost= 10*model.x(3)^2 + (model.x(4)-1.2)^2 + 0.1*model.u(2)^2;
model.cost_expr_ext_cost_e= 10*(model.x(4)-1.2)^2;

nx = length(model.x); % state size
nu = length(model.u); % input size

% OCP formulation object
ocp = AcadosOcp();
ocp.model = model;

% cost
% initial cost term
ocp.cost.cost_type_0 = 'EXTERNAL';

% path cost term
ocp.cost.cost_type = 'EXTERNAL';

% terminal cost term
ocp.cost.cost_type_e = 'EXTERNAL';

% define constraints

% bound on u
ocp.constraints.lbu = [0 0];
ocp.constraints.ubu = [45e3 90];
ocp.constraints.idxbu = [0 1];

% bound on x

% initial state
ocp.constraints.x0 = x0;

% define solver options
ocp.solver_options.N_horizon = N;
ocp.solver_options.tf = T;
ocp.solver_options.nlp_solver_type = 'SQP';
ocp.solver_options.integrator_type = 'IRK';
ocp.solver_options.sim_method_num_steps= 1;
ocp.solver_options.sim_method_num_stages= 1;
ocp.solver_options.qp_solver = 'PARTIAL_CONDENSING_HPIPM';
ocp.solver_options.hessian_approx = 'GAUSS_NEWTON';
% ocp.solver_options.tf = T;
% ocp.solver_options.N_horizon = N;
% ocp.solver_options.time_steps = time_steps;
% ocp.solver_options.nlp_solver_type = 'SQP'; % 'SQP_RTI'
% ocp.solver_options.hessian_approx = 'GAUSS_NEWTON'; % 'EXACT'
% ocp.solver_options.regularize_method = 'CONVEXIFY';
% % NO_REGULARIZE, PROJECT, PROOJECT_REDUC_HESS, MIRROR, CONVEXIFY
% ocp.solver_options.nlp_solver_max_iter = 50;
% ocp.solver_options.nlp_solver_tol_stat = 1e-8;
% ocp.solver_options.nlp_solver_tol_eq = 1e-8;
% ocp.solver_options.nlp_solver_tol_ineq = 1e-8;
% ocp.solver_options.nlp_solver_tol_comp = 1e-8;
% ocp.solver_options.qp_solver = 'PARTIAL_CONDENSING_HPIPM';
% % FULL_CONDENSING_HPIPM, PARTIAL_CONDENSING_HPIPM
% % FULL_CONDENSING_QPOASES, PARTIAL_CONDENSING_OSQP
% ocp.solver_options.qp_solver_cond_N = 5; % for partial condensing
% ocp.solver_options.qp_solver_cond_ric_alg = 0;
% ocp.solver_options.qp_solver_ric_alg = 0;
% ocp.solver_options.qp_solver_warm_start = 1; % 0: cold, 1: warm, 2: hot
% ocp.solver_options.qp_solver_iter_max = 1000; % default is 50; OSQP needs a lot sometimes.
% ocp.solver_options.qp_solver_mu0 = 1e4;
% ocp.solver_options.exact_hess_dyn = 1;
% ocp.solver_options.exact_hess_cost = 1;
% ocp.solver_options.exact_hess_constr = 1;
% ocp.solver_options.print_level = 1;
% ocp.solver_options.store_iterates = true;

% create solver

ocp.parameter_values= ap;
ocp_solver = AcadosOcpSolver(ocp);

%% solve OCP
ocp_solver.reset();

ocp_solver.set('qp_print_level', 0) % console output only
ocp_solver.set('nlp_solver_max_iter', 500)

% x0= [0.0, 0.9*pi, 0.0, 0.0]';
% ocp_solver.set('constr_x0', x0)
% ocp_solver.set('constr_ubu', 40)
% ocp_solver.set('constr_lbu', -40)
% for i= 1:N-1
%     ocp_solver.set('constr_ubx', 0.9, i)
%     ocp_solver.set('constr_lbx', -0.9, i)
% end

x_traj_init = zeros(nx, N+1);
x_traj_init(2, :)= linspace(0, T*1.2, N+1);
x_traj_init(4, :)= 1.2;
u_traj_init = zeros(nu, N);
u_traj_init(1, :)= 4e4;
ocp_solver.set('init_x', x_traj_init);
ocp_solver.set('init_u', u_traj_init);
ocp_solver.set('init_pi', zeros(nx, N)) % multipliers for dynamics equality constraints
ocp_solver.set('p', ap)

tic
ocp_solver.solve();
toc

ocp_solver.print
ocp_solver.get('status')
simU = ocp_solver.get('u');
simX = ocp_solver.get('x');

run(fullfile(gen_dir, "model_indices.m"))
ts = linspace(0, T, N+1);
clf
States = [dof_names; dof_d_names];
tiledlayout(nx+nu, 1)
for i=1:length(States)
    nexttile
    plot(ts, simX(i, :)); grid on;
    ylabel(States{i});
    xlabel('t [s]')
end

for i=1:nu
    nexttile
    plot(ts(1:end-1), simU(i, :)); grid on;
    ylabel(input_names{i});
    xlabel('t [s]')
end