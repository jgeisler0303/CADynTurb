%% prepare paths
clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
CADynTurb_dir= fullfile(model_dir, '../..');
run(fullfile(CADynTurb_dir, 'matlab/setupCADynTurb'))

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T1B1cG_est';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'_direct.hpp', '_param.hpp', 'model_indices.m', 'model_parameters.m'};

%% calculate parameters
cd(model_dir)
if exist('./params.mat', 'file')
    load('params.mat')
else
    [param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 -2 ]}, 1);
    save('params', 'param', 'tw_sid', 'bd_sid')
end

%% generate and compile all source code
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid);
writeModelParams(param, gen_dir);
makeCADynMex(model_name, gen_dir, '', '', fullfile(CADynTurb_dir, 'simulator'))

%% compile ekf mex
clc
makeCADynEKFMex(model_name, model_dir, gen_dir)

%% get reference simulations 1p1
sim_dir= fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow');
wind_dir= fullfile(CADynTurb_dir, 'ref_sim/wind');

ref_sims= get_ref_sims(sim_dir, '1p1*_maininput.outb');

%% simulate mex model
cd(gen_dir)

v= 11;
for  i= find(ref_sims.vv==v & ref_sims.yaw==0)'
    d_FAST= loadData(ref_sims.files{i}, wind_dir);

    d_sim= run_simulation(model_name, d_FAST, param);
    plot_timeseries_cmp(d_FAST, d_sim, {'RtVAvgxh', 'BlPitchC', 'HSShftV', 'GenTq', 'YawBrTDxp', 'Q_BF1'});
end

%% run Kalman filter
cd(gen_dir)
model_indices
ekf_config= T1B1cG_est_ekf_config;
ix_vwind= find(ekf_config.estimated_states==vwind_idx);
param.Tadapt= 30;
param.fixedQxx= zeros(length(ekf_config.estimated_states), 1);

v= 12;
for  i= find(ref_sims.vv==v & ref_sims.yaw==0)'
    d_in= loadData(ref_sims.files{i}, wind_dir);

    ss1= std(d_in.Wind1VelX.Data);
    param.fixedQxx(ix_vwind)= (ss1/200)^2;

    [d_est1, ~, ~, ~, ~, ~, Q, R]= run_simulation(model_name, d_in, param, [], 0, 2, [], []);
    [d_est2, ~, ~, ~, ~, ~, Q, R]= run_simulation(model_name, d_in, param, [], 0, 2, Q, R);

    plot_timeseries_multi({d_in, d_est1, d_est2}, {'RtVAvgxh', 'Q_TFA1' 'Q_BF1' 'LSSTipVxa', 'Q_DrTr'})
end