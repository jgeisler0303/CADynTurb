%% set configuration variables
clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
if isempty(model_dir), model_dir= pwd; end

CADynTurb_dir= fullfile(model_dir, '../..');
run(fullfile(CADynTurb_dir, 'matlab/setupCADynTurb'))

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T1_est';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'_ode1.hpp', '_direct.hpp', '_param.hpp', 'model_indices.m', 'model_parameters.m', 'model_indices_ode1.m'};

%% calculate parameters
cd(model_dir)
if exist('./params.mat', 'file')
    load('params.mat')
else
    [param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 -2 ]}, 1);
    save('params', 'param', 'tw_sid', 'bd_sid')
end

%% generate and compile all source code
cd(model_dir)
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid, [0 1]); % no reduce const but const matrix elements only once
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

% Newmark beta
model_indices
ekf_config= T1_est_ekf_config;
ix_vwind= find(ekf_config.estimated_states==vwind_idx);
param.fixedQxx= zeros(length(ekf_config.estimated_states), 1);
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

    [d_est1, ~, ~, ~, ~, ~, Q, R, x_end_est, P_end]= run_simulation(model_name, d_in, param, [], 0, 2, [], []);
    d_est2                                         = run_simulation(model_name, d_in, param, [], 0, 2, Q, R, [], x_end_est, P_end);

    [d_est_RK1_1, ~, ~, ~, ~, ~, Q, R, x_end_est, P_end]= run_simulation([model_name '_RK1'], d_in, param, [], 0, 2, [], []);
    d_est_RK1_2                                         = run_simulation([model_name '_RK1'], d_in, param, [], 0, 2, Q, R, [], x_end_est, P_end);

    % plot_timeseries_multi({d_in, d_est1, d_est2}, {{'RAWS', 'RAWS'}, 'BlPitchC', 'LSSTipVxa', 'GenTq', 'YawBrTDxp'})
    plot_timeseries_multi({d_in, d_est2, d_est_RK1_1, d_est_RK1_2}, {{'RAWS'}}, {'FAST', 'Newmark', 'RK1 1', 'RK1 2'})
end

%% compare mex simulations
cd(gen_dir)

v= 11;
for  i= find(ref_sims.vv==v & ref_sims.yaw==0)'
    d_FAST= loadData(ref_sims.files{i}, wind_dir, false, param);

    d_sim= run_simulation(model_name, d_FAST, param);
    d_sim_RK1= run_simulation([model_name '_RK1'], d_FAST, param);

    plot_timeseries_multi({d_FAST, d_sim, d_sim_RK1}, {'RAWS', 'BlPitchC', 'GenTq', 'LSSTipVxa', 'YawBrTDxp'}, {'FAST', 'Newmark', 'RK1'});
end