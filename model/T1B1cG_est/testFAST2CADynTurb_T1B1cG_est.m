%% prepare paths
clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
run(fullfile(model_dir, '../../matlab/setupCADynTurb'))

fst_file= '../../5MW_Baseline/5MW_Land_DLL_WTurb.fst';

model_name= 'T1B1cG_est';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'cpp_direct'};

%% calculate parameters
[param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 -2 ]}, 1);
save('params', 'param', 'tw_sid', 'bd_sid')

%% generate and compile all source code
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid);
writeModelParams(param, gen_dir);
makeCADynMex(model_name, gen_dir, '', '', fullfile(model_dir, '../../simulator'))

%% compile ekf mex
clc
cd(gen_dir)
copyfile(fullfile(model_dir, [model_name '_ekf_config.m']), gen_dir)
makeEKFMexSource(model_name)
makeMex(fullfile(gen_dir, [model_name '_ekf_mex.cpp']), ...
    {'.', fullfile(model_dir, '../../../CADyn/src'), fullfile(model_dir, '../../simulator')}, ...
    '', ...
    '$CXXFLAGS -std=c++11 -Wall -fdiagnostics-show-option -O2 -march=native');

%% get reference simulations 1p1
sim_dir= fullfile(model_dir, '../../ref_sim/sim_dyn_inflow');
wind_dir= fullfile(model_dir, '../../ref_sim/wind');

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
param.Tadapt= 30;
param.adaptScale= [2 1];
param.adaptUpdate= ones(8, 1);
param.adaptUpdate(4)= 3;

v= 12;
for  i= find(ref_sims.vv==v & ref_sims.yaw==0)'
    d_in= loadData(ref_sims.files{i}, wind_dir);

    [d_est1, ~, ~, ~, ~, ~, Q, R]= run_simulation(model_name, d_in, param, [], 0, 2, [], []);
    [d_est2, ~, ~, ~, ~, ~, Q, R]= run_simulation(model_name, d_in, param, [], 0, 2, Q, R);

    plot_timeseries_multi({d_in, d_est1, d_est2}, {'RtVAvgxh', 'Q_TFA1' 'Q_BF1' 'LSSTipVxa', 'Q_DrTr'})
end