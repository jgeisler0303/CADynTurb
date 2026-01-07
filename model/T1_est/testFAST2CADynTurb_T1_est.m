%% set configuration variables
clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
CADynTurb_dir= fullfile(model_dir, '../..');
run(fullfile(CADynTurb_dir, 'matlab/setupCADynTurb'))

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T1_est';
gen_dir= fullfile(model_dir, 'generated');
gen_dir_m = [gen_dir '_M'];

files_to_generate= {'_direct.hpp', '_param.hpp', 'model_indices.m', 'model_parameters.m'};

%% calculate parameters
cd(model_dir)
if exist('./params.mat', 'file')
    load('params.mat')
else
    [param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 -2 ]}, 1);
    save('params', 'param', 'tw_sid', 'bd_sid')
end

%% CADynM model
% If you want to use this experimental feature, please clone
% https://github.com/jgeisler0303/CADynM in a directory parallel to CADynTurb
clc
cd(model_dir)

param.tw_sid= tw_sid;
T1_est = modelT1_est(param);
eom = T1_est.getEOM;
T1_est.removeUnusedParameters();

[~, ~] = mkdir(gen_dir_m);
copyfile(fullfile(model_dir, [model_name '_Externals.hpp']), gen_dir_m)
matlabTemplateEngine(fullfile(gen_dir_m, 'model_parameters.m'), 'model_parameters.m.mte', T1_est)
matlabTemplateEngine(fullfile(gen_dir_m, 'model_indices.m'), 'model_indices.m.mte', T1_est)
matlabTemplateEngine(fullfile(gen_dir_m, 'T1_est_param.hpp'), 'param.hpp.mte', T1_est)
matlabTemplateEngine(fullfile(gen_dir_m, 'T1_est_direct.hpp'), 'direct.hpp.mte', T1_est)
extermals_file = fullfile(gen_dir_m, 'T1_est_Externals.hpp');
if ~exist(extermals_file, 'file')
    matlabTemplateEngine(extermals_file, 'Externals.hpp.mte', T1_est)
end

%% Build mex-file for CADynM generated model
cd(gen_dir_m)
clc
makeCADynMex(model_name, '.', '', '', fullfile(CADynTurb_dir, 'simulator'))
makeCADynEKFMex(model_name, model_dir, gen_dir_m)

%% generate and compile all source code
cd(model_dir)
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid, [0 1]); % no reduce const but const matrix elements only once
writeModelParams(param, gen_dir);
makeCADynMex(model_name, gen_dir, '', '', fullfile(CADynTurb_dir, 'simulator'))

%% compile ekf mex
clc
makeCADynEKFMex(model_name, model_dir, gen_dir)

%% get reference simulations 1p1
sim_dir= fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow');
wind_dir= fullfile(CADynTurb_dir, 'ref_sim/wind');

ref_sims= get_ref_sims(sim_dir, '1p1*_maininput.outb');

%% run Kalman filter
cd(gen_dir_m)
model_indices
ekf_config= T1_est_ekf_config;
ix_vwind= find(ekf_config.estimated_states==vwind_idx);
param.Tadapt= 30;
param.fixedQxx= zeros(length(ekf_config.estimated_states), 1);

v= 12;
for  i= find(ref_sims.vv==12 & ref_sims.yaw==0)'
    d_in= loadData(ref_sims.files{i}, wind_dir);

    ss1= std(d_in.Wind1VelX.Data);
    param.fixedQxx(ix_vwind)= (ss1/200)^2;
    [d_est1, ~, ~, ~, ~, ~, Q, R]= run_simulation(model_name, d_in, param, [], 0, 2, [], []);
    [d_est2, ~, ~, ~, ~, ~, Q, R]= run_simulation(model_name, d_in, param, [], 0, 2, Q, R);

    plot_timeseries_multi({d_in, d_est1, d_est2}, {'RtVAvgxh', 'BlPitchC', 'LSSTipVxa', 'GenTq', 'YawBrTDxp'})
end

%% compare mex simulations
v= 11;
for  i= find(ref_sims.vv==v & ref_sims.yaw==0)'
    d_FAST= loadData(ref_sims.files{i}, wind_dir);

    cd(gen_dir)
    d_sim= run_simulation(model_name, d_FAST, param);
    cd(gen_dir_m)
    d_sim_M= run_simulation(model_name, d_FAST, param);
    plot_timeseries_multi({d_FAST, d_sim, d_sim_M}, {'RtVAvgxh', 'BlPitchC', 'GenTq', 'LSSTipVxa', 'YawBrTDxp'}, {'FAST', 'CADyn', 'CADynM'});
end