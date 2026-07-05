%% Demonstration/Test simulation of a model with tower fa and rotational DOF using acados in descriptor form

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
gen_dir= fullfile(model_dir, 'generated_descr');

files_to_generate= {'model_indices.m', 'model_parameters.m', '_acados_descriptor.m'};

if ~exist('TEST_MODE', 'var') || ~TEST_MODE; return; end

%% calculate parameters
cd(model_dir)
if exist('./params.mat', 'file')
    load('params.mat')
else
    [param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 -2]}, 1);
    save('params', 'param', 'tw_sid', 'bd_sid')
end
param.rpm_max= 1200;
param.rpm_min= 800;
param.power_max= 5000e3;
param= calc_cx_poly('cp', param);
param= calc_cx_poly('ct', param);

%% generate and compile all source code
clc
cd(model_dir)
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid, [0 1]);
copyfile([model_name '_acados_external.m'], gen_dir)

%% descriptor system simulation
clc
import casadi.*
cd(gen_dir)

model_parameters;
p= acados_params(parameter_names, param);
[model, index_name] = T1_acados_descriptor;

fun_E = Function('funE', {model.x, model.u, model.p}, {model.E});
fun_f = Function('funf', {model.x, model.u, model.p}, {model.f_descr_expr});

% fast_file= fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow/impulse_URef-12_maininput.fst');
% wind_dir= '';
fast_file= fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow/1p1_NacYaw-0_URef-12_maininput.fst');
wind_dir= fullfile(CADynTurb_dir, 'ref_sim/wind');

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
