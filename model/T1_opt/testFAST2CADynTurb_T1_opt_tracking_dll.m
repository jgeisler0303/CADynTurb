%% Demonstration/Test Solving a DLL compiled tracking MPC with estimated states based on a model with tower fa and rotational DOF

%% Setup environment
% RUN THE ENTIRE SCRIPT ONCE (F5), NOT THE CELL, OTHERWISE mfilename will not work!
% The rest of this schript is intended to be run cell by cell (Crtl+Enter)

clc
model_dir= fileparts(mfilename('fullpath'));
CADynTurb_dir= fullfile(model_dir, '../..');
addpath(fullfile(CADynTurb_dir, 'matlab'))
setupCADynTurb(true)

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T1_opt';
gen_dir= fullfile(model_dir, 'generated_tracking_ocp');

files_to_generate= {'model_indices.m', 'model_parameters.m', '_acados.m', '_param.hpp'};

ocp_path= gen_dir;
sim_model_path= fullfile(model_dir, '../T1/generated');
ekf_path= fullfile(model_dir, '../T1_est/generated');

addpath(sim_model_path)
addpath(ekf_path)
addpath(fullfile(CADynTurb_dir, 'simulator'))

if ~exist('TEST_MODE', 'var') || ~TEST_MODE; return; end

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
param.cp_lut = param.cp';
param.power_max= 5000e3;
param.rpm_max= 1200;
param.rpm_min= 800;
param.pit_min= 0;
param.max_trq= 45e3;
param.max_trq_rate= 40e3;
param.max_pit_rate= 7/180*pi;
param.w_cost= zeros(1, 9); % just some values, not needed here
[param.vwind_vec, param.theta_full_lut, param.theta_opt_lut, param.lambda_opt] = pitch_ref_lut(param);

%% generate and compile all source code
clc
cd(model_dir)
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid, [0 1]);
copyfile(fullfile(model_dir, 'calc_tracking_references.m'), gen_dir)

%% make acados OCP
clc
clear mex
cd(gen_dir)

% Solver settings
N = 150;                        % Number of time steps
T = 15;                         % time horizon length
x0 = [0.4; 40e3; 0; 0; 1.3];    % just some values, will change later

% Model dynamics
acados_model_func= str2func([model_name '_acados']);
[model, idx_name, model_info]= acados_model_func(param);

nx = length(model.x);           % state size
nu = length(model.u);           % input size

% OCP formulation object
ocp = AcadosOcp();
ocp.model = model;

% Parameters must be supplied as a vector p_values
run(fullfile(gen_dir, "model_parameters.m"))
p_values= acados_params(parameter_names, param);
ocp.parameter_values = p_values;

% cost in nonlinear least squares form
% x: tow_fa, Tgen, theta, tow_fa_d, phi_rot_d
W_x = diag([0, 1e-6, 1e5, 1e2, 1e5]);
% u: dTgen, dtheta
W_u = diag([1e-6 1e-2]);

% initial cost term
ocp.cost.cost_type_0 = 'NONLINEAR_LS';
ocp.cost.W_0 = W_u;
ocp.cost.yref_0 = zeros(nu, 1);
ocp.model.cost_y_expr_0 = model.u;

% path cost term
ocp.cost.cost_type = 'NONLINEAR_LS';
ocp.cost.W = blkdiag(W_x, W_u);
ocp.cost.yref = zeros(nx+nu, 1);
ocp.model.cost_y_expr = vertcat(model.x, model.u);

% terminal cost term
ocp.cost.cost_type_e = 'NONLINEAR_LS';
ocp.model.cost_y_expr_e = model.x;
ocp.cost.yref_e = zeros(nx, 1);
ocp.cost.W_e = W_x;

% Constraints
% bound on u
acados_inf= 1e8;
ocp.constraints.lbu = [-param.max_trq_rate -param.max_pit_rate];
ocp.constraints.ubu = [ param.max_trq_rate  param.max_pit_rate];
ocp.constraints.idxbu = [0 1];

% bound on x
ocp.constraints.lbx = [0 -pi/4];
ocp.constraints.ubx = [param.max_trq 0];
ocp.constraints.idxbx = [1 2];

% initial state
ocp.constraints.x0 = x0;

% Solver options
ocp.solver_options.N_horizon = N;
ocp.solver_options.tf = T;
ocp.solver_options.nlp_solver_type = 'SQP'; % possible values: SQP, SQP_RTI
ocp.solver_options.integrator_type = 'IRK';
ocp.solver_options.sim_method_num_steps= 1;
ocp.solver_options.sim_method_num_stages= 1;
ocp.solver_options.qp_solver = 'PARTIAL_CONDENSING_HPIPM';
% possible values: FULL_CONDENSING_HPIPM, PARTIAL_CONDENSING_HPIPM, FULL_CONDENSING_QPOASES, PARTIAL_CONDENSING_OSQP
ocp.solver_options.hessian_approx = 'GAUSS_NEWTON'; % possible values: EXACT, GAUSS_NEWTON
ocp.solver_options.regularize_method = 'NO_REGULARIZE';
% possible values: NO_REGULARIZE, PROJECT, PROOJECT_REDUC_HESS, MIRROR, CONVEXIFY
ocp.solver_options.nlp_solver_max_iter = 200; % This value cann not be exceeded when later setting ocp_solver.set('nlp_solver_max_iter', 10)

% Create solver
ocp_solver = AcadosOcpSolver(ocp);

%% Compile MPC DISCON
clc
cd(ocp_path)

tracking = true;
DISCON_MPC_dll = compileMPC_DISCON(model_name, model_dir, ocp_path, ekf_path, CADynTurb_dir, false, tracking);

% write parameter file with all necessary parameters
run(fullfile(ocp_path, 'model_parameters.m'))
parameter_names_ = parameter_names;
run(fullfile(ekf_path, 'model_parameters.m'))
parameter_names = unique([parameter_names; parameter_names_]);

param.max_iter = 1;
parameter_names{end+1} = 'max_iter';
DLL_InFile = writeModelParams(param, ocp_path, parameter_names);

%% Possible OpenFAST simulations as reference and for wind
sim_dir= fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow');
ref_sims= get_ref_sims(sim_dir, '1p1*_maininput.fst');

%% Run step-by-step simulation by calling the DISCON via a mex function
% select wind speed
v= 12;
i= find(ref_sims.vv==v & ref_sims.yaw==0)';
ref_sim_file = ref_sims.files{i};
d_FAST= loadData(ref_sim_file);

% set DISCON parameters, that are usually set in ServoDyn file
DISCON_param.comm_interval= 0.01;
DISCON_param.Ptch_Min= 0;
DISCON_param.Ptch_Max= 90;
DISCON_param.PtchRate_Min= -15;
DISCON_param.PtchRate_Max= 15;
DISCON_param.pitch_actuator= 0;
DISCON_param.Gain_OM= 1;
DISCON_param.GenSpd_MinOM= 800;
DISCON_param.GenSpd_MaxOM= 1200;
DISCON_param.GenSpd_Dem= 1200;
DISCON_param.GenTrq_Dem= 40000;
DISCON_param.GenPwr_Dem= 0;
DISCON_param.Ptch_SetPnt= 0;
DISCON_param.yaw_ctrl_mode= 0;
DISCON_param.num_blades= 3;
DISCON_param.Ptch_Cntrl= 0;
DISCON_param.gen_contractor= 1;
DISCON_param.controller_state= 0;
DISCON_param.time_to_output= 0;
DISCON_param.version= 0.0;

% prepare simulation result vectors and wind vector
cd(sim_model_path)
t_end= 150;
ts= 0.01;

nt= ceil(t_end/ts);
t= 0:ts:t_end-ts;

model_indices
[x_ref, u]= convertFAST_CADyn(d_FAST, param);
q= x_ref(1:nq, 1:nt);
dq= x_ref(nq+1:end, 1:nt);
ddq= zeros(nq, 1);
u= u(:, 1:nt);

vwind= d_FAST.RAWS.Data(1:nt);

% run simulation
clc
cd(ocp_path)

% prepare DISCON calling mex function
DISCON_param.sandbox_worker_path        = fullfile(getenv('CADYNTURB_DIR'), 'simulator', 'DISCON_sandbox_worker');
DISCON_param.sandbox_log_path           = fullfile(ocp_path, 'discon_worker_debug.log');
DISCON_param = rmfield(DISCON_param, 'sandbox_log_path');
DISCON_param.sandbox_detailed_logging   = true;

DISCON_sandbox_mex() % no arguments: terminate if necessary
DISCON_sandbox_mex(fullfile(ocp_path, 'DISCON_T1_tracking_MPC.dll'), DISCON_param, fullfile(ocp_path, 'params.txt')) % initialize

% simulation loop
for i= 2:nt
    % values communicated to DISCON
    Tgen_meas= u(in_Tgen_idx, i-1);
    om_rot= dq(phi_rot_idx, i-1);
    om_gen= dq(phi_rot_idx, i-1)*param.GBRatio;
    theta_meas= -u(in_theta_idx, i-1);
    tow_fa_acc= ddq(tow_fa_idx);
    tow_ss_acc= 0;
    phi_rot= q(phi_rot_idx, i-1);

    % call controller
    [theta_set, Tgen_set, status]= DISCON_sandbox_mex(t(i-1), vwind(i), Tgen_meas, om_rot, om_gen, theta_meas, tow_fa_acc, tow_ss_acc, phi_rot);
    if status==-1
        error('DISCON finished')
    end
    
    % call simulation step
    u(in_vwind_idx, i)= vwind(i);
    u(in_Tgen_idx, i)= Tgen_set;
    u(in_theta_idx, i)= -theta_set; % sign of theta is reverse in controller and model
    [q(:, i), dq(:, i), ddq]= T1_mex(q(:, i-1), dq(:, i-1), ddq, u(:, i), param, ts);
end
DISCON_sandbox_mex() % no arguments: terminate controller dll

% plot results
subplot(6, 1, 1)
plot(t, vwind)
grid on
title('vwind')

subplot(6, 1, 2)
plot(t, -u(in_theta_idx, :)/pi*180)
title('pitch')
grid on

subplot(6, 1, 3)
plot(t, dq(phi_rot_idx, :)/pi*30*param.GBRatio)
title('speed')
grid on

subplot(6, 1, 4)
plot(t, u(in_Tgen_idx, :)/1e3)
title('torque')
grid on

subplot(6, 1, 5)
plot(t, q(tow_fa_idx, :))
title('tow fa')
grid on

subplot(6, 1, 6)
plot(t, dq(tow_fa_idx, :))
title('tow fa rate')
grid on

%% Run comparison of MPC and classic DISCON via standalone simulators
clc
cd(gen_dir)
figures_dir = 'Classic_vs_MPC';
status = mkdir(figures_dir);

VV = 5:2:21;

for v = VV
    i= find(ref_sims.vv==v & ref_sims.yaw==0)';
    ref_sim_file = ref_sims.files{i};

    disp('#### Simulating classic DISCON')
    d_T1 = sim_standalone(fullfile(sim_model_path, 'sim_T1'), ref_sim_file);
    disp('#### Simulating MPC DISCON')
    d_T1_MPC = sim_standalone(fullfile(sim_model_path, 'sim_T1'), ref_sim_file, '', '', false, fullfile(ocp_path, DISCON_MPC_dll), DLL_InFile);
    plot_timeseries_cmp(d_T1, d_T1_MPC, {'RAWS', 'BlPitchC', 'LSSTipVxa', 'GenTq', 'YawBrTDxp'})

    [~, fig_name] = fileparts(ref_sim_file);
    savefig(fullfile(figures_dir, fig_name))
end
