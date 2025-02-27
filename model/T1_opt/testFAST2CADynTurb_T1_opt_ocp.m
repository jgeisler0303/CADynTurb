%%
clc
model_dir= '/home/jgeisler/Temp/CADynTurb_Suite/CADynTurb/model/T1_opt'; % fileparts(matlab.desktop.editor.getActiveFilename);
CADynTurb_dir= fullfile(model_dir, '../..');
run(fullfile(CADynTurb_dir, 'matlab/setupCADynTurb'))

model_name= 'T1_opt';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'model_indices.m', 'model_parameters.m', '_acados.m', '_pre_calc.m'};

%% calculate parameters
clc
cd(model_dir)
if exist('./params.mat', 'file')
    load('params.mat')
else
    [param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 -2]}, 1);
    param.vwind= 12;
    save('params', 'param', 'tw_sid', 'bd_sid')
end
param.power_max= 5000e3;
param.rpm_max= 1200;
param.rpm_min= 800;
param.pit_min= 0;

param.w_cost= [50 50 5 5e-5  0.00001 5 50];
% param.w_cost= [50000 50 5 5e-5  0.00001 5 50];
param= calc_cx_poly('cp', param);
param= calc_cx_poly('ct', param);

%% generate and compile all source code
clc
cd(model_dir)
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid, [0 1]);

%% make acados OCP
clc
cd(gen_dir)

% solver settings
N = 80;
T = 8; % time horizon length
x0 = [0.4; 40e3; 0; 0; 1.3];

% model dynamics
acados_model_func= str2func([model_name '_acados']);
model= acados_model_func(param);

nx = length(model.x); % state size
nu = length(model.u); % input size

% OCP formulation object
ocp = AcadosOcp();
ocp.model = model;

% cost
% initial cost term set in acados_model_func
ocp.cost.cost_type_0 = 'EXTERNAL';
% path cost term set in acados_model_func
ocp.cost.cost_type = 'EXTERNAL';
% terminal cost term set in acados_model_func
ocp.cost.cost_type_e = 'EXTERNAL';

% define constraints
% bound on u
max_trq_rate= 40e3*0.1;
max_pit_rate= 7/180*pi;
ocp.constraints.lbu = [-max_trq_rate -max_pit_rate];
ocp.constraints.ubu = [ max_trq_rate  max_pit_rate];
ocp.constraints.idxbu = [0 1];

% bound on x
ocp.constraints.lbx = [0 -pi/2];
ocp.constraints.ubx = [45e3 0];
ocp.constraints.idxbx = [1 2];

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
ocp.solver_options.nlp_solver_max_iter = 200;
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

% ocp.parameter_values= ap;
ocp_solver = AcadosOcpSolver(ocp);

%% solve OCP
param.vwind= 6;
ocp_solver.reset();

ocp_solver.set('qp_print_level', 0) % console output only
ocp_solver.set('nlp_solver_max_iter', 100)

x0= simX(:, end);
ocp_solver.set('constr_x0', x0)

% for i= 0:N-1
%     ocp_solver.set('constr_ubu', [45e3 0], i)
%     ocp_solver.set('constr_lbu', [0 -pi/2], i)
% end

x_traj_init = repmat(x0, 1, N+1);
% x_traj_init(2, :)= linspace(0, T*x0(4), N+1);
u_traj_init = zeros(nu, N);
% u_traj_init(1, :)= 4e4;

ocp_solver.set('init_x', x_traj_init);
ocp_solver.set('init_u', u_traj_init);
ocp_solver.set('init_pi', zeros(nx, N)) % multipliers for dynamics equality constraints

model_parameters
% [param, precalcNames]= T1_opt_pre_calc(p_);
% ap= acados_params([parameter_names; precalcNames'], param);
ap= acados_params(parameter_names, param);
ocp_solver.set('p', ap)

param_moveblock= param;
for i= 50:80
    param_moveblock.w_cost([1 2 5:7])= param_moveblock.w_cost([1 2 5:7])*1.2;
    ap= acados_params(parameter_names, param_moveblock);
    ocp_solver.set('p', ap, i)
end

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
