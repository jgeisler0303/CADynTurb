%%
clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
CADynTurb_dir= fullfile(model_dir, '../..');
run(fullfile(CADynTurb_dir, 'matlab/setupCADynTurb'))

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T1';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'_direct.hpp', '_param.hpp', 'model_indices.m', 'model_parameters.m', '_acados.m', '_pre_calc.m', '_descriptor_form.hpp', '_lin.m', '_nonlin.m'};

%% calculate parameters
cd(model_dir)
if exist('./params.mat', 'file')
    load('params.mat')
else
    [param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 -2]}, 1);
    save('params', 'param', 'tw_sid', 'bd_sid')
end

%% generate and compile all source code
clc
cd(model_dir)
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid, [0 1]);
writeModelParams(param, gen_dir);
compileModel(model_name, model_dir, gen_dir, files_to_generate)

%% compare stand-alone simulator with OpenFAST
cd(gen_dir)
fast_file= fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow/impulse_URef-12_maininput.fst');
% fast_file= fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow/impulse_URef-12_maininput.fst');
wind_dir= '';

[~, base_file]= fileparts(fast_file);
sim_file= fullfile(gen_dir, [strrep(base_file, '_maininput', '') '.outb']);
d_sim= sim_standalone(fullfile(gen_dir, ['sim_' model_name]), fast_file, sim_file, '-a 0.99');

d_FAST= loadData(strrep(fast_file, '.fst', '.outb'), wind_dir);

plot_timeseries_cmp(d_sim, d_FAST, {'RtVAvgxh', 'BlPitchC', 'LSSTipVxa', 'GenTq', 'YawBrTDxp'});

%%
if isempty(getenv('ACADOS_INSTALL_DIR'))
    return
end

%% make acados model
clc
acados_model_solver= make_acados_sim(model_name, gen_dir);

%% run acados simulation
fast_file= fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow/impulse_URef-12_maininput.fst');
wind_dir= '';
d_FAST= loadData(strrep(fast_file, '.fst', '.outb'), wind_dir);

load('params_config.mat')
d_acados= run_acados_simulation(acados_model_solver, d_FAST, p_);
plot_timeseries_cmp(d_acados, d_FAST, {'RtVAvgxh', 'BlPitchC', 'LSSTipVxa', 'GenTq', 'YawBrTDxp'});

%% make acados standalone simulator
clc
cd(gen_dir)
sim_generate_c_code(acados_model_solver.sim)
compileAcados(model_name, model_dir, gen_dir)
% copy_acados_libs(gen_dir)

%% compare acados stand-alone simulator with OpenFAST
cd(gen_dir)
fast_file= fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow/impulse_URef-12_maininput.fst');
wind_dir= '';

[~, base_file]= fileparts(fast_file);
sim_file= fullfile(gen_dir, [strrep(base_file, '_maininput', '_acados') '.outb']);
d_acados= sim_standalone(fullfile(gen_dir, ['sim_' model_name '_acados']), fast_file, sim_file, '-a 0.99');

d_FAST= loadData(strrep(fast_file, '.fst', '.outb'), wind_dir);

plot_timeseries_cmp(d_acados, d_FAST, {'RtVAvgxh', 'BlPitchC', 'LSSTipVxa', 'GenTq', 'YawBrTDxp'});
