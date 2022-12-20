function varargout= turbine_T2B2cG_aero_est_state_out(varargin)

model_indices

if length(varargin)==2
    d_in= varargin{1};
    nt= length(d_in.Time);

    param= varargin{2};

    x= zeros(14, nt);
    x(tow_fa_idx, :)= d_in.Q_TFA1.Data;
    x(tow_ss_idx, :)= -d_in.Q_TSS1.Data;
    x(bld_flp_idx, :)= d_in.Q_BF1.Data;
    x(bld_edg_idx, :)= d_in.Q_BE1.Data;
    x(phi_rot_idx, :)= unwrap(d_in.LSSTipPxa.Data/180*pi);
    % Q_GeAz is on the low speed side
    x(Dphi_gen_idx, :)= -(d_in.Q_DrTr.Data - d_in.YawBrTDyp.Data*param.TwTrans2Roll)*param.GBRatio;
    x(vwind_idx, :)= d_in.RtVAvgxh.Data;

    x(tow_fa_idx+7, :)= d_in.QD_TFA1.Data;      % 8
    x(tow_ss_idx+7, :)= -d_in.QD_TSS1.Data;     % 9
    x(bld_flp_idx+7, :)= d_in.QD_BF1.Data;      % 10
    x(bld_edg_idx+7, :)= d_in.QD_BE1.Data;      % 11
    x(phi_rot_idx+7, :)= d_in.LSSTipVxa.Data/30*pi; %12
    x(Dphi_gen_idx+7, :)= -(d_in.QD_DrTr.Data + d_in.QD_TSS1.Data*param.TwTrans2Roll)*param.GBRatio; %13
    x(vwind_idx+7, :)= 0;

    y= zeros(3, nt);
    y(1, :)= d_in.YawBrTAxp.Data;
    y(2, :)= d_in.YawBrTAyp.Data;
    y(3, :)= d_in.HSShftV.Data/30*pi;


    varargout{1}= x;
    varargout{2}= y;
else
    t= varargin{1};
    x= varargin{2};
    dx= varargin{3};
    ddx= varargin{4};
    u= varargin{5};
    y= varargin{6};
    param= varargin{7};

    d_out= tscollection(t);
    d_out= addts(d_out, 'Q_BF1', 'm', x(bld_flp_idx, :));
    d_out= addts(d_out, 'Q_BE1', 'm', x(bld_edg_idx, :));
    d_out= addts(d_out, 'QD_BF1', 'm/s', dx(bld_flp_idx, :));
    d_out= addts(d_out, 'QD_BE1', 'm/s', dx(bld_edg_idx, :));
    d_out= addts(d_out, 'PtchPMzc', 'deg', -u(in_theta_idx, :)/pi*180);
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
    d_out= addts(d_out, 'YawBrTVxp', 'm/s', dx(tow_fa_idx, :));
    d_out= addts(d_out, 'YawBrTVyp', 'm/s', dx(tow_ss_idx, :));
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
    d_out= addts(d_out, 'HSShftTq', 'kNm', u(in_Tgen_idx, :)/1000.0);
    % d_out= addts(d_out, 'HSShftPwr', 'kW', system.inputs.Tgen*system.states.phi_gen_d/1000.0);
    d_out= addts(d_out, 'RtVAvgxh', 'm/s', x(vwind_idx, :));
    % d_out= addts(d_out, 'RtTSR', '-', &system.lam);
    % d_out= addts(d_out, 'RtAeroCq', '-', &system.cm);
    % d_out= addts(d_out, 'RtAeroCt', '-', &system.ct);
    % d_out= addts(d_out, 'RotCf', '-', &system.cflp);
    % d_out= addts(d_out, 'RotCe', '-', &system.cedg);
    d_out= addts(d_out, 'BlPitchC', 'deg', -u(in_theta_idx, :)*180.0/pi);
    d_out= addts(d_out, 'GenTq', 'kNm', u(in_Tgen_idx, :)/1000.0);
    % d_out= addts(d_out, 'RootMxb', '-', &system.modalFlapForce);
    % d_out= addts(d_out, 'RootMyb', '-', &system.modalEdgeForce);
    d_out= addts(d_out, 'y', '-', y);

    varargout{1}= d_out;
end

function d= addts(d, name, unit, v)
ts= timeseries(name);
ts.Time= d.Time;
ts.Data= v';
ts.DataInfo.Units= unit;
ts.TimeInfo.Units= 's';
d= d.addts(ts);
