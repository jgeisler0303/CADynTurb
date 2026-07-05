%% Demonstration/Test simulation of a model with tower fa and rotational DOF using acados in implicit ode form

%% Setup environment
% RUN THE ENTIRE SCRIPT ONCE (F5), NOT THE CELL, OTHERWISE mfilename will not work!
% The rest of this schript is intended to be run cell by cell (Crtl+Enter)

clc
model_dir= fileparts(mfilename('fullpath'));
CADynTurb_dir= fullfile(model_dir, '../..');
addpath(fullfile(CADynTurb_dir, 'matlab'))
setupCADynTurb(true)

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T1';
gen_dir= fullfile(model_dir, 'generated');

files_to_generate= {'model_indices.m', 'model_parameters.m', '_acados.m', '_acados_descriptor.m', '_param.hpp'};

if ~exist('TEST_MODE', 'var') || ~TEST_MODE; return; end

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

%% make acados model
clc
clear mex
acados_model_solver= make_acados_sim(param, model_name, gen_dir);

%% run acados simulation
fast_file= fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow/impulse_URef-12_maininput.fst');
d_FAST= loadData(fast_file);

load('params_config.mat')
d_acados= run_acados_simulation(acados_model_solver, d_FAST, p_);
plot_timeseries_cmp(d_acados, d_FAST, {'RAWS', 'BlPitchC', 'LSSTipVxa', 'GenTq', 'YawBrTDxp'});

%% make acados standalone simulator
clc
cd(gen_dir)
compileAcados(model_name, model_dir, gen_dir)

%% compare acados stand-alone simulator with OpenFAST
cd(gen_dir)
fast_file= fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow/impulse_URef-12_maininput.fst');

[~, base_file]= fileparts(fast_file);
sim_file= fullfile(gen_dir, [strrep(base_file, '_maininput', '_acados') '.outb']);
d_acados= sim_standalone(fullfile(gen_dir, ['sim_' model_name '_acados']), fast_file, sim_file, '-a 0.99');

d_FAST= loadData(fast_file);

plot_timeseries_cmp(d_acados, d_FAST, {'RAWS', 'BlPitchC', 'LSSTipVxa', 'GenTq', 'YawBrTDxp'});

%% descriptor system simulation
clc
import casadi.*
cd(gen_dir)

model_parameters;
p= acados_params(parameter_names, param);
[model, index_name] = T1_acados_descriptor;

fun_E = Function('funE', {model.x, model.u, model.p}, {model.E});
fun_f = Function('funf', {model.x, model.u, model.p}, {model.f_descr_expr});

x = [0, 0, 0, 1.2]';
u = [12, 10e3, 0]';

fast_file= fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow/impulse_URef-12_maininput.fst');
wind_dir= '';
d_FAST= loadData(fast_file);

[x_ref, u_ref]= convertFAST_CADyn(d_FAST, param, 0);

N_sim= length(d_FAST.Time);
h = diff(d_FAST.Time(1:2));
x_sim= x_ref; % eigentlich nur für initial condition x0

for ii= 2:N_sim
    x = x_sim(:, ii-1);
    u = u_ref(:, ii-1);

    val_E = full(fun_E(x, u, p));
    val_f = full(fun_f(x, u, p));

    x_dot = val_E\val_f;

    % explicti euler
    x_sim(:, ii) = x_sim(:, ii-1) + h*x_dot;
end

n = size(x_sim, 1);
tiledlayout(n, 1)
for i = 1:n
    nexttile
    plot(d_FAST.Time, x_ref(i, :), d_FAST.Time, x_sim(i, :))
    grid on
    ylabel(index_name.name{i}, 'Interpreter','none')
end
legend('FAST', 'sim')
