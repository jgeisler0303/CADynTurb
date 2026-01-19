%% CADynM model
% If you want to use this experimental feature, please clone
% https://github.com/jgeisler0303/CADynM in a directory parallel to CADynTurb

clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
CADynTurb_dir= fullfile(model_dir, '../..');
run(fullfile(CADynTurb_dir, 'matlab/setupCADynTurb'))

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T2B2cG';
gen_dir_m= fullfile(model_dir, 'generated_M');

files_to_generate= {'_direct.hpp', '_param.hpp', 'model_indices.m', 'model_parameters.m', '_lin.m', '_nonlin.m'};

%% calculate parameters
cd(model_dir)
if exist('./params.mat', 'file')
    load('params.mat')
else
    [param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 2]}, [1 2]);
    save('params', 'param', 'tw_sid', 'bd_sid')
end

%% Generate Model
clc
cd(model_dir)

param.tw_sid= tw_sid;
param.bd_sid= bd_sid;
T2B2cG = modelT2B2cG(param);
eom = T2B2cG.getEOM;
T2B2cG.addOutput('bld_edg_mom', T2B2cG.getConstraintForce('M_edg')/3);
T2B2cG.addOutput('bld_flp_mom', T2B2cG.getConstraintForce('M_flp')/3);

T2B2cG.removeUnusedParameters();

[~, ~] = mkdir(gen_dir_m);
copyfile(fullfile(model_dir, [model_name '_Externals.hpp']), gen_dir_m)
matlabTemplateEngine('generated_M/model_parameters.m', 'model_parameters.m.mte', T2B2cG)
matlabTemplateEngine('generated_M/model_indices.m', 'model_indices.m.mte', T2B2cG)
matlabTemplateEngine('generated_M/T2B2cG_param.hpp', 'param.hpp.mte', T2B2cG)
matlabTemplateEngine('generated_M/T2B2cG_direct.hpp', 'direct.hpp.mte', T2B2cG)
extermals_file = fullfile(gen_dir_m, 'T2B2cG_Externals.hpp');
if ~exist(extermals_file, 'file')
    matlabTemplateEngine(extermals_file, 'Externals.hpp.mte', T2B2cG)
end

%% Build mex-file for CADynM generated model
cd(gen_dir_m)
clc
makeCADynMex(model_name, '.', '', '', fullfile(CADynTurb_dir, 'simulator'))

%% sim mex models (feedforward)
if ~exist('d_sim', 'var')
    error('Please supply some reference simulation "d_sim" via the testFAST2CADynTurbM_T2B2cG.m script.')
end
opts= struct('StepTol', 1e-8, 'AbsTol', 1e-6, 'RelTol', 1e-6, 'hminmin', 1E-8, 'jac_recalc_step', 4, 'max_steps', 10);

cd(fullfile(gen_dir_m, '..', 'generated'))
d_mex= run_simulation(model_name, d_sim, param, opts);
cd(gen_dir_m)
d_mexM= run_simulation(model_name, d_sim, param, opts);

plot_timeseries_multi({d_sim, d_mex, d_mexM}, {'RtVAvgxh', 'y{(:, 4)}', 'y{(:, 5)}', 'y{(:, 6)}', 'y{(:, 7)}'}, {'sim', 'CADyn mex', 'CADYnM mex'});
% plot_timeseries_multi({d_sim, d_mex, d_mexM}, {'RtVAvgxh', 'HSShftV', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'}, {'sim', 'CADyn mex', 'CADYnM mex'});
% plot_timeseries_multi({d_sim, d_mex, d_mexM}, {'RtVAvgxh', 'BlPitchC', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'}, {'sim', 'CADyn mex', 'CADYnM mex'});