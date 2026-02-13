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

files_to_generate= {'_direct.hpp', '_param.hpp', 'model_indices.m', 'model_parameters.m'};

%% calculate parameters
cd(model_dir)
if exist('./params.mat', 'file')
    load('params.mat')
else
    [param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 2]}, [1 2]);
    save('params', 'param', 'tw_sid', 'bd_sid')
end

%% generate and compile all source code
clc
cd(model_dir)
MaximaInterface.getInstance(1200,'',true);
MultiBodySystem.setSym();
tic
model = genCodeM(['model' model_name '.m'], gen_dir_m, files_to_generate, param, tw_sid, bd_sid);
toc
writeModelParams(param, gen_dir_m);
compileModel(model_name, model_dir, gen_dir_m, files_to_generate)


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
