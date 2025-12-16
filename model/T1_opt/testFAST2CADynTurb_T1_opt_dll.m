ocp_path= '/home/jgeisler/Temp/CADynTurb_Suite/CADynTurb/model/T1_opt/generated/c_generated_code';
sim_model_path= '/home/jgeisler/Temp/CADynTurb_Suite/CADynTurb/model/T1/generated';
ekf_path= '/home/jgeisler/Temp/CADynTurb_Suite/CADynTurb/model/T1_est/generated/';

addpath(sim_model_path)
addpath(ekf_path)
addpath('/home/jgeisler/Temp/CADynTurb_Suite/CADynTurb/simulator')

%%
clc
% system('g++ -shared -fpermissive -I. -I/home/jgeisler/Temp/CADynTurb_Suite/CADynTurb/model/T1_est/generated -I/home/jgeisler/Temp/CADynTurb_Suite/CADynTurb/simulator -I/home/jgeisler/Temp/CADynTurb_Suite/CADyn/src -I/home/jgeisler/Temp/acados -I/home/jgeisler/Temp/acados/include -I/home/jgeisler/Temp/acados/include/blasfeo/include -I/home/jgeisler/Temp/acados/include/hpipm/include -o DISCON_MPC.dll /home/jgeisler/Temp/CADynTurb_Suite/CADynTurb/simulator/DISCON_MPC.cpp acados_solver_T1_opt_acados.c -fPIC -Wl,--disable-new-dtags,-rpath,\$ORIGIN,-rpath,/home/jgeisler/Temp/acados/lib -L/home/jgeisler/Temp/acados/lib -L/home/jgeisler/Temp/CADynTurb_Suite/CADynTurb/model/T1_opt/generated/c_generated_code -lacados -lhpipm -lblasfeo -lacados_ocp_solver_T1_opt_acados')
ocp_model= 'T1_opt';
ocp_gen_dir= '/home/jgeisler/Temp/CADynTurb_Suite/CADynTurb/model/T1_opt/generated';
ekf_gen_dir= '/home/jgeisler/Temp/CADynTurb_Suite/CADynTurb/model/T1_est/generated';

compileMPC_DISCON(ocp_model, ocp_gen_dir, ekf_gen_dir, CADynTurb_dir)

%%
sim_dir= fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow');
wind_dir= fullfile(CADynTurb_dir, 'ref_sim/wind');
ref_sims= get_ref_sims(sim_dir, '1p1*_maininput.outb');
v= 11;
i= find(ref_sims.vv==v & ref_sims.yaw==0)';
d_FAST= loadData(ref_sims.files{i}, wind_dir);

%% DISCON parameters
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

%%
cd(sim_model_path)
m_param= load('params_config.mat', 'p_');
m_param= m_param.p_;

t_end= 150;
ts= 0.01;

nt= ceil(t_end/ts);
t= 0:ts:t_end-ts;

model_indices
[x_ref, u]= convertFAST_CADyn(d_FAST, m_param);
q= x_ref(1:nq, 1:nt);
dq= x_ref(nq+1:end, 1:nt);
ddq= zeros(nq, 1);
u= u(:, 1:nt);

vwind= d_FAST.RtVAvgxh.Data(1:nt);

%% simulation with Newmark T1 simulator
cd(ocp_path)

DISCON_mex() % terminate id necessary
DISCON_mex('DISCON_MPC3.dll', DISCON_param, '/home/jgeisler/Temp/CADynTurb_Suite/CADynTurb/model/T1_est/generated/params.txt') % initialize

%%
for i= 2:nt
    Tgen_meas= u(in_Tgen_idx, i-1); % last setpoint, maybe not used by controller
    om_rot= dq(phi_rot_idx, i-1);
    om_gen= dq(phi_rot_idx, i-1)*m_param.GBRatio;
    theta_meas= -u(in_theta_idx, i-1); % last setpoint, maybe not used by controller
    tow_fa_acc= ddq(tow_fa_idx);
    tow_ss_acc= 0; % not used by controller
    phi_rot= q(phi_rot_idx, i-1); % probably not used by controller

    [theta_set, Tgen_set, status]= DISCON_mex(t(i-1), vwind(i), Tgen_meas, om_rot, om_gen, theta_meas, tow_fa_acc, tow_ss_acc, phi_rot);
    if status==-1
        error('DISCON finished')
    end

    u(in_vwind_idx, i)= vwind(i);
    u(in_Tgen_idx, i)= Tgen_set;
    u(in_theta_idx, i)= -theta_set; % sign of theta is reverse in controller and model
    [q(:, i), dq(:, i), ddq]= T1_mex(q(:, i-1), dq(:, i-1), ddq, u(:, i), m_param, ts);
end
DISCON_mex()

%%
subplot(6, 1, 1)
plot(t, vwind) %, t, q_est(vwind_idx_ekf, idx))
% legend('real', 'estimated')
grid on
title('vwind')

subplot(6, 1, 2)
plot(t, -u(in_theta_idx, :)/pi*180)
title('pitch')
grid on

subplot(6, 1, 3)
plot(t, dq(phi_rot_idx, :)/pi*30*m_param.GBRatio) %, t, dq_est(phi_rot_idx_ekf, idx)/pi*30*param.GBRatio, t, t*0+param.rpm_max)
title('speed')
% legend('gen speed', 'estimated', 'set point')
grid on

subplot(6, 1, 4)
% TorqueMax= param.power_max/(param.rpm_max/30*pi);
plot(t, u(in_Tgen_idx, :)/1e3) %, t, Tgen*0+TorqueMax/1e3)
% legend('gen trq', 'set point')
title('torque')
grid on

subplot(6, 1, 5)
plot(t, q(tow_fa_idx, :)) %, t, q_est(tow_fa_idx_ekf, idx))
% legend('tower', 'estimated')
grid on

subplot(6, 1, 6)
plot(t, dq(tow_fa_idx, :)) %, t, dq_est(tow_fa_idx_ekf, idx))
% tilegendtle('tower rate', 'estimated')
grid on

% subplot(6, 1, 6)
% plot(t, Tgen*param.GBRatio.*dq(phi_rot_idx, idx)/1e3)
% title('power')
% grid on


