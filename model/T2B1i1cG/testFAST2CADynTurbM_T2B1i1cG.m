%% CADynM model
% If you want to use this experimental feature, please clone
% https://github.com/jgeisler0303/CADynM in a directory parallel to CADynTurb

clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
CADynTurb_dir= fullfile(model_dir, '../..');
run(fullfile(CADynTurb_dir, 'matlab/setupCADynTurb'))

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T2B1i1cG';
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
T2B1i1cG = modelT2B1i1cG(param);
eom = T2B1i1cG.getEOM;
T2B1i1cG.addOutput('bld1_flp_mom', T2B1i1cG.getConstraintForce('M_flp1'));
T2B1i1cG.addOutput('bld1_edg_mom', T2B1i1cG.getConstraintForce('M_edg1'));
T2B1i1cG.addOutput('bld2_flp_mom', T2B1i1cG.getConstraintForce('M_flp2'));
T2B1i1cG.addOutput('bld2_edg_mom', T2B1i1cG.getConstraintForce('M_edg2'));
T2B1i1cG.addOutput('bld3_flp_mom', T2B1i1cG.getConstraintForce('M_flp3'));
T2B1i1cG.addOutput('bld3_edg_mom', T2B1i1cG.getConstraintForce('M_edg3'));
T2B1i1cG.addOutput('tow_bot_fa_mom', T2B1i1cG.getConstraintForce('M_tow_y'));
T2B1i1cG.addOutput('tow_bot_ss_mom', T2B1i1cG.getConstraintForce('M_tow_x'));

T2B1i1cG.removeUnusedParameters();

[~, ~] = mkdir(gen_dir_m);
copyfile(fullfile(model_dir, [model_name '_Externals.hpp']), gen_dir_m)
matlabTemplateEngine('generated_M/model_parameters.m', 'model_parameters.m.mte', T2B1i1cG)
matlabTemplateEngine('generated_M/model_indices.m', 'model_indices.m.mte', T2B1i1cG)
matlabTemplateEngine('generated_M/T2B1i1cG_param.hpp', 'param.hpp.mte', T2B1i1cG)
matlabTemplateEngine('generated_M/T2B1i1cG_direct.hpp', 'direct.hpp.mte', T2B1i1cG)
extermals_file = fullfile(gen_dir_m, 'T2B1i1cG_Externals.hpp');
if ~exist(extermals_file, 'file')
    matlabTemplateEngine(extermals_file, 'Externals.hpp.mte', T2B1i1cG)
end

%% Build mex-file for CADynM generated model
cd(gen_dir_m)
clc
makeCADynMex(model_name, '.', '', '', fullfile(CADynTurb_dir, 'simulator'))

%% sim mex models (feedforward)
if ~exist('d_sim', 'var')
    error('Please supply some reference simulation "d_sim" via the testFAST2CADynTurbM_T2B1i1cG.m script.')
end
opts= struct('StepTol', 1e-8, 'AbsTol', 1e-6, 'RelTol', 1e-6, 'hminmin', 1E-8, 'jac_recalc_step', 4, 'max_steps', 10);

cd(fullfile(gen_dir_m, '..', 'generated'))
d_mex= run_simulation(model_name, d_sim, param, opts);
cd(gen_dir_m)
d_mexM= run_simulation(model_name, d_sim, param, opts);

% plot_timeseries_multi({d_mex, d_mexM}, {'RtVAvgxh', 'y{(:, 4)}', 'y{(:, 5)}', 'y{(:, 10)}', 'y{(:, 11)}'}, {'CADyn mex', 'CADYnM mex'});
plot_timeseries_multi({d_sim, d_mex, d_mexM}, {'RtVAvgxh', 'HSShftV', 'YawBrTDxp', 'YawBrTDyp', 'Q_B1F1', 'Q_BE1'}, {'sim', 'CADyn mex', 'CADYnM mex'});
