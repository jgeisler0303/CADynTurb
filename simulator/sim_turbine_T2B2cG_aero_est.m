function [d_out, cpu_time, int_err, n_steps, n_backsteps, n_sub_steps]= sim_turbine_T2B2cG_aero_est(d_in, param, step_predict, do_est, Q, R)
if ~exist('step_predict', 'var') || isempty(step_predict)
    step_predict= 0;
end

if ~exist('do_est', 'var')
    do_est= 0;
end

if ~exist('Q', 'var')
    Q= [];
end

if ~exist('R', 'var')
    R= [];
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
if step_predict
    u(dvwind_idx, :)= 0;
else
    u(dvwind_idx, :)= wind_adjust*gradient(d_in.RtVAvgxh.Data, d_in.Time);
end
u(Tgen_idx, :)= d_in.GenTq.Data*1000;
u(theta_idx, :)= -d_in.BlPitchC.Data/180*pi;

if step_predict
    x_ref= zeros(14, nt);
    x_ref(tow_fa_idx, :)= d_in.Q_TFA1.Data;
    x_ref(tow_ss_idx, :)= -d_in.Q_TSS1.Data;
    x_ref(bld_flp_idx, :)= d_in.Q_BF1.Data;
    x_ref(bld_edg_idx, :)= d_in.Q_BE1.Data;
    x_ref(phi_rot_idx, :)= unwrap(d_in.LSSTipPxa.Data/180*pi);
    % Q_GeAz is on the low speed side
    x_ref(Dphi_gen_idx, :)= -(d_in.Q_DrTr.Data - d_in.YawBrTDyp.Data*param.TwTrans2Roll)*param.GBRatio;
    x_ref(vwind_idx, :)= d_in.RtVAvgxh.Data;

    x_ref(tow_fa_idx+7, :)= d_in.QD_TFA1.Data;      % 8
    x_ref(tow_ss_idx+7, :)= -d_in.QD_TSS1.Data;     % 9
    x_ref(bld_flp_idx+7, :)= d_in.QD_BF1.Data;      % 10
    x_ref(bld_edg_idx+7, :)= d_in.QD_BE1.Data;      % 11
    x_ref(phi_rot_idx+7, :)= d_in.LSSTipVxa.Data/30*pi; %12
    x_ref(Dphi_gen_idx+7, :)= -(d_in.QD_DrTr.Data + d_in.QD_TSS1.Data*param.TwTrans2Roll)*param.GBRatio; %13
    x_ref(vwind_idx+7, :)= 0;
end    


y_meas= zeros(5, nt);
y_pred= zeros(5, nt);
y_meas(1, :)= d_in.YawBrTAxp.Data;
y_meas(2, :)= d_in.YawBrTAyp.Data;
y_meas(3, :)= d_in.HSShftV.Data/30*pi;
y_meas(4, :)= 0; % not used
y_meas(5, :)= 0; % not used

cpu_time= zeros(1, nt);
int_err= zeros(1, nt);
n_steps= zeros(1, nt);
n_backsteps= zeros(1, nt);
n_sub_steps= zeros(1, nt);

Sigma_est= [];

% nt= 1000;
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
    y_pred(1, i)= (dx(1, i)-dx(1, i-1))/dt;
    y_pred(2, i)= (dx(2, i)-dx(2, i-1))/dt;

    if ~res
        error('Integrator error');
    end

    if do_est
        [x(:, i), dx(:, i), Sigma_est]= est6DOF(x(:, i), dx(:, i), y_pred(:, i), y_meas(:, i), Sigma_est, AB, CD, Q, R, t(i));
    end
end
y_pred(:, 1)= y_pred(:, 2);

if step_predict
    d_out.x= x_ref;
    d_out.x_pred= [x; dx];
    d_out.y= y_meas;
    d_out.y_pred= y_pred;    
else
    d_out= tscollection(t);
    d_out= addts(d_out, 'Q_BF1', 'm', x(bld_flp_idx, :));
    d_out= addts(d_out, 'Q_BE1', 'm', x(bld_edg_idx, :));
    d_out= addts(d_out, 'QD_BF1', 'm/s', dx(bld_flp_idx, :));
    d_out= addts(d_out, 'QD_BE1', 'm/s', dx(bld_edg_idx, :));
    d_out= addts(d_out, 'PtchPMzc', 'deg', -u(theta_idx, :)/pi*180);
    d_out= addts(d_out, 'LSSTipPxa', 'deg', mod(x(phi_rot_idx, :), 2*pi)*180.0/pi);
    d_out= addts(d_out, 'Q_GeAz', 'rad', mod(x(phi_rot_idx, :) + x(Dphi_gen_idx, :)/param.GBRatio+3/2*pi, 2*pi));
    d_out= addts(d_out, 'Q_DrTr', 'rad', -x(Dphi_gen_idx, :)/param.GBRatio + x(tow_ss_idx, :)*param.TwTrans2Roll);
    d_out= addts(d_out, 'QD_DrTr', 'rad', -dx(Dphi_gen_idx, :)/param.GBRatio + dx(tow_ss_idx, :)*param.TwTrans2Roll);
    d_out= addts(d_out, 'LSSTipVxa', 'rpm', dx(phi_rot_idx, :)*30.0/pi);
    d_out= addts(d_out, 'LSSTipAxa', 'deg/s^2', ddx(phi_rot_idx, :)*180.0/pi);
    d_out= addts(d_out, 'HSShftV', 'rpm', (dx(phi_rot_idx, :)*param.GBRatio + dx(Dphi_gen_idx, :))*30.0/pi);
    d_out= addts(d_out, 'HSShftA', 'deg/s^2', (ddx(phi_rot_idx, :)*param.GBRatio + ddx(Dphi_gen_idx, :))*180.0/pi);
    d_out= addts(d_out, 'YawBrTDxp', 'm', x(tow_fa_idx, :));
    d_out= addts(d_out, 'YawBrTDyp', 'm', x(tow_ss_idx, :));
    d_out= addts(d_out, 'YawBrTVyp', 'm/s', dx(tow_fa_idx, :));
    d_out= addts(d_out, 'YawBrTVxp', 'm/s', dx(tow_ss_idx, :));
    d_out= addts(d_out, 'Q_TFA1', 'm', x(tow_fa_idx, :));
    d_out= addts(d_out, 'Q_TSS1', 'm', -x(tow_ss_idx, :));
    d_out= addts(d_out, 'QD_TFA1', 'm/s', dx(tow_fa_idx, :));
    d_out= addts(d_out, 'QD_TSS1', 'm/s', -dx(tow_ss_idx, :));
    d_out= addts(d_out, 'YawBrTAxp', 'm/s^2', ddx(tow_fa_idx, :));
    d_out= addts(d_out, 'YawBrTAyp', 'm/s^2', ddx(tow_ss_idx, :));
    % d_out= addts(d_out, 'RootFxc', 'kN', &system.Fthrust, 1.0/3000.0);
    % d_out= addts(d_out, 'RootMxc', 'kNm', &system.Trot, 1.0/3000.0);
    % d_out= addts(d_out, 'LSShftFxa', 'kN', &system.Fthrust, 1.0/1000.0);
    % d_out= addts(d_out, 'LSShftMxa', 'kNm', &system.Trot, 1.0/1000.0);
    % d_out= addts(d_out, 'RotPwr', 'kW', system.Trot*system.states.phi_rot_d/1000.0);
    d_out= addts(d_out, 'HSShftTq', 'kNm', u(Tgen_idx, :)/1000.0);
    % d_out= addts(d_out, 'HSShftPwr', 'kW', system.inputs.Tgen*system.states.phi_gen_d/1000.0);
    d_out= addts(d_out, 'RtVAvgxh', 'm/s', x(vwind_idx, :));
    % d_out= addts(d_out, 'RtTSR', '-', &system.lam);
    % d_out= addts(d_out, 'RtAeroCq', '-', &system.cm);
    % d_out= addts(d_out, 'RtAeroCt', '-', &system.ct);
    % d_out= addts(d_out, 'RotCf', '-', &system.cflp);
    % d_out= addts(d_out, 'RotCe', '-', &system.cedg);
    d_out= addts(d_out, 'BlPitchC', 'deg', -u(theta_idx, :)*180.0/pi);
    d_out= addts(d_out, 'GenTq', 'kNm', u(Tgen_idx, :)/1000.0);
    % d_out= addts(d_out, 'RootMxb', '-', &system.modalFlapForce);
    % d_out= addts(d_out, 'RootMyb', '-', &system.modalEdgeForce);
end

function d= addts(d, name, unit, v)
ts= timeseries(name);
ts.Time= d.Time;
ts.Data= v';
ts.DataInfo.Units= unit;
ts.TimeInfo.Units= 's';
d= d.addts(ts);
