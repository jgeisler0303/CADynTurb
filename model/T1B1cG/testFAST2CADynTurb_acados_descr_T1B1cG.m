%%
clc
model_dir= fileparts(matlab.desktop.editor.getActiveFilename);
CADynTurb_dir= fullfile(model_dir, '../..');
addpath(fullfile(CADynTurb_dir, 'matlab'))
setupCADynTurb(true)

fst_file= fullfile(CADynTurb_dir, '5MW_Baseline/5MW_Land_DLL_WTurb.fst');

model_name= 'T1B1cG';
gen_dir= fullfile(model_dir, 'generated_descr');

files_to_generate= {'model_indices.m', 'model_parameters.m', '_acados_descriptor.m'};

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
copyfile([model_name '_acados_external.m'], gen_dir)

%% descriptor system simulation
clc
import casadi.*
cd(gen_dir)

model_parameters;
p= acados_params(parameter_names, param);
[model, index_name] = T1B1cG_acados_descriptor;

fun_E = Function('funE', {model.x, model.u, model.p}, {model.E});
fun_f = Function('funf', {model.x, model.u, model.p}, {model.f_descr_expr});

fast_file= fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow/impulse_URef-12_maininput.fst');
wind_dir= '';
d_FAST= loadData(strrep(fast_file, '.fst', '.outb'), wind_dir, false, param);

[x_ref, u_ref]= convertFAST_CADyn(d_FAST, param, 0);

%%
N_sim= length(d_FAST.Time);
h = diff(d_FAST.Time(1:2));
n_sub_steps = 4;
x_sim= x_ref; % eigentlich nur für initial condition x0

for ii= 2:N_sim
    x_sim(:, ii) = x_sim(:, ii-1);
    u = u_ref(:, ii-1);
    for jj= 1:n_sub_steps
        val_E = full(fun_E(x_sim(:, ii), u, p));
        val_f = full(fun_f(x_sim(:, ii), u, p));
    
        if rcond(val_E)<1e-12
            % instability often manifests in noninvertible mass matrix
            break
        end
        x_dot = val_E\val_f;
    
        % explicti euler
        x_sim(:, ii) = x_sim(:, ii) + h/n_sub_steps*x_dot;
    end
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