%%
clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
CADynTurb_dir= fullfile(model_dir, '../..');
run(fullfile(CADynTurb_dir, 'matlab/setupCADynTurb'))

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T1B1cG';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'_direct.hpp', '_param.hpp', 'model_indices.m', 'model_parameters.m'};

%% calculate parameters
cd(model_dir)
if exist('./params.mat', 'file')
    load('params.mat')
else
    [param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 -2]}, 1);
    save('params', 'param', 'tw_sid', 'bd_sid')
end

%% CADynM model
% If you want to use this experimental feature, please clone
% https://github.com/jgeisler0303/CADynM in a directory parallel to CADynTurb
clc
cd(model_dir)

param.tw_sid= tw_sid;
param.bd_sid= bd_sid;
T1B1cG = modelT1B1cG(param);
eom = T1B1cG.getEOM;
T1B1cG.removeUnusedParameters();
matlabTemplateEngine('generated/model_M_parameters.m', 'model_parameters.m.mte', T1B1cG)
matlabTemplateEngine('generated/model_M_indices.m', 'model_indices.m.mte', T1B1cG)
matlabTemplateEngine('generated/T1B1cG_M_param.hpp', 'param.hpp.mte', T1B1cG)
matlabTemplateEngine('generated/T1B1cG_M_direct.hpp', 'direct.hpp.mte', T1B1cG)

%% Build mex-file for CADynM generated model
cd(gen_dir)
clc
makeCADynMex([model_name '_M'], '.', '', '', fullfile(CADynTurb_dir, 'simulator'))

%% generate and compile all source code
cd(model_dir)
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid, [], false);
writeModelParams(param, gen_dir);
compileModel(model_name, model_dir, gen_dir, files_to_generate)

%% compare stand-alone simulator with OpenFAST
cd(gen_dir)
fast_file= fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow/impulse_URef-12_maininput.fst');
wind_dir= '';

[~, base_file]= fileparts(fast_file);
sim_file= fullfile(gen_dir, [strrep(base_file, '_maininput', '') '.outb']);
d_sim= sim_standalone(fullfile(gen_dir, ['sim_' model_name]), fast_file, sim_file, '-a 0.99');

d_FAST= loadData(strrep(fast_file, '.fst', '.outb'), wind_dir);

plot_timeseries_cmp(d_sim, d_FAST, {'RtVAvgxh', 'BlPitchC', 'HSShftV', 'Q_DrTr', 'YawBrTDxp', 'Q_BF1'});

%% sim mex model (feedforward)
cd(gen_dir)
clc
opts= struct('StepTol', 1e-8, 'AbsTol', 1e-6, 'RelTol', 1e-6, 'hminmin', 1E-8, 'jac_recalc_step', 4, 'max_steps', 10);
d_mex= run_simulation(model_name, d_sim, param, opts);
d_mexM= run_simulation([model_name '_M'], d_sim, param, opts);
plot_timeseries_multi({d_FAST, d_sim, d_mex, d_mexM}, {'HSShftV', 'LSSTipVxa', 'YawBrTDxp', 'Q_BF1'},{'FAST', 'sim', 'CADyn mex', 'CADYnM mex'});

