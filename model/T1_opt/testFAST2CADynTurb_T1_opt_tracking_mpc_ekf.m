% BEFORE RUNNING THIS MAKE SURE YOU RAN
% testFAST2CADynTurb_T1_opt_tracking_ocp and created an ocp_solver

%% Load wind data from FAST simulation
sim_dir= fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow');
wind_dir= fullfile(CADynTurb_dir, 'ref_sim/wind');
ref_sims= get_ref_sims(sim_dir, '1p1*_maininput.fst');
% desired wind speed for simulation
v= 12;
i= find(ref_sims.vv==v & ref_sims.yaw==0)';
d_FAST= loadData(ref_sims.files{i});

%% Prepare MPC simulation, use a slightly more detailed model for simulation (T1B1cG), this of course, must be generated first
sim_model_path= fullfile(model_dir, '../T1B1cG/generated');
addpath(sim_model_path)

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
ekf_path= fullfile(model_dir, '../T1_est/generated');
addpath(ekf_path)
cd(ekf_path)

model_indices
tow_fa_idx_ekf= tow_fa_idx;
phi_rot_idx_ekf= phi_rot_idx;
vwind_idx_ekf= vwind_idx;

x_ref= convertFAST_CADyn(d_FAST, m_param);
q_est= x_ref(1:nq, :);
dq_est= x_ref(nq+1:end, :);
ddq_est= zeros(nq, 1);

ekf_config= T1_est_ekf_config;
ekf_ix_vwind= find(ekf_config.estimated_states==vwind_idx);
ekf_param= load('params_config.mat', 'p_');
ekf_param= ekf_param.p_;

ekf_param.Tadapt= 30;
ekf_param.fixedQxx= zeros(length(ekf_config.estimated_states), 1);
ekf_param.adaptScale= ones(1, ny);
ekf_param.fixedRxx= zeros(ny, 1);
opts= struct('StepTol', 1e6, 'AbsTol', 1e6, 'RelTol', 1e6, 'hminmin', 1E-8, 'jac_recalc_step', 10, 'max_steps', 1);
P= [];
Q= [];
R= [];

% set EKF adaption rate according to mean wind
ss1= std(d_FAST.Wind1VelX.Data);
ekf_param.fixedQxx(ekf_ix_vwind)= (ss1/200)^2;

%% Execute MPC simulation
% prepare solver for MPC
clc
cd(model_dir)

nlp_solver_max_iter = 2;
use_shifting = true; % shift the solution from previous MPC call to initialize the next call
ref_init = false; % init solution to reference values
n= 100000; % limit simulation length

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
            error('Solver status %d in step %d', ocp_solver.get('status'), k)
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


