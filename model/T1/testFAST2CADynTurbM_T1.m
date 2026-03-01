%% CADynM model
% If you want to use this experimental feature, please clone
% https://github.com/jgeisler0303/CADynM in a directory parallel to CADynTurb
clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
if isempty(model_dir), model_dir= pwd; end

CADynTurb_dir= fullfile(model_dir, '../..');
run(fullfile(CADynTurb_dir, 'matlab/setupCADynTurb'))

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T1';
gen_dir_m= fullfile(model_dir, 'generated_M');

files_to_generate= {'_ode1.hpp', '_direct.hpp', '_param.hpp', 'model_indices.m', 'model_indices_ode1.m', 'model_parameters.m', '_acados.m', '_descriptor_form.hpp'};

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
MultiBodySystem.setSym();
MultiBodySystem.setKinematicsFromLocal();
tic
model = genCodeM(['model' model_name '.m'], gen_dir_m, files_to_generate, param, tw_sid, bd_sid);
toc
writeModelParams(param, gen_dir_m);
compileModel(model_name, model_dir, gen_dir_m, files_to_generate)

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

%% compare stand-alone RK1 simulator with OpenFAST
cd(gen_dir_m)
fast_file= fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow/impulse_URef-12_maininput.fst');
% fast_file= fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow/impulse_URef-12_maininput.fst');
wind_dir= '';

d_FAST= loadData(strrep(fast_file, '.fst', '.outb'), wind_dir);

[~, base_file]= fileparts(fast_file);
sim_file= fullfile(gen_dir_m, [strrep(base_file, '_maininput', '') '.outb']);

d_sim= sim_standalone(fullfile(gen_dir_m, ['sim_' model_name]), fast_file, sim_file, '-a 0.99');
d_sim_RK1= sim_standalone(fullfile(gen_dir_m, ['sim_' model_name '_RK1']), fast_file, sim_file, '-a 0.99');

plot_timeseries_multi({d_FAST, d_sim, d_sim_RK1}, {'RtVAvgxh', 'BlPitchC', 'LSSTipVxa', 'GenTq', 'YawBrTDxp'}, {'FAST', 'Newmark beta', 'RK1'});

