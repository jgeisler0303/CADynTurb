%% set configuration variables
clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
run(fullfile(model_dir, '../../matlab/setupCADynTurb'))

fst_file= '../../5MW_Baseline/5MW_Land_DLL_WTurb.fst';

model_name= 'T1B1i_est';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'cpp_direct'};

%% calculate parameters
[param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 -2 ]}, 1);
save('params', 'param', 'tw_sid', 'bd_sid')

%% generate and compile all source code
clc
cd(model_dir)
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid, 1);
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

%% run Kalman filter
cd(gen_dir)
param.Tadapt= 30;
get_ekf_config= str2func([model_name '_ekf_config']);
ekf_config= get_ekf_config();
model_indices

ix_vwind= find(ekf_config.estimated_states==vwind_idx);
ix_h_shear= find(ekf_config.estimated_states==h_shear_idx);
ix_v_shear= find(ekf_config.estimated_states==v_shear_idx);
param.fixedQxx= zeros(length(ekf_config.estimated_states), 1);
param.fixedQxx(ix_vwind)= (10^-2.8)^2; % for 10ms
param.fixedQxx(ix_h_shear)= eps; %(10^-4)^2; % for 10ms
param.fixedQxx(ix_v_shear)= eps; %(10^-4)^2; % for 10ms

% param.adaptScale= [2 1];

v= 12;
for  i= find(ref_sims.vv==12 & ref_sims.yaw==0)'
    d_in= loadData(ref_sims.files{i}, wind_dir);

    [d_est1, ~, ~, ~, ~, ~, Q, R, x_end, P_end]= run_simulation(model_name, d_in, param, [], 0, 2, [], []);
    [d_est2, ~, ~, ~, ~, ~, Q, R]= run_simulation(model_name, d_in, param, [], 0, 2, Q, R, [], x_end, P_end);
    
    plot_timeseries_cmp(d_in, d_est2, {'RtVAvgxh', 'RtHSAvg', 'RtVSAvg', 'BlPitchC', 'LSSTipVxa', 'YawBrTDxp', 'RootMxb1', 'RootMyb1'})
end

