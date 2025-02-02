%%
clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
CADynTurb_dir= fullfile(model_dir, '../..');
run(fullfile(CADynTurb_dir, 'matlab/setupCADynTurb'))

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T2B2cG';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'cpp_direct'};

%% calculate parameters
[param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 2]}, [1 2]);
save('params', 'param', 'tw_sid', 'bd_sid')

%% generate and compile all source code
cd(model_dir)
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid);
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
plot_timeseries_cmp(d_sim, d_mex, {'RtVAvgxh', 'BlPitchC', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'});
% plot_timeseries_cmp(d_sim, d_mex, {'RtVAvgxh', 'LSSTipVxa', 'HSShftV', 'Q_DrTr', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'});

%% sim mex model 100ms (feedforward)
clc
d_mex_100ms= run_simulation(model_name, d_sim_100ms, param);
plot_timeseries_cmp(d_sim_100ms, d_mex_100ms, {'RtVAvgxh', 'Q_DrTr', 'HSShftV', 'Q_GeAz', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'});