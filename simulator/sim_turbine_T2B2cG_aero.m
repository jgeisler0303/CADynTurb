function [d_out, cpu_time, int_err, n_steps, n_backsteps, n_sub_steps]= sim_turbine_T2B2cG_aero(d_in, param, step_by_step)
if ~exist('step_by_step', 'var')
    step_by_step= 0;
end

% TODO generate this automatically
tow_fa_idx= 1;
tow_ss_idx= 2;
bld_flp_idx= 3;
bld_edg_idx= 4;
phi_rot_idx= 5;
phi_gen_idx= 6;

vwind_idx= 1;
Tgen_idx= 2;
theta_idx= 3;

wind_adjust= 1;
% standard
% opts= struct('StepTol', 1e-8, 'AbsTol', 1e-6, 'RelTol', 1e-6, 'hminmin', 1E-8, 'jac_recalc_step', 4, 'max_steps', 10);
% one step
opts= struct('StepTol', 1e6, 'AbsTol', 1e6, 'RelTol', 1e6, 'hminmin', 1E-8, 'jac_recalc_step', 10, 'max_steps', 1);

u(vwind_idx)= wind_adjust*d_in.RtVAvgxh.Data(1);
u(Tgen_idx)= 10000;
u(theta_idx)= 0;

x= zeros(6, 1);
dx= zeros(6, 1);
x(phi_gen_idx)= u(Tgen_idx)*param.GBRatio/param.DTTorSpr;
dx(phi_gen_idx)= 1000.0/30.0*pi;
x(phi_rot_idx)= 0.0;
dx(phi_rot_idx)= dx(phi_gen_idx)/param.GBRatio;

opts_init= opts;
opts_init.doflocked= zeros(6, 1);
opts_init.doflocked(5)= 1;
opts_init.doflocked(6)= 1;

[x0, dx0, ddx0, ~, ~, ~, res]= turbine_T2B2cG_aero_mex(x, dx, u, param, 0, opts_init);
if ~res
    error('Static equilibrium could not be found');
end

t= d_in.Time;
nt= length(t);

x= zeros(length(x0), nt);
dx= zeros(length(dx0), nt);
ddx= zeros(length(ddx0), nt);
y= zeros(5, nt);

x(:, 1)= x0;
dx(:, 1)= dx0;
ddx(:, 1)= ddx0;

u= zeros(3, nt);
u(vwind_idx, :)= wind_adjust*d_in.RtVAvgxh.Data;
u(Tgen_idx, :)= d_in.GenTq.Data*1000;
u(theta_idx, :)= -d_in.BlPitchC.Data/180*pi;

cpu_time= zeros(1, nt);
int_err= zeros(1, nt);
n_steps= zeros(1, nt);
n_backsteps= zeros(1, nt);
n_sub_steps= zeros(1, nt);

for i= 2:nt
    if step_by_step
        x_in(tow_fa_idx)= d_in.YawBrTDxp.Data(i-1);
        x_in(tow_ss_idx)= d_in.YawBrTDyp.Data(i-1);
        x_in(bld_flp_idx)= d_in.Q_BF1.Data(i-1);
        x_in(bld_edg_idx)= d_in.Q_BE1.Data(i-1);
        x_in(phi_rot_idx)= d_in.LSSTipPxa.Data(i-1)/180*pi;
        x_in(phi_gen_idx)= d_in.Q_GeAz.Data(i-1);

        dx_in(tow_fa_idx)= d_in.YawBrTVxp.Data(i-1);
        dx_in(tow_ss_idx)= d_in.YawBrTVyp.Data(i-1);
        dx_in(bld_flp_idx)= d_in.QD_BF1.Data(i-1);
        dx_in(bld_edg_idx)= d_in.QD_BE1.Data(i-1);
        dx_in(phi_rot_idx)= d_in.LSSTipVxa.Data(i-1)/30*pi;
        dx_in(phi_gen_idx)= d_in.HSShftV.Data(i-1)/30*pi;
    else
        x_in= x(:, i-1);
        dx_in= dx(:, i-1);
    end
    [x(:, i), dx(:, i), ddx(:, i), y(:, i), AB, CD, res, cpu_time(i), int_err(i), n_steps(i), n_backsteps(i), n_sub_steps(i)]= ...
        turbine_T2B2cG_aero_mex(x_in, dx_in, u(:, i-1), param, t(i)-t(i-1), opts);
    
    if ~res
        error('Integrator error');
    end
end
% y(:, 1)= y(:, 2);

d_out= tscollection(t);
d_out= addts(d_out, 'Q_BF1', 'm', x(bld_flp_idx, :));
d_out= addts(d_out, 'Q_BE1', 'm', x(bld_edg_idx, :));
d_out= addts(d_out, 'QD_BF1', 'm/s', dx(bld_flp_idx, :));
d_out= addts(d_out, 'QD_BE1', 'm/s', dx(bld_edg_idx, :));
d_out= addts(d_out, 'PtchPMzc', 'deg', -u(theta_idx, :)/pi*180);
d_out= addts(d_out, 'LSSTipPxa', 'deg', mod(x(phi_rot_idx, :), 2*pi)*180.0/pi);
d_out= addts(d_out, 'Q_GeAz', 'rad', mod(x(phi_gen_idx, :)/param.GBRatio+3/2*pi, 2*pi));
d_out= addts(d_out, 'LSSTipVxa', 'rpm', dx(phi_rot_idx, :)*30.0/pi);
d_out= addts(d_out, 'Q_DrTr', 'rad', x(phi_rot_idx, :) - x(phi_gen_idx, :)/param.GBRatio + x(tow_ss_idx, :)*param.TwTrans2Roll);
d_out= addts(d_out, 'QD_DrTr', 'rad/s', dx(phi_rot_idx, :) - dx(phi_gen_idx, :)/param.GBRatio + dx(tow_ss_idx, :)*param.TwTrans2Roll);
d_out= addts(d_out, 'LSSTipAxa', 'deg/s^2', ddx(phi_rot_idx, :)*180.0/pi);
d_out= addts(d_out, 'HSShftV', 'rpm', dx(phi_gen_idx, :)*30.0/pi);
d_out= addts(d_out, 'HSShftA', 'deg/s^2', ddx(phi_gen_idx, :)*180.0/pi);
d_out= addts(d_out, 'YawBrTDxp', 'm', x(tow_fa_idx, :));
d_out= addts(d_out, 'YawBrTDyp', 'm', x(tow_ss_idx, :));
d_out= addts(d_out, 'YawBrTVyp', 'm/s', dx(tow_fa_idx, :));
d_out= addts(d_out, 'YawBrTVxp', 'm/s', dx(tow_ss_idx, :));
d_out= addts(d_out, 'YawBrTAxp', 'm/s^2', ddx(tow_fa_idx, :));
d_out= addts(d_out, 'YawBrTAyp', 'm/s^2', ddx(tow_ss_idx, :));
d_out= addts(d_out, 'Q_TFA1', 'm', x(tow_fa_idx, :));
d_out= addts(d_out, 'Q_TSS1', 'm', -x(tow_ss_idx, :));
d_out= addts(d_out, 'QD_TFA1', 'm/s', dx(tow_fa_idx, :));
d_out= addts(d_out, 'QD_TSS1', 'm/s', -dx(tow_ss_idx, :));
% d_out= addts(d_out, 'RootFxc', 'kN', &system.Fthrust, 1.0/3000.0);
% d_out= addts(d_out, 'RootMxc', 'kNm', &system.Trot, 1.0/3000.0);
% d_out= addts(d_out, 'LSShftFxa', 'kN', &system.Fthrust, 1.0/1000.0);
% d_out= addts(d_out, 'LSShftMxa', 'kNm', &system.Trot, 1.0/1000.0);
% d_out= addts(d_out, 'RotPwr', 'kW', system.Trot*system.states.phi_rot_d/1000.0);
d_out= addts(d_out, 'HSShftTq', 'kNm', u(Tgen_idx, :)/1000.0);
% d_out= addts(d_out, 'HSShftPwr', 'kW', system.inputs.Tgen*system.states.phi_gen_d/1000.0);
d_out= addts(d_out, 'RtVAvgxh', 'm/s', u(vwind_idx, :));
% d_out= addts(d_out, 'RtTSR', '-', &system.lam);
% d_out= addts(d_out, 'RtAeroCq', '-', &system.cm);
% d_out= addts(d_out, 'RtAeroCt', '-', &system.ct);
% d_out= addts(d_out, 'RotCf', '-', &system.cflp);
% d_out= addts(d_out, 'RotCe', '-', &system.cedg);
d_out= addts(d_out, 'BlPitchC', 'deg', -u(theta_idx, :)*180.0/pi);
d_out= addts(d_out, 'GenTq', 'kNm', u(Tgen_idx, :)/1000.0);
% d_out= addts(d_out, 'RootMxb', '-', &system.modalFlapForce);
% d_out= addts(d_out, 'RootMyb', '-', &system.modalEdgeForce);

function d= addts(d, name, unit, v)
ts= timeseries(name);
ts.Time= d.Time;
ts.Data= v';
ts.DataInfo.Units= unit;
ts.TimeInfo.Units= 's';
d= d.addts(ts);
