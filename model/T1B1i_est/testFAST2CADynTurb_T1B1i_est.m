%% set configuration variables
clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
CADynTurb_dir= fullfile(model_dir, '../..');
run(fullfile(CADynTurb_dir, 'matlab/setupCADynTurb'))

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T1B1i_est';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'_direct.hpp', '_ode1.hpp', '_param.hpp', 'model_parameters.m', 'model_indices.m', 'model_indices_ode1.m'};

%% calculate parameters
cd(model_dir)
if exist('./params.mat', 'file')
    load('params.mat')
else
    [param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 -2]}, 1);
    save('params', 'param', 'tw_sid', 'bd_sid')
end

%% generate and compile all source code
cd(model_dir)
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid, [0, 1]);
writeModelParams(param, gen_dir);
compileModel(model_name, model_dir, gen_dir, files_to_generate)

%% get reference simulations 1p1
sim_dir= fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow');
wind_dir= fullfile(CADynTurb_dir, 'ref_sim/wind');

ref_sims= get_ref_sims(sim_dir, '1p1*_maininput.outb');

%% run Kalman filter
clc
cd(gen_dir)

param.Tadapt= 30;
param.adaptScale= [1 1 1.1 1.1 1.1 1.1 1.1 1.1];

% Newmark beta
model_indices
ekf_config= T1B1i_est_ekf_config;
ix_vwind= find(ekf_config.estimated_states==vwind_idx);
% ix_h_shear= find(ekf_config.estimated_states==h_shear_idx);
% ix_v_shear= find(ekf_config.estimated_states==v_shear_idx);
param.fixedQxx= zeros(length(ekf_config.estimated_states), 1);
% param.fixedQxx(ix_h_shear)= (10^-4)^2; % for 10ms
% param.fixedQxx(ix_v_shear)= (10^-4)^2; % for 10ms

% RK1
param_RK1 = param;
model_indices_ode1
param_RK1.fixedQxx= zeros(nx, 1);

v= 12;
for  i= find(ref_sims.vv==v & ref_sims.yaw==0)'
    d_in= loadData(ref_sims.files{i}, wind_dir, false, param);

    ss1= std(d_in.Wind1VelX.Data);
    param.fixedQxx(ix_vwind)= (ss1/200)^2;
    param_RK1.fixedQxx(vwind_idx)= (ss1/200)^2;

    [d_est, ~, ~, ~, ~, ~, Q, R, x_end_est, P_end]= run_simulation(model_name, d_in, param, [], 0, 2, [], []);
    d_est2                                        = run_simulation(model_name, d_in, param, [], 0, 2, Q, R, [], x_end_est, P_end);

    [d_est_RK1, ~, ~, ~, ~, ~, Q, R, x_end_est, P_end]= run_simulation([model_name '_RK1'], d_in, param_RK1, [], 0, 2, [], []);
    d_est_RK12                                        = run_simulation([model_name '_RK1'], d_in, param_RK1, [], 0, 2, Q, R, [], x_end_est, P_end);


    plot_timeseries_multi({d_in, d_est2, d_est_RK12}, {'RAWS', 'Q_TFA1' 'RtHSAvg', 'RtVSAvg', 'Q_B1F1' 'LSSTipVxa'}, {'FAST', 'Newmark' 'RK1'}, 0, inf, [], true, 3)
end

%% plot_timeseries_cmp(d_FAST, d_sim, {'RAWS', 'BlPitchC1', 'LSSTipPxa', 'YawBrTDxp', {'RootMxb1' 'RootMxb2' 'RootMxb3'}, {'RootMyb1' 'RootMyb2' 'RootMyb3'}})
plot_timeseries_cmp(d_FAST, d_sim, {'RAWS', 'RootMxb1' 'RootMxb2' 'RootMxb3', 'RootMyb1' 'RootMyb2' 'RootMyb3'})

