% BEFORE RUNNING THIS MAKE SURE YOU RAN
% testFAST2CADynTurb_T1_opt_tracking_ocp and created an ocp_solver

ocp_path= gen_dir;
sim_model_path= fullfile(model_dir, '../T1/generated');
ekf_path= fullfile(model_dir, '../T1_est/generated');

addpath(sim_model_path)
addpath(ekf_path)
addpath(fullfile(CADynTurb_dir, 'simulator'))

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
wind_dir= fullfile(CADynTurb_dir, 'ref_sim/wind');
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