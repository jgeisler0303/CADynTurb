%% set configuration variables
clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
CADynTurb_dir= fullfile(model_dir, '../..');
run(fullfile(CADynTurb_dir, 'matlab/setupCADynTurb'))

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T1B1i';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'cpp_direct'};

%% calculate parameters
cd(model_dir)
if exist('./params.mat', 'file')
    load('params.mat')
else
    [param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 -2]}, 1);
    save('params', 'param', 'tw_sid', 'bd_sid')
end

%% generate and compile all source code
cd(model_dir)
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid);
writeModelParams(param, gen_dir);
compileModel(model_name, model_dir, gen_dir, files_to_generate)

%% compare stand-alone simulator with OpenFAST
cd(gen_dir)
% fast_file= fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow/impulse_URef-12_maininput.fst');
% wind_dir= '';
% 
% [~, base_file]= fileparts(fast_file);
% sim_file= fullfile(gen_dir, [strrep(base_file, '_maininput', '') '.outb']);

sim_dir= fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow');
wind_dir= fullfile(CADynTurb_dir, 'ref_sim/wind');

ref_sims= get_ref_sims(sim_dir, '1p1*_maininput.outb');
v= 12;
i= find(ref_sims.vv==12 & ref_sims.yaw==0)';
fast_file= strrep(ref_sims.files{i}, '.outb', '.fst');

[~, base_file]= fileparts(fast_file);
sim_file= fullfile(gen_dir, [strrep(base_file, '_maininput', '') '.outb']);

d_sim= sim_standalone(fullfile(gen_dir, ['sim_' model_name]), fast_file, sim_file, '-a 0.99');

d_FAST= loadData(strrep(fast_file, '.fst', '.outb'), wind_dir, 0);

% plot_timeseries_cmp(d_FAST, d_sim, {'RtVAvgxh', 'BlPitchC1', 'LSSTipPxa', 'YawBrTDxp', {'RootMxb1' 'RootMxb2' 'RootMxb3'}, {'RootMyb1' 'RootMyb2' 'RootMyb3'}})
plot_timeseries_cmp(d_FAST, d_sim, {'RtVAvgxh', 'RootMxb1' 'RootMxb2' 'RootMxb3', 'RootMyb1' 'RootMyb2' 'RootMyb3'})