%% Demonstration/Test Solving a tracking MPC with estimated states based on a model with tower fa and rotational DOF

%% Setup environment
% RUN THE ENTIRE SCRIPT ONCE (F5), NOT THE CELL, OTHERWISE mfilename will not work!
% The rest of this schript is intended to be run cell by cell (Crtl+Enter)

clc
model_dir= fileparts(mfilename('fullpath'));
CADynTurb_dir= fullfile(model_dir, '../..');
addpath(fullfile(CADynTurb_dir, 'matlab'))
setupCADynTurb(true)

model_name= 'T1_opt';
gen_dir= fullfile(model_dir, 'generated_tracking_ocp');

files_to_generate= {'model_indices.m', 'model_parameters.m', '_acados.m', '_param.hpp'};

sim_model_path= fullfile(model_dir, '../T1B1cG/generated');
addpath(sim_model_path)

ekf_path= fullfile(model_dir, '../T1_est/generated');
addpath(ekf_path)

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

%% Prepare MPC simulation, use a slightly more detailed model for simulation (T1B1cG), this of course, must be generated first
% load simulation model parameters
cd(sim_model_path)
m_param= load('params_config.mat', 'p_');
m_param= m_param.p_;
model_indices
tow_fa_idx_sim = tow_fa_idx;
bld_flp_idx_sim = bld_flp_idx;
phi_rot_idx_sim = phi_rot_idx;
phi_gen_idx_sim = phi_gen_idx;

nq_sim = nq;

%% Prepare EKF
cd(ekf_path)

model_indices
tow_fa_idx_ekf= tow_fa_idx;
phi_rot_idx_ekf= phi_rot_idx;
vwind_idx_ekf= vwind_idx;

ekf_config= T1_est_ekf_config;
ekf_ix_vwind= find(ekf_config.estimated_states==vwind_idx);
ekf_param= load('params_config.mat', 'p_');
ekf_param= ekf_param.p_;

ekf_param.Tadapt= 30;
ekf_param.fixedQxx= zeros(length(ekf_config.estimated_states), 1);
ekf_param.adaptScale= ones(1, ny);
ekf_param.fixedRxx= zeros(ny, 1);
opts= struct('StepTol', 1e6, 'AbsTol', 1e6, 'RelTol', 1e6, 'hminmin', 1E-8, 'jac_recalc_step', 10, 'max_steps', 1);

%% Load wind data from FAST simulation
sim_dir= fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow');
ref_sims= get_ref_sims(sim_dir, '1p1*_maininput.fst');
% desired wind speed for simulation
v= 12;
i= find(ref_sims.vv==v & ref_sims.yaw==0)';
d_FAST= loadData(ref_sims.files{i});

%% Execute MPC simulation
% prepare solver for MPC
clc
cd(model_dir)

nlp_solver_max_iter = 2;
use_shifting = true; % shift the solution from previous MPC call to initialize the next call
ref_init = false; % init solution to reference values
n= inf; % limit simulation length

n= min(n, length(d_FAST.Time));
ts= d_FAST.Time(2);
mpc_rate_f= T/N/ts; % MPC rate factor, i.e. how often the MPC is called, in multiples of the simulation time step

ocp_solver.reset(); % reset solver once, use warm start for subsequent calls
ocp_solver.set('qp_print_level', 0) % console output only
ocp_solver.set('nlp_solver_max_iter', nlp_solver_max_iter)

% cost in nonlinear least squares form
% x: tow_fa, Tgen, theta, tow_fa_d, phi_rot_d
W_x = diag([0, 1e-6, 1e5, 1e2, 1e5]);
% u: dTgen, dtheta
W_u = diag([1e-6 1e-2]);

% values have to be set in loop, intervalls don't seem to work
ocp_solver.set('cost_W', W_u, 0)
for k = 1:(N-1)
    ocp_solver.set('cost_W', blkdiag(W_x, W_u), k)
end
ocp_solver.set('cost_W', W_x, N)

% move blocking
% for i= 100:149
%     ocp_solver.set('constr_ubu', [0 0], i)
%     ocp_solver.set('constr_lbu', [0 0], i)
% end

% prepare EKF
x_ref= convertFAST_CADyn(d_FAST, m_param);
q_est= x_ref(1:nq, :);
dq_est= x_ref(nq+1:end, :);
ddq_est= zeros(nq, 1);

P= [];
Q= [];
R= [];

% set EKF adaption rate according to mean wind
ss1= std(d_FAST.Wind1VelX.Data);
ekf_param.fixedQxx(ekf_ix_vwind)= (ss1/200)^2;

VWIND= d_FAST.RAWS.Data(1:n);
Tgen= nan(1, length(VWIND));
theta= nan(1, length(VWIND));
q= nan(nq_sim, length(VWIND), 1);
dq= nan(nq_sim, length(VWIND), 1);
ddq= zeros(nq_sim, 1);

om_rot_ref = nan(length(VWIND), 1);
P_ref = nan(length(VWIND), 1);
Tgen_ref = nan(length(VWIND), 1);
theta_ref = nan(length(VWIND), 1);
x0 = zeros(5, 1);

% simulation loop
try close(f), catch, end
f = waitbar(0, 'Simulation in progress...');
for k= 1:length(VWIND)
    waitbar(k/length(VWIND), f, 'Simulation in progress...');

    % downsample MPC rate, i.e. only call the MPC every mpc_rate_f samples
    if mod(k-1, mpc_rate_f)==0
        param.vwind = VWIND(k);

        % Calculate tracking references for current wind speed
        [om_rot_ref(k), Tgen_ref(k), theta_ref(k), P_ref(k)] = calc_tracking_references(VWIND(k), param);

        % reset solver and prepare with parameters and initial conditions
        ocp_solver.reset();

        ocp_solver.set('qp_print_level', 0) % console output only
        ocp_solver.set('nlp_solver_max_iter', nlp_solver_max_iter)
        
        ocp_solver.set('constr_x0', x0)

        yref = zeros(model_info.q.n+model_info.qd.n+model_info.u.n, 1);
        yref(idx_name.idx.theta)= theta_ref(k);
        yref(idx_name.idx.Tgen)= Tgen_ref(k);
        yref(idx_name.idx.phi_rot_d)= om_rot_ref(k);

        % values have to be set in loop, intervalls don't seem to work
        for j = 1:(N-1)
            ocp_solver.set('cost_y_ref', yref, j);
        end
        ocp_solver.set('cost_y_ref_e', yref(1:model_info.q.n+model_info.qd.n), N);

        % set simulation initial state
        if k==1
            q(tow_fa_idx_sim, k) = 0.15;
            q(bld_flp_idx_sim, k) = 0;
            q(phi_rot_idx_sim, k) = 0;
            q(phi_gen_idx_sim, k) = 0;
            dq(tow_fa_idx_sim, k) = 0;
            dq(bld_flp_idx_sim, k) = 0;
            dq(phi_rot_idx_sim, k) = om_rot_ref(k);
            dq(phi_gen_idx_sim, k) = om_rot_ref(k)*param.GBRatio;
            Tgen(k)= Tgen_ref(k);
            theta(k)= theta_ref(k);
        end

        % set mpc initial state
        x0(idx_name.idx.tow_fa)= q_est(tow_fa_idx_ekf, k);
        x0(idx_name.idx.Tgen)= Tgen(k);
        x0(idx_name.idx.theta)= theta(k);
        x0(idx_name.idx.tow_fa_d)= dq_est(tow_fa_idx_ekf, k);
        x0(idx_name.idx.phi_rot_d)= dq_est(phi_rot_idx_ekf, k);

        if k==1
            Tgen(1)= Tgen_ref(k);
            theta(1)= theta_ref(k);

            x_traj_init= repmat(x0, 1, N+1);
            u_traj_init= zeros(2, N);
        elseif use_shifting
            x_traj_init(:, 1:end-1)= x_traj_init(:, 2:end);
            x_traj_init(:, 1)= x0;
            u_traj_init(:, 1:end-1)= u_traj_init(:, 2:end);
        elseif ref_init
            x_traj_init= repmat(yref(1:model_info.q.n+model_info.qd.n), 1, N+1);
            x_traj_init(:, 1)= x0;
            u_traj_init = zeros(2, N);
        end
        if k==1 || use_shifting || ref_init
            ocp_solver.set('init_x', x_traj_init);
            ocp_solver.set('init_u', u_traj_init);
            ocp_solver.set('init_pi', zeros(numel(x0), N)) % multipliers for dynamics equality constraints
        end
        
        % set parameters for current wind speed
        ap= acados_params(parameter_names, param);
        ocp_solver.set('p', ap)
        ocp_solver.set('constr_x0', x0)

        ocp_solver.solve();

        if ocp_solver.get('status')~=0 && ocp_solver.get('status')~=2
            warning('Solver status %d in step %d', ocp_solver.get('status'), k)
        end
        solU = ocp_solver.get('u');
    end

    % simulate one time step with the current control input
    [q(:, k+1), dq(:, k+1), ddq, y]= T1B1cG_mex(q(:, k), dq(:, k), ddq, [VWIND(k), Tgen(k) theta(k)], m_param, ts);

    % update control rate inputs for next time step
    Tgen(k+1)= Tgen(k) + ts*solU(model_info.u.idx.dTgen, 1);
    theta(k+1)= theta(k) + ts*solU(model_info.u.idx.dtheta, 1);

    % run EKF
    [q_est_, dq_est_, ddq_est_, ~, Q, R, ~, ~, ~, ~, ~, P]= T1_est_ekf_mex(q_est(:, k), dq_est(:, k), [0 Tgen(k) theta(k); 0 0 0]', [[0; 0] y], ekf_param, ts, ekf_config.x_ul, ekf_config.x_ll, Q, R, ekf_param.Tadapt, ekf_param.adaptScale, ekf_param.fixedQxx, ekf_param.fixedRxx, opts, P, ddq_est);
    q_est(:, k+1)= q_est_(:, 2);
    dq_est(:, k+1)= dq_est_(:, 2);
    ddq_est= ddq_est_(:, 2);    
end
close(f)

t= (0:n)*ts;
idx= 1:n+1;
idx_ = 1:n;

% plot results
clf
tiledlayout(7, 1)
nexttile
plot(t(1:end-1), VWIND, t, q_est(vwind_idx_ekf, idx))
legend('real', 'estimated')
grid on
title('vwind')

nexttile
plot(t, -theta/pi*180, t(idx_), -theta_ref/pi*180, '.')
title('pitch', 'ref')
grid on

nexttile
plot(t, dq(phi_rot_idx_sim, idx)/pi*30*param.GBRatio, t, dq_est(phi_rot_idx_ekf, idx)/pi*30*param.GBRatio, t(idx_), om_rot_ref/pi*30*param.GBRatio, '.')
title('speed')
legend('gen speed', 'estimated', 'set point')
grid on
ylim([700 1300])

nexttile
TorqueMax= param.power_max/(param.rpm_max/30*pi);
plot(t, Tgen/1e3, t(idx_), Tgen_ref/1e3, '.')
legend('gen trq', 'ref')
title('torque')
grid on

nexttile
plot(t, q(tow_fa_idx_sim, idx), t, q_est(tow_fa_idx_ekf, idx))
title('tower', 'estimated')
grid on

nexttile
plot(t, dq(tow_fa_idx_sim, idx), t, dq_est(tow_fa_idx_ekf, idx))
title('tower rate', 'estimated')
grid on

nexttile
plot(t, Tgen*param.GBRatio.*dq(phi_rot_idx_sim, idx)/1e3)
title('power')
grid on

linkaxes(findobj(gcf, 'Type', 'Axes'), 'x')