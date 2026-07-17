%% Demonstration/Test Extended Kalman Filter with wind estimation model with tower fa and rotational DOF
%% Setup environment
% RUN THE ENTIRE SCRIPT ONCE (F5), NOT THE CELL, OTHERWISE mfilename will not work!
% The rest of this schript is intended to be run cell by cell (Crtl+Enter)

clc
model_dir= fileparts(mfilename('fullpath'));
addpath(fullfile(CADynTurb_dir, 'matlab'))
setupCADynTurb()

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T1_est';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'_ode1.hpp', '_direct.hpp', '_param.hpp', 'model_indices.m', 'model_parameters.m', 'model_indices_ode1.m'};

if ~exist('TEST_MODE', 'var') || ~TEST_MODE; return; end

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

ref_sims= get_ref_sims(sim_dir, '1p1*_maininput.fst');

%% run Kalman filter
clc
cd(gen_dir)

param.Tadapt= 30;

% prepare EKF
model_indices
ekf_config= T1_est_ekf_config;
ix_vwind= find(ekf_config.estimated_states==vwind_idx);
param.fixedQxx= zeros(length(ekf_config.estimated_states), 1);

v= 12;
for  i= find(ref_sims.vv==v & ref_sims.yaw==0)'
    d_in= loadData(ref_sims.files{i});

    ss1= std(d_in.Wind1VelX.Data);
    param.fixedQxx(ix_vwind)= (ss1/200)^2;

    [d_est1, ~, ~, ~, ~, ~, Q, R, x_end_est, P_end]= run_simulation(model_name, d_in, param, [], 0, 2, [], []);
    d_est2                                         = run_simulation(model_name, d_in, param, [], 0, 2, Q, R, [], x_end_est, P_end);

    plot_timeseries_multi({d_in, d_est1, d_est2}, {{'RAWS', 'RAWS'}, 'BlPitchC', 'LSSTipVxa', 'GenTq', 'YawBrTDxp'})
    % plot_timeseries_multi({d_in, d_est2}, {{'RAWS'}}, {'FAST', 'EKF'})
end