%%
clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
CADynTurb_dir= fullfile(model_dir, '../..');
run(fullfile(CADynTurb_dir, 'matlab/setupCADynTurb'))

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T2B2cG';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'_direct.hpp', '_param.hpp', 'model_indices.m', 'model_parameters.m', '_lin.m', '_nonlin.m'};

%% calculate parameters
cd(model_dir)
if exist('./params.mat', 'file')
    load('params.mat')
else
    [param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 2]}, [1 2]);
    save('params', 'param', 'tw_sid', 'bd_sid')
end

%% CADynM model
% If you want to use this experimental feature, please clone
% https://github.com/jgeisler0303/CADynM in a directory parallel to CADynTurb
clc
cd(model_dir)

param.tw_sid= tw_sid;
param.bd_sid= bd_sid;
T2B2cG = modelT2B2cG(param);
eom = T2B2cG.getEOM;
T2B2cG.addOutput('bld_edg_mom', T2B2cG.getConstraintForce('M_edg')/3);
T2B2cG.addOutput('bld_flp_mom', T2B2cG.getConstraintForce('M_flp')/3);

T2B2cG.removeUnusedParameters();
matlabTemplateEngine('generated/model_M_parameters.m', 'model_parameters.m.mte', T2B2cG)
matlabTemplateEngine('generated/model_M_indices.m', 'model_indices.m.mte', T2B2cG)
matlabTemplateEngine('generated/T2B2cG_M_param.hpp', 'param.hpp.mte', T2B2cG)
matlabTemplateEngine('generated/T2B2cG_M_direct.hpp', 'direct.hpp.mte', T2B2cG)

%% Build mex-file for CADynM generated model
cd(gen_dir)
clc
makeCADynMex([model_name '_M'], '.', '', '', fullfile(CADynTurb_dir, 'simulator'))

%% generate and compile all source code
cd(model_dir)
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid, [0 1]);
writeModelParams(param, gen_dir);
compileModel(model_name, model_dir, gen_dir, files_to_generate)

%% compare stand-alone simulator with OpenFAST
cd(gen_dir)
fast_file= fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow/impulse_URef-12_maininput.fst');
wind_dir= '';
options= '-a 0.99';

[~, base_file]= fileparts(fast_file);
sim_file= fullfile(gen_dir, [strrep(base_file, '_maininput', '') '.outb']);
d_sim= sim_standalone(fullfile(gen_dir, ['sim_' model_name]), fast_file, sim_file, options);

d_FAST= loadData(strrep(fast_file, '.fst', '.outb'), wind_dir);

% plot_timeseries_cmp(d_sim, d_FAST, {'RtVAvgxh', 'BlPitchC', 'HSShftV', 'GenTq', 'Q_TFA1', 'Q_TSS1', 'RootMxc', 'RootMyc'}, {}, {}, {}, 30);
plot_timeseries_cmp(d_sim, d_FAST, {'RtVAvgxh', 'BlPitchC', 'HSShftV', 'GenTq', 'Q_TFA1', 'Q_TSS1', 'Q_BF1', 'Q_BE1'});

%% 100ms step size simulation
options= '-a 0.99 -s 0.1';
d_sim_100ms= sim_standalone(fullfile(gen_dir, ['sim_' model_name]), fast_file, strrep(sim_file, '.outb', '_100ms.outb'), options);

plot_timeseries_cmp(d_sim, d_sim_100ms, {'RtVAvgxh', 'BlPitchC', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'});

%% sim mex model (feedforward)
opts= struct('StepTol', 1e-8, 'AbsTol', 1e-6, 'RelTol', 1e-6, 'hminmin', 1E-8, 'jac_recalc_step', 4, 'max_steps', 10);
d_mex= run_simulation(model_name, d_sim, param, opts);
d_mexM= run_simulation([model_name '_M'], d_sim, param, opts);
plot_timeseries_multi({d_FAST, d_sim, d_mex, d_mexM}, {'RtVAvgxh', 'y{(:, 4)}', 'y{(:, 5)}', 'y{(:, 6)}', 'y{(:, 7)}'}, {'FAST', 'sim', 'CADyn mex', 'CADYnM mex'});
% plot_timeseries_multi({d_FAST, d_sim, d_mex, d_mexM}, {'RtVAvgxh', 'HSShftV', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'}, {'FAST', 'sim', 'CADyn mex', 'CADYnM mex'});
% plot_timeseries_multi({d_FAST, d_sim, d_mex, d_mexM}, {'RtVAvgxh', 'BlPitchC', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'}, {'FAST', 'sim', 'CADyn mex', 'CADYnM mex'});
% plot_timeseries_cmp(d_sim, d_mex, {'RtVAvgxh', 'BlPitchC', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'});
% plot_timeseries_cmp(d_sim, d_mex, {'RtVAvgxh', 'LSSTipVxa', 'HSShftV', 'Q_DrTr', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'});

%% sim mex model 100ms (feedforward)
clc
d_mex_100ms= run_simulation(model_name, d_sim_100ms, param);
plot_timeseries_cmp(d_sim_100ms, d_mex_100ms, {'RtVAvgxh', 'Q_DrTr', 'HSShftV', 'Q_GeAz', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'});