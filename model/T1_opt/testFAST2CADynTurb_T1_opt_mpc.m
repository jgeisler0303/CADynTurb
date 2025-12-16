ocp_path= '/home/jgeisler/Temp/CADynTurb_Suite/CADynTurb/model/T1_opt/generated';
sim_model_path= '/home/jgeisler/Temp/CADynTurb_Suite/CADynTurb/model/T1B1cG/generated';

addpath(sim_model_path)

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

model_indices
[x_ref, u]= convertFAST_CADyn(d_FAST, m_param);
q= x_ref(1:nq, :);
dq= x_ref(nq+1:end, :);

mpc_rate_f= 10;
ts= d_FAST.Time(2);

%%
cd(ocp_path)
load('../params.mat')
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

n= 10000;
VWIND= d_FAST.RtVAvgxh.Data(1:n);
Tgen= zeros(1, n+1);
theta= zeros(1, n+1);
ddq= zeros(nq, 1);
x0= zeros(5, 1);

Tgen(1)= u(in_Tgen_idx, 1);
theta(1)= u(in_theta_idx, 1);
for k= 1:length(VWIND)
    if mod(k-1, mpc_rate_f)==0
        x0(1)= q(tow_fa_idx, k);
        x0(2)= Tgen(k);
        x0(3)= theta(k);
        x0(4)= dq(tow_fa_idx, k);
        x0(5)= dq(phi_rot_idx, k);

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

    [q(:, k+1), dq(:, k+1), ddq]= T1B1cG_mex(q(:, k), dq(:, k), ddq, [VWIND(k), Tgen(k) theta(k)], m_param, ts);
    Tgen(k+1)= Tgen(k) + ts*solU(1);
    theta(k+1)= theta(k) + ts*solU(2);
end

t= (0:n)*ts;
idx= 1:n+1;

subplot(6, 1, 1)
plot(t(1:end-1), VWIND)
grid on
title('vwind')

subplot(6, 1, 2)
plot(t, -theta/pi*180)
title('pitch')
grid on

subplot(6, 1, 3)
plot(t, dq(phi_rot_idx, idx)/pi*30*param.GBRatio, t, t*0+param.rpm_max)
title('speed')
legend('gen speed', 'set point')
grid on

subplot(6, 1, 4)
TorqueMax= param.power_max/(param.rpm_max/30*pi);
plot(t, Tgen/1e3, t, Tgen*0+TorqueMax/1e3)
legend('gen trq', 'set point')
title('torque')
grid on

subplot(6, 1, 5)
plot(t, q(tow_fa_idx, idx))
title('tower')
grid on

subplot(6, 1, 6)
plot(t, dq(tow_fa_idx, idx))
title('tower rate')
grid on

% subplot(6, 1, 6)
% plot(t, Tgen*param.GBRatio.*dq(phi_rot_idx, idx)/1e3)
% title('power')
% grid on


