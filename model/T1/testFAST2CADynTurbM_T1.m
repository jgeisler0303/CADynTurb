%% CADynM model
% If you want to use this experimental feature, please clone
% https://github.com/jgeisler0303/CADynM in a directory parallel to CADynTurb
clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
CADynTurb_dir= fullfile(model_dir, '../..');
run(fullfile(CADynTurb_dir, 'matlab/setupCADynTurb'))

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T1';
gen_dir_m= fullfile(model_dir, 'generated_M');

files_to_generate= {'_direct.hpp', '_param.hpp', 'model_indices.m', 'model_parameters.m'};

%% calculate parameters
cd(model_dir)
if exist('./params.mat', 'file')
    load('params.mat')
else
    [param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 -2]}, 1);
    save('params', 'param', 'tw_sid', 'bd_sid')
end

%%
clc
cd(model_dir)

param.tw_sid= tw_sid;
T1 = modelT1(param);
eom = T1.getEOM;
T1.removeUnusedParameters();

[~, ~] = mkdir(gen_dir_m);
copyfile(fullfile(model_dir, [model_name '_Externals.hpp']), gen_dir_m)
matlabTemplateEngine('generated_M/model_parameters.m', 'model_parameters.m.mte', T1)
matlabTemplateEngine('generated_M/model_indices.m', 'model_indices.m.mte', T1)
matlabTemplateEngine('generated_M/T1_param.hpp', 'param.hpp.mte', T1)
matlabTemplateEngine('generated_M/T1_direct.hpp', 'direct.hpp.mte', T1)
matlabTemplateEngine('generated_M/T1_acados.m', 'acados.m.mte', T1)
matlabTemplateEngine('generated_M/T1_descriptor_form.m', 'descriptor_form.hpp.mte', T1)
extermals_file = fullfile(gen_dir_m, 'T1_Externals.hpp');
if ~exist(extermals_file, 'file')
    matlabTemplateEngine(extermals_file, 'Externals.hpp.mte', T1)
end

%% Build mex-file for CADynM generated model
cd(gen_dir_m)
clc
makeCADynMex(model_name, '.', '', '', fullfile(CADynTurb_dir, 'simulator'))

%% sim mex models (feedforward)
if ~exist('d_sim', 'var')
    error('Please supply some reference simulation "d_sim" via the testFAST2CADynTurbM_T1.m script.')
end
opts= struct('StepTol', 1e-8, 'AbsTol', 1e-6, 'RelTol', 1e-6, 'hminmin', 1E-8, 'jac_recalc_step', 4, 'max_steps', 10);

cd(fullfile(gen_dir_m, '..', 'generated'))
d_mex= run_simulation(model_name, d_sim, param, opts);
cd(gen_dir_m)
d_mexM= run_simulation(model_name, d_sim, param, opts);

plot_timeseries_multi({d_sim, d_mex, d_mexM}, {'RtVAvgxh', 'BlPitchC', 'LSSTipVxa', 'GenTq', 'YawBrTDxp'},{'sim', 'CADyn mex', 'CADYnM mex'});