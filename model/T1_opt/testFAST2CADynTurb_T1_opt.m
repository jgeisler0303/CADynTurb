%% Setup environment
% RUN THE ENTIRE SCRIPT ONCE (F5), NOT THE CELL, OTHERWISE mfilename will not work!
% The rest of this schript is intended to be run cell by cell (Crtl+Enter)

clc
model_dir= fileparts(mfilename('fullpath'));
CADynTurb_dir= fullfile(model_dir, '../..');
run(fullfile(CADynTurb_dir, 'matlab/setupCADynTurb'))

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T1_opt';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'model_indices.m', 'model_parameters.m', '_acados.m', 'model_indices_ode1.m'};

if ~exist('TEST_MODE', 'var') || ~TEST_MODE; return; end

%% Calculate parameters
clc
cd(model_dir)
if exist('./params.mat', 'file')
    load('params.mat')
else
    [param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 -2]}, 1);
end
param.vwind= 12;
param.power_max= 5000e3;
param.rpm_max= 1200;
param.rpm_min= 800;
param.pit_min= 0;
param.w_cost= zeros(9, 1); % unused, but needed by eco_multi_cost

%% Generate and compile all source code
clc
cd(model_dir)
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid, [0 1]);

%% Make acados model
clc
cd(gen_dir)
acados_model_solver= make_acados_sim(param, model_name, gen_dir);
acados_model_func= str2func([model_name '_acados']);
[~, ~, model_info]= acados_model_func(param);

%% Run acados simulation
cd(gen_dir)
fast_file= fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow/impulse_URef-12_maininput.fst');
wind_dir= '';
d_FAST= loadData(strrep(fast_file, '.fst', '.outb'), wind_dir, false, param);

d_acados= run_acados_simulation(acados_model_solver, d_FAST, param, model_info);
plot_timeseries_cmp(d_FAST, d_acados, {'RAWS', 'BlPitchC', 'LSSTipVxa', 'GenTq', 'YawBrTDxp'});