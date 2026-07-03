%% Setup environment
% RUN THE ENTIRE SCRIPT ONCE (F5), NOT THE CELL, OTHERWISE mfilename will not work!
% The rest of this schript is intended to be run cell by cell (Crtl+Enter)

clc
model_dir= fileparts(mfilename('fullpath'));
CADynTurb_dir= fullfile(model_dir, '../..');
run(fullfile(CADynTurb_dir, 'matlab/setupCADynTurb'))

model_name= 'T1_opt';
gen_dir= fullfile(model_dir, 'generated_tracking_ocp');

files_to_generate= {'model_indices.m', 'model_parameters.m', '_acados.m', '_param.hpp'};

if ~exist('TEST_MODE', 'var') || ~TEST_MODE; return; end

%% calculate parameters
clc
cd(model_dir)
if exist('./params.mat', 'file')
    load('params.mat')
else
    [param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 -2]}, 1);
    param.vwind= 12;
    save('params', 'param', 'tw_sid', 'bd_sid')
end
param.cp_lut = param.cp';
param.power_max= 5000e3;
param.rpm_max= 1200;
param.rpm_min= 800;
param.pit_min= 0;
param.max_trq= 45e3;
param.max_trq_rate= 40e3;
param.max_pit_rate= 7/180*pi;
param.w_cost= zeros(1, 9); % just some values, not needed here
[param.vwind_vec, param.theta_full_lut, param.theta_opt_lut, param.lambda_opt] = pitch_ref_lut(param);


%% generate and compile all source code
clc
cd(model_dir)
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid, [0 1]);
copyfile(fullfile(model_dir, 'calc_tracking_references.m'), gen_dir)

%% make acados OCP
clc
cd(gen_dir)

% Solver settings
N = 150;                        % Number of time steps
T = 15;                         % time horizon length
x0 = [0.4; 40e3; 0; 0; 1.3];    % just some values, will change later

% Model dynamics
acados_model_func= str2func([model_name '_acados']);
[model, idx_name, model_info]= acados_model_func(param);

nx = length(model.x);           % state size
nu = length(model.u);           % input size

% OCP formulation object
ocp = AcadosOcp();
ocp.model = model;

% Parameters must be supplied as a vector p_values
run(fullfile(gen_dir, "model_parameters.m"))
p_values= acados_params(parameter_names, param);
ocp.parameter_values = p_values;

% cost in nonlinear least squares form
% x: tow_fa, Tgen, theta, tow_fa_d, phi_rot_d
W_x = diag([0, 1e-6, 1e5, 1e2, 1e5]);
% u: dTgen, dtheta
W_u = diag([1e-6 1e-2]);

% initial cost term
ocp.cost.cost_type_0 = 'NONLINEAR_LS';
ocp.cost.W_0 = W_u;
ocp.cost.yref_0 = zeros(nu, 1);
ocp.model.cost_y_expr_0 = model.u;

% path cost term
ocp.cost.cost_type = 'NONLINEAR_LS';
ocp.cost.W = blkdiag(W_x, W_u);
ocp.cost.yref = zeros(nx+nu, 1);
ocp.model.cost_y_expr = vertcat(model.x, model.u);

% terminal cost term
ocp.cost.cost_type_e = 'NONLINEAR_LS';
ocp.model.cost_y_expr_e = model.x;
ocp.cost.yref_e = zeros(nx, 1);
ocp.cost.W_e = W_x;

% Constraints
% bound on u
acados_inf= 1e8;
ocp.constraints.lbu = [-param.max_trq_rate -param.max_pit_rate];
ocp.constraints.ubu = [ param.max_trq_rate  param.max_pit_rate];
ocp.constraints.idxbu = [0 1];

% bound on x
ocp.constraints.lbx = [0 -pi/4];
ocp.constraints.ubx = [param.max_trq 0];
ocp.constraints.idxbx = [1 2];

% initial state
ocp.constraints.x0 = x0;

% Solver options
ocp.solver_options.N_horizon = N;
ocp.solver_options.tf = T;
ocp.solver_options.nlp_solver_type = 'SQP'; % possible values: SQP, SQP_RTI
ocp.solver_options.integrator_type = 'IRK';
ocp.solver_options.sim_method_num_steps= 1;
ocp.solver_options.sim_method_num_stages= 1;
ocp.solver_options.qp_solver = 'PARTIAL_CONDENSING_HPIPM';
% possible values: FULL_CONDENSING_HPIPM, PARTIAL_CONDENSING_HPIPM, FULL_CONDENSING_QPOASES, PARTIAL_CONDENSING_OSQP
ocp.solver_options.hessian_approx = 'GAUSS_NEWTON'; % possible values: EXACT, GAUSS_NEWTON
ocp.solver_options.regularize_method = 'NO_REGULARIZE';
% possible values: NO_REGULARIZE, PROJECT, PROOJECT_REDUC_HESS, MIRROR, CONVEXIFY
ocp.solver_options.nlp_solver_max_iter = 200; % This value cann not be exceeded when later setting ocp_solver.set('nlp_solver_max_iter', 10)

% Create solver
ocp_solver = AcadosOcpSolver(ocp);

%% Solve OCP
clc
cd(model_dir)
nlp_solver_max_iter = 1;

% simulate for different wind speeds
VW = 5:2:19;
simX = cell(length(VW), 1);
simU = cell(length(VW), 1);
status = nan(length(VW), 1);

om_rot_ref = nan(length(VW), 1);
P_ref = nan(length(VW), 1);
Tgen_ref = nan(length(VW), 1);
theta_ref = nan(length(VW), 1);

for i = 1:length(VW)
    param.vwind = VW(i);
    % Calculate tracking references for current wind speed
    [om_rot_ref(i), Tgen_ref(i), theta_ref(i), P_ref(i)] = calc_tracking_references(VW(i), param);

    % set initial state not too far from references
    x0 = [0.15; 0.8*Tgen_ref(i); -15/180*pi; 0; 0.8*om_rot_ref(i)];

    % reset solver and prepare with parameters and initial conditions
    ocp_solver.reset();

    ocp_solver.set('qp_print_level', 0) % console output only
    ocp_solver.set('nlp_solver_max_iter', nlp_solver_max_iter)
    
    ocp_solver.set('constr_x0', x0)

    % cost in nonlinear least squares form
    % x: tow_fa, Tgen, theta, tow_fa_d, phi_rot_d
    W_x = diag([0, 1e-6, 1e-1, 1e3, 1e5]);
    % u: dTgen, dtheta
    W_u = diag([1e-6 1e-2]);
    yref = zeros(nx+nu, 1);
    yref(idx_name.idx.Tgen)= Tgen_ref(i);
    yref(idx_name.idx.phi_rot_d)= om_rot_ref(i);

    % values have to be set in loop, intervalls don't seem to work
    ocp_solver.set('cost_W', W_u, 0)
    for k = 1:(N-1)
        ocp_solver.set('cost_W', blkdiag(W_x, W_u), k)
        ocp_solver.set('cost_y_ref', yref, k);
    end
    ocp_solver.set('cost_W', W_x, N)
    ocp_solver.set('cost_y_ref_e', yref(1:nx), N);

    x_traj_init = repmat(x0, 1, N+1);
    u_traj_init = zeros(nu, N);
    
    ocp_solver.set('init_x', x_traj_init);
    ocp_solver.set('init_u', u_traj_init);
    ocp_solver.set('init_pi', zeros(nx, N)) % multipliers for dynamics equality constraints
    
    run(fullfile(gen_dir, "model_parameters.m"))
    ap= acados_params(parameter_names, param);
    ocp_solver.set('p', ap)
    
    % % move blocking
    % for j= 100:149
    %     ocp_solver.set('constr_ubu', [0 0], j)
    %     ocp_solver.set('constr_lbu', [0 0], j)
    % end

    % solve
    tic
    ocp_solver.solve();
    toc
    
    ocp_solver.print
    status(i) = ocp_solver.get('status');
    simU{i} = ocp_solver.get('u');
    simX{i} = ocp_solver.get('x');
end

% plot results
t= linspace(0, T, N+1);
clf
for i = 1:length(VW)
    subplot(6, 1, 1)
    hold on
    plot(t(1:end), -simX{i}(idx_name.idx.theta, :)/pi*180)
    title('pitch')
    grid on
    
    subplot(6, 1, 2)
    hold on
    plot(t, simX{i}(idx_name.idx.phi_rot_d, :)/pi*30*param.GBRatio)
    if i==length(VW)
        plot(t, t*0+param.rpm_max, 'k', 'LineWidth', 2)
        legend('set point', 'gen speed')
    end
    title('speed')
    grid on
    
    subplot(6, 1, 3)
    hold on
    TorqueMax= param.power_max/(param.rpm_max/30*pi);
    plot(t(1:end), simX{i}(idx_name.idx.Tgen, :)/1e3)
    if i==length(VW)
        plot(t(1:end), t*0+TorqueMax/1e3, 'k', 'LineWidth', 2)
        legend('limit', 'gen trq')
    end
    title('torque')
    grid on
    
    subplot(6, 1, 4)
    hold on
    plot(t, simX{i}(idx_name.idx.tow_fa, :))
    title('tower')
    grid on
    
    subplot(6, 1, 5)
    hold on
    plot(t, simX{i}(idx_name.idx.tow_fa_d, :))
    title('tower rate')
    grid on
    
    subplot(6, 1, 6)
    hold on
    plot(t(1:end), simX{i}(idx_name.idx.Tgen, :)*param.GBRatio.*simX{i}(idx_name.idx.phi_rot_d, :)/1e3)
    title('power')
    grid on
end

legend(sprintfc('v=%d', VW), 'Location','southoutside', 'Orientation','horizontal')