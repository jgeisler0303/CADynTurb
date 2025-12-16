%%
clc
model_dir= '/home/jgeisler/Temp/CADynTurb_Suite/CADynTurb/model/T1_opt'; % fileparts(matlab.desktop.editor.getActiveFilename);
CADynTurb_dir= fullfile(model_dir, '../..');
run(fullfile(CADynTurb_dir, 'matlab/setupCADynTurb'))

model_name= 'T1_opt';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'model_indices.m', 'model_parameters.m', '_acados.m', '_pre_calc.m'};

%% calculate parameters
N= 150;
T= 15;
t= 0:0.1:15;

MPC_W= [66000 66000*9.1189e-04 66.6667e0 6.67e-0 6e-5  66.667    0.6667    0.00001    06.667];
rated_power= 3430e3;
rated_rpm= 1452;
gear_ratio= 120.45;
om_gen= rated_rpm/30*pi;
om_rot= om_gen;
rated_torque= rated_power/om_rot;
x0= [rated_torque 3 om_rot 0.3 0];

vwind= 7;
OmMax= om_gen;
TorqueMax= rated_torque;
TorquTuning= 0;
PitSet= 2;
AirDensity= 1.225;
ap= [vwind, AirDensity, TorquTuning, OmMax, TorqueMax, PitSet, MPC_W];

%% make acados OCP
clc

% model dynamics
model= modelDT_T_B_P_t3();

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
% ocp.constraints.constr_type_0 = 'AUTO';
% ocp.constraints.constr_type = 'AUTO';
% ocp.constraints.constr_type_e = 'AUTO';
% bound on u
% pitch angle rate
dbeta_min = - 2.8;
dbeta_max =   8.5;
% generator torque rate
dM_gen_min = - 2.7056e+04*2;
dM_gen_max =   2.7056e+04*2;

ocp.constraints.lbu = [dM_gen_min dbeta_min];
ocp.constraints.ubu = [dM_gen_max dbeta_max];
ocp.constraints.idxbu = [0 1];

% bound on x
% pitch angle
beta_min =  0.0;
beta_max = 30.0;
% generator torque
M_gen_min = 0.0;
M_gen_max = 2.2558e+04*1.2;
M_gen_avg_max = 2.2558e+04+1;
acados_inf= 1e8;

ocp.constraints.lbx = [beta_min, M_gen_min];
ocp.constraints.ubx = [beta_max, M_gen_max];
ocp.constraints.idxbx = [1 0];

ocp.constraints.lh = 0;
ocp.constraints.uh = acados_inf;

% initial state
ocp.constraints.x0 = x0;

% define solver options
ocp.solver_options.N_horizon = N;
ocp.solver_options.tf = T;
ocp.solver_options.nlp_solver_type = 'SQP_RTI';% 'SQP'
ocp.solver_options.integrator_type = 'IRK';
ocp.solver_options.sim_method_num_steps= 1;
ocp.solver_options.sim_method_num_stages= 4;
ocp.solver_options.qp_solver = 'PARTIAL_CONDENSING_HPIPM';
% FULL_CONDENSING_HPIPM, PARTIAL_CONDENSING_HPIPM, FULL_CONDENSING_QPOASES, PARTIAL_CONDENSING_OSQP
ocp.solver_options.hessian_approx = 'GAUSS_NEWTON'; % EXACT, GAUSS_NEWTON
ocp.solver_options.regularize_method = 'NO_REGULARIZE';
% NO_REGULARIZE, PROJECT, PROOJECT_REDUC_HESS, MIRROR, CONVEXIFY
ocp.solver_options.nlp_solver_max_iter = 200;

% ocp.solver_options.ext_fun_compile_flags = '-O2';
% ocp.solver_options.globalization = 'MERIT_BACKTRACKING';

% ocp.solver_options.nlp_solver_tol_stat = 1e-8;
% ocp.solver_options.nlp_solver_tol_eq = 1e-8;
% ocp.solver_options.nlp_solver_tol_ineq = 1e-8;
% ocp.solver_options.nlp_solver_tol_comp = 1e-8;
% ocp.solver_options.qp_solver_cond_N = 5; % for partial condensing
% ocp.solver_options.qp_solver_cond_ric_alg = 0;
% ocp.solver_options.qp_solver_ric_alg = 0;
% ocp.solver_options.qp_solver_warm_start = 1; % 0: cold, 1: warm, 2: hot
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
vwind= 12;
x0= [rated_torque*0.8 1 om_rot*0.99 0.3 0];

ocp_solver.reset();

ocp_solver.set('qp_print_level', 0) % console output only
% ocp_solver.set('nlp_solver_max_iter', 100)

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

ap(1)= vwind;
ocp_solver.set('p', ap)

tic
ocp_solver.solve();
toc

ocp_solver.print
ocp_solver.get('status')
simU = ocp_solver.get('u')';
simX = ocp_solver.get('x')';


subplot(6, 1, 1)
plot(t(1:end), simX(:, 2))
title('pitch')
grid on

subplot(6, 1, 2)
plot(t, simX(:, 3)/pi*30, t, t*0+OmMax/pi*30)
title('speed')
legend('rotor speed', 'set point')
grid on

subplot(6, 1, 3)
plot(t(1:end), simX(:, 1), t(1:end), simX(:, 1)*0+TorqueMax)
legend('gen trq', 'set point')
title('torque')
grid on

subplot(6, 1, 4)
plot(t, simX(:, 4))
title('tower')
grid on

subplot(6, 1, 5)
plot(t, simX(:, 5))
title('tower rate')
grid on

subplot(6, 1, 6)
plot(t(1:end), simX(:, 1).*simX(:, 3)/1000)
title('power')
grid on
