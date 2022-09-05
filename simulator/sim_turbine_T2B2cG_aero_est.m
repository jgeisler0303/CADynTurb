function [d_out, cpu_time, int_err, n_steps, n_backsteps, n_sub_steps]= sim_turbine_T2B2cG_aero_est(d_in, param, step_predict, do_est, Q, R, N, T_adapt)
if ~exist('step_predict', 'var') || isempty(step_predict)
    step_predict= 0;
end

if ~exist('do_est', 'var')
    do_est= 0;
end

if ~exist('N', 'var')
    N= [];
end

% TODO generate this automatically
tow_fa_idx= 1;
tow_ss_idx= 2;
bld_flp_idx= 3;
bld_edg_idx= 4;
phi_rot_idx= 5;
Dphi_gen_idx= 6;
vwind_idx= 7;

dvwind_idx= 1;
Tgen_idx= 2;
theta_idx= 3;

wind_adjust= 1;
% standard
% opts= struct('StepTol', 1e-8, 'AbsTol', 1e-6, 'RelTol', 1e-6, 'hminmin', 1E-8, 'jac_recalc_step', 4, 'max_steps', 10);
% one step
opts= struct('StepTol', 1e6, 'AbsTol', 1e6, 'RelTol', 1e6, 'hminmin', 1E-8, 'jac_recalc_step', 10, 'max_steps', 1);

u(dvwind_idx)= 0;
u(Tgen_idx)= 10000;
u(theta_idx)= 0;

x= zeros(7, 1);
dx= zeros(7, 1);
x(phi_rot_idx)= 0.0;
dx(phi_rot_idx)= 1000.0/30.0*pi/param.GBRatio;
x(Dphi_gen_idx)= u(Tgen_idx)*param.GBRatio/param.DTTorSpr;
dx(Dphi_gen_idx)= 0;
x(vwind_idx)= d_in.RtVAvgxh.Data(1);

opts_init= opts;
opts_init.doflocked= zeros(6, 1);
opts_init.doflocked(Dphi_gen_idx)= 1;
opts_init.doflocked(phi_rot_idx)= 1;
opts_init.doflocked(vwind_idx)= 1;

[x0, dx0, ddx0, ~, ~, ~, res]= turbine_T2B2cG_aero_est_mex(x, dx, u, param, 0, opts_init);
if ~res
    error('Static equilibrium could not be found');
end

t= d_in.Time;
dt= t(2)-t(1);
nt= length(t);

x= zeros(length(x0), nt);
dx= zeros(length(dx0), nt);
ddx= zeros(length(ddx0), nt);

x(:, 1)= x0;
dx(:, 1)= dx0;
ddx(:, 1)= ddx0;

u= zeros(3, nt);
if step_predict || do_est
    u(dvwind_idx, :)= 0;
else
    u(dvwind_idx, :)= wind_adjust*gradient(d_in.RtVAvgxh.Data, d_in.Time);
end
if ~exist('T_adapt', 'var')
    alpha_adapt= [];
else
    alpha_adapt= exp(-dt/T_adapt);
end

u(Tgen_idx, :)= d_in.GenTq.Data*1000;
u(theta_idx, :)= -d_in.BlPitchC.Data/180*pi;

[x_ref, y_meas]= turbine_T2B2cG_aero_est_state_out(d_in, param);

cpu_time= zeros(1, nt);
int_err= zeros(1, nt);
n_steps= zeros(1, nt);
n_backsteps= zeros(1, nt);
n_sub_steps= zeros(1, nt);

y_pred= zeros(5, nt);
Sigma_est= [];

% nt= 1000;
tic
for i= 2:nt
    if step_predict
        x_in= x_ref(1:7, i-1);
        dx_in= x_ref(8:end, i-1);
    else
        x_in= x(:, i-1);
        dx_in= dx(:, i-1);
    end
    [x(:, i), dx(:, i), ddx(:, i), y_pred(:, i), AB, CD, res, cpu_time(i), int_err(i), n_steps(i), n_backsteps(i), n_sub_steps(i)]= ...
        turbine_T2B2cG_aero_est_mex(x_in, dx_in, u(:, i-1), param, t(i)-t(i-1), opts);

    if ~res
        error('Integrator error');
    end

    if do_est
        [x(:, i), dx(:, i), Sigma_est, Q, R]= est6DOF(x(:, i), dx(:, i), y_pred(:, i), y_meas(:, i), Sigma_est, AB, CD, Q, R, N, t(i), alpha_adapt);
    end
end
toc
y_pred(:, 1)= y_pred(:, 2);

if step_predict
    d_out.x= x_ref;
    d_out.x_pred= [x; dx];
    d_out.y= y_meas;
    d_out.y_pred= y_pred;    
else
    d_out= turbine_T2B2cG_aero_est_state_out(t, x, dx, ddx, u, y_pred, param);
end