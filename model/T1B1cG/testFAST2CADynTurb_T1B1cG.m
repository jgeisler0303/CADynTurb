%%
clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
run(fullfile(model_dir, '../matlab/setupCADynTurb'))

fst_file= '../../5MW_Baseline/5MW_Land_DLL_WTurb.fst';

model_name= 'T1B1cG';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'cpp_direct'};

%% calculate parameters
[param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 -2]}, 1);
save('params', 'param', 'tw_sid', 'bd_sid')

%% generate and compile all source code
cd(model_dir)
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid);
writeModelParams(param, gen_dir);
compileModel(model_name, model_dir, gen_dir, files_to_generate)

%% compare stand-alone simulator with OpenFAST
cd(gen_dir)
fast_file= fullfile(model_dir, '../../ref_sim/sim_no_inflow/impulse_URef-12_maininput.fst');
wind_dir= '';

[~, base_file]= fileparts(fast_file);
sim_file= fullfile(gen_dir, [strrep(base_file, '_maininput', '') '.outb']);
d_sim= sim_standalone(fullfile(gen_dir, ['sim_' model_name]), fast_file, sim_file, '-a 0.99');

d_FAST= loadData(strrep(fast_file, '.fst', '.outb'), wind_dir);

plot_timeseries_cmp(d_sim, d_FAST, {'RtVAvgxh', 'BlPitchC', 'HSShftV', 'GenTq', 'YawBrTDxp', 'Q_BF1'});
