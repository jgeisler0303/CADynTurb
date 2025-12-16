ocp_path= '/home/jgeisler/Temp/CADynTurb_Suite/CADynTurb/model/T1_opt/generated/c_generated_code';
sim_model_path= '/home/jgeisler/Temp/CADynTurb_Suite/CADynTurb/model/T1B1cG/generated';
ekf_path= '/home/jgeisler/Temp/CADynTurb_Suite/CADynTurb/model/T1_est/generated/';

addpath(sim_model_path)
addpath(ekf_path)

%%
sim_dir= fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow');
wind_dir= fullfile(CADynTurb_dir, 'ref_sim/wind');
ref_sims= get_ref_sims(sim_dir, '1p1*_maininput.outb');
v= 11;
i= find(ref_sims.vv==v & ref_sims.yaw==0)';
d_FAST= loadData(ref_sims.files{i}, wind_dir);

%%
cd(sim_model_path)
m_param= load('params_config.mat', 'p_');
m_param= m_param.p_;

%%
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
ss1= std(d_FAST.Wind1VelX.Data);
ekf_param.fixedQxx(ekf_ix_vwind)= (ss1/200)^2;
P= [];
Q= [];
R= [];

%%
cd(sim_model_path)

model_indices
[x_ref, u]= convertFAST_CADyn(d_FAST, m_param);
q= x_ref(1:nq, :);
dq= x_ref(nq+1:end, :);

mpc_rate_f= 10;
ts= d_FAST.Time(2);

%%
cd(ocp_path)
run('../model_parameters.m')
load('../../params.mat')
param.power_max= 5000e3;
param.rpm_max= 1200;
param.rpm_min= 800;
param.pit_min= 0;

% param.w_cost= [50 50 5 5e-5  0.00001 5 50];
param.w_cost= [66000 66000*9.1189e-04 66.6667e0 6.67e-0 6e-5  66.667    0.6667    0.00001    06.667];
param= calc_cx_poly('cp', param);
param= calc_cx_poly('ct', param);

ocp_solver.reset();

ocp_solver.set('qp_print_level', 0) % console output only
ocp_solver.set('nlp_solver_max_iter', 10)

% move blocking
for i= 100:149
    ocp_solver.set('constr_ubu', [0 0], i)
    ocp_solver.set('constr_lbu', [0 0], i)
end

n= 63000;
VWIND= d_FAST.RtVAvgxh.Data(1:n);
Tgen= zeros(1, n+1);
theta= zeros(1, n+1);
ddq= zeros(nq, 1);
x0= zeros(5, 1);

Tgen(1)= u(in_Tgen_idx, 1);
theta(1)= u(in_theta_idx, 1);
f = waitbar(0, 'Simulation in progress...');
for k= 1:length(VWIND)
    waitbar(k/length(VWIND), f, 'Simulation in progress...');
    if mod(k-1, mpc_rate_f)==0
        x0(1)= q_est(tow_fa_idx_ekf, k);
        x0(2)= Tgen(k);
        x0(3)= theta(k);
        x0(4)= dq_est(tow_fa_idx_ekf, k);
        x0(5)= dq_est(phi_rot_idx_ekf, k);

        if k==1
            x_traj_init= repmat(x0, 1, N+1);
            u_traj_init= zeros(2, N);
        else
            x_traj_init(:, 1:end-1)= x_traj_init(:, 2:end);
            x_traj_init(:, 1)= x0;
            u_traj_init(:, 1:end-1)= u_traj_init(:, 2:end);
        end
        
        param.vwind= VWIND(k);
        ap= acados_params(parameter_names, param);
        ocp_solver.set('p', ap)
        ocp_solver.set('constr_x0', x0)
        ocp_solver.set('init_x', x_traj_init);
        ocp_solver.set('init_u', u_traj_init);
        ocp_solver.set('init_pi', zeros(5, N)) % multipliers for dynamics equality constraints
        ocp_solver.solve();

        if ocp_solver.get('status')~=0 && ocp_solver.get('status')~=2
            error('Solver status %d', ocp_solver.get('status'))
        end
        solU = ocp_solver.get('u');
    end

    [q(:, k+1), dq(:, k+1), ddq, y]= T1B1cG_mex(q(:, k), dq(:, k), ddq, [VWIND(k), Tgen(k) theta(k)], m_param, ts);
    
    [q_est_, dq_est_, ddq_est_, ~, Q, R, ~, ~, ~, ~, ~, P]= T1_est_ekf_mex(q_est(:, k), dq_est(:, k), [0 Tgen(k) theta(k); 0 0 0]', [[0; 0] y], ekf_param, ts, ekf_config.x_ul, ekf_config.x_ll, Q, R, ekf_param.Tadapt, ekf_param.adaptScale, ekf_param.fixedQxx, ekf_param.fixedRxx, opts, P, ddq_est);
    q_est(:, k+1)= q_est_(:, 2);
    dq_est(:, k+1)= dq_est_(:, 2);
    ddq_est= ddq_est_(:, 2);

    Tgen(k+1)= Tgen(k) + ts*solU(1);
    theta(k+1)= theta(k) + ts*solU(2);
end
close(f)

t= (0:n)*ts;
idx= 1:n+1;

subplot(6, 1, 1)
plot(t(1:end-1), VWIND, t, q_est(vwind_idx_ekf, idx))
legend('real', 'estimated')
grid on
title('vwind')

subplot(6, 1, 2)
plot(t, -theta/pi*180)
title('pitch')
grid on

subplot(6, 1, 3)
plot(t, dq(phi_rot_idx, idx)/pi*30*param.GBRatio, t, dq_est(phi_rot_idx_ekf, idx)/pi*30*param.GBRatio, t, t*0+param.rpm_max)
title('speed')
legend('gen speed', 'estimated', 'set point')
grid on

subplot(6, 1, 4)
TorqueMax= param.power_max/(param.rpm_max/30*pi);
plot(t, Tgen/1e3, t, Tgen*0+TorqueMax/1e3)
legend('gen trq', 'set point')
title('torque')
grid on

subplot(6, 1, 5)
plot(t, q(tow_fa_idx, idx), t, q_est(tow_fa_idx_ekf, idx))
title('tower', 'estimated')
grid on

subplot(6, 1, 6)
plot(t, dq(tow_fa_idx, idx), t, dq_est(tow_fa_idx_ekf, idx))
title('tower rate', 'estimated')
grid on

% subplot(6, 1, 6)
% plot(t, Tgen*param.GBRatio.*dq(phi_rot_idx, idx)/1e3)
% title('power')
% grid on


