%% Demonstration/Test simulation of a model with tower fa, rotational, drive train and collective blade DOF using cpp compiled standalone and mex function versions

%% Setup environment
% RUN THE ENTIRE SCRIPT ONCE (F5), NOT THE CELL, OTHERWISE mfilename will not work!
% The rest of this schript is intended to be run cell by cell (Crtl+Enter)

clc
model_dir= fileparts(mfilename('fullpath'));
CADynTurb_dir= fullfile(model_dir, '../..');
addpath(fullfile(CADynTurb_dir, 'matlab'))
setupCADynTurb()

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T1B1cG';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'_direct.hpp', '_param.hpp', 'model_indices.m', 'model_parameters.m'};

if ~exist('TEST_MODE', 'var') || ~TEST_MODE; return; end

%% calculate parameters
cd(model_dir)
if exist('./params.mat', 'file')
    load('./params.mat')
else
    [param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 -2]}, 1);
    save('params', 'param', 'tw_sid', 'bd_sid')
end

%% generate and compile all source code
cd(model_dir)
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid, [0 1]);
writeModelParams(param, gen_dir);
compileModel(model_name, model_dir, gen_dir, files_to_generate)

%% compare stand-alone simulator with OpenFAST
cd(gen_dir)
fast_file= fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow/impulse_URef-12_maininput.fst');
wind_dir= '';

[~, base_file]= fileparts(fast_file);
sim_file= fullfile(gen_dir, [strrep(base_file, '_maininput', '') '.outb']);
d_sim= sim_standalone(fullfile(gen_dir, ['sim_' model_name]), fast_file, sim_file, '-a 0.99');

d_FAST= loadData(fast_file);

plot_timeseries_cmp(d_sim, d_FAST, {'RAWS', 'BlPitchC', 'HSShftV', 'Q_DrTr', 'YawBrTDxp', 'Q_BF1'});

%% sim mex model (feedforward)
cd(gen_dir)
clc
opts= struct('StepTol', 1e-8, 'AbsTol', 1e-6, 'RelTol', 1e-6, 'hminmin', 1E-8, 'jac_recalc_step', 4, 'max_steps', 10);
d_mex= run_simulation(model_name, d_sim, param, opts);
plot_timeseries_multi({d_FAST, d_sim, d_mex}, {'HSShftV', 'LSSTipVxa', 'YawBrTDxp', 'Q_BF1'},{'FAST', 'sim', 'CADyn mex'});

