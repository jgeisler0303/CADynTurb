function [d_out, cpu_time, int_err, n_steps, n_backsteps, n_sub_steps, Q, R]= sim_turbine_T2B1i1cG_aero_est(d_in, param, step_predict, do_est, Q, R, N, T_adapt, adjust_adapt)
if ~exist('step_predict', 'var') || isempty(step_predict)
    step_predict= 0;
end

if ~exist('do_est', 'var')
    do_est= 0;
end

if ~exist('N', 'var')
    N= [];
end
if ~exist('adjust_adapt', 'var')
    adjust_adapt= [];
end

model_indices

wind_adjust= 1;
% standard
% opts= struct('StepTol', 1e-8, 'AbsTol', 1e-6, 'RelTol', 1e-6, 'hminmin', 1E-8, 'jac_recalc_step', 4, 'max_steps', 10);
% one step
opts= struct('StepTol', 1e6, 'AbsTol', 1e6, 'RelTol', 1e6, 'hminmin', 1E-8, 'jac_recalc_step', 10, 'max_steps', 1);

t= d_in.Time;
dt= t(2)-t(1);
nt= length(t);

% tow_fa, tow_ss, bld1_flp, bld2_flp, bld3_flp, bld_edg, phi_rot, Dphi_gen, vwind, h_shear, v_shear, m_bld_mom
m_offset= [4, -725; 6, -743.4027; 8, -800.2436; 10, -823.5407; 11,  -758.6681; 12, -638.8656; 14, -342.6672; 18, 161; 19, 275; 20, 385.6; 21, 465; 22, 589];
if do_est
    q0= zeros(nq, 1);
    q0(vwind_idx)= 8;
    q0(m_bld_mom_idx)= 1e3*interp1(m_offset(:, 1), m_offset(:, 2), mean(d_in.RtVAvgxh.Data), "linear", "extrap");
    dq0= zeros(nq, 1);
    dq0(phi_rot_idx)= 1000/30*pi/param.GBRatio;
    ddq0= zeros(nq, 1);
else
    q0= [d_in.Q_TFA1.Data(1) d_in.Q_TSS1.Data(1) d_in.Q_B1F1.Data(1) d_in.Q_B2F1.Data(1) d_in.Q_B3F1.Data(1) d_in.Q_BE1.Data(1) 0 d_in.Q_DrTr.Data(1)*param.GBRatio d_in.RtVAvgxh.Data(1) d_in.RtHSAvg.Data(1) d_in.RtVSAvg.Data(1) 0];
    dq0= zeros(nq, 1);
    dq0(phi_rot_idx)= d_in.LSSTipVxa.Data(1)/30*pi;
    ddq0= zeros(nq, 1);
end
q= zeros(length(q0), nt);
dq= zeros(length(dq0), nt);
ddq= zeros(length(ddq0), nt);

q(:, 1)= q0;
dq(:, 1)= dq0;
ddq(:, 1)= ddq0;

u= zeros(nu, nt);
if step_predict || do_est
    u(in_dvwind_idx, :)= 0;
    u(in_dh_shear_idx, :)= 0;
    u(in_dv_shear_idx, :)= 0;
else
    u(in_dvwind_idx, :)= wind_adjust*gradient(d_in.RtVAvgxh.Data, d_in.Time);
    u(in_dh_shear_idx, :)= gradient(d_in.RtHSAvg.Data, d_in.Time);
    u(in_dv_shear_idx, :)= gradient(d_in.RtVSAvg.Data, d_in.Time);
end
if ~exist('T_adapt', 'var')
    alpha_adapt= [];
else
    alpha_adapt= exp(-dt/T_adapt);
end

u(in_Tgen_idx, :)= d_in.GenTq.Data*1000;
u(in_theta1_idx, :)= -d_in.BlPitchC1.Data/180*pi;
u(in_theta2_idx, :)= -d_in.BlPitchC2.Data/180*pi;
u(in_theta3_idx, :)= -d_in.BlPitchC3.Data/180*pi;

[x_ref, y_meas]= turbine_T2B1i1cG_aero_est_state_out(d_in, param);

cpu_time= zeros(1, nt);
int_err= zeros(1, nt);
n_steps= zeros(1, nt);
n_backsteps= zeros(1, nt);
n_sub_steps= zeros(1, nt);

y_pred= zeros(ny, nt);
Sigma_est= [];

tic
for i= 2:nt
    if step_predict
        x_in= x_ref(1:(nx/2), i-1);
        dx_in= x_ref(((nx/2)+1):end, i-1);
    else
        x_in= q(:, i-1);
        dx_in= dq(:, i-1);
    end
    [q(:, i), dq(:, i), ddq(:, i), y_pred(:, i), AB, CD, res, cpu_time(i), int_err(i), n_steps(i), n_backsteps(i), n_sub_steps(i)]= ...
        turbine_T2B1i1cG_aero_est_mex(x_in, dx_in, u(:, i-1), param, t(i)-t(i-1), opts);

    if ~res
        error('Integrator error');
    end

    if do_est
        [q(:, i), dq(:, i), Sigma_est, Q, R]= est_T2B1i1cG_aero_est(q(:, i), dq(:, i), u(:, i-1), y_pred(:, i), y_meas(:, i), param, Sigma_est, AB, CD, Q, R, N, t(i), alpha_adapt, adjust_adapt);
    end
end
toc
y_pred(:, 1)= y_pred(:, 2);

if step_predict
    d_out.x= x_ref;
    d_out.x_pred= [q; dq];
    d_out.y= y_meas;
    d_out.y_pred= y_pred;    
else
    d_out= turbine_T2B1i1cG_aero_est_state_out(t, q, dq, ddq, u, y_pred, param);
end