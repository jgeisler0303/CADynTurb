%%
clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
run(fullfile(model_dir, '../../matlab/setupCADynTurb'))

fst_file= '../../5MW_Baseline/5MW_Land_DLL_WTurb.fst';

model_name= 'T1_opt';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'cpp_direct', 'acados'};

%% calculate parameters
clc
cd(model_dir)
[param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 -2]}, 1);
param.vwind= 12;
save('params', 'param', 'tw_sid', 'bd_sid')

%% generate and compile all source code
clc
cd(model_dir)
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid);
writeModelParams(param, gen_dir);
cd(gen_dir)
makeCADynMex(model_name, '.', '', '', fullfile(model_dir, '../../simulator'))

%%
if isempty(getenv('ACADOS_INSTALL_DIR'))
    return
end

%% make acados model
clc
acados_model= make_acados_sim(model_name, gen_dir);

%% run acados simulation
fast_file= fullfile(model_dir, '../../ref_sim/sim_no_inflow/impulse_URef-12_maininput.fst');
wind_dir= '';
d_FAST= loadData(strrep(fast_file, '.fst', '.outb'), wind_dir);

load('params_config.mat')
d_acados= run_acados_simulation(acados_model, d_FAST, p_);
plot_timeseries_cmp(d_acados, d_FAST, {'RtVAvgxh', 'BlPitchC', 'LSSTipVxa', 'GenTq', 'YawBrTDxp'});