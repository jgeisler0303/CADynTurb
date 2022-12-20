function varargout= turbine_T1B1i_aero_est_state_out(varargin)

model_indices

if length(varargin)==2
    d_in= varargin{1};
    nt= length(d_in.Time);

    param= varargin{2};

    q= zeros(nx, nt);
    q(tow_fa_idx, :)= d_in.Q_TFA1.Data;
    q(bld1_flp_idx, :)= d_in.Q_B1F1.Data;
    q(bld2_flp_idx, :)= d_in.Q_B2F1.Data;
    q(bld3_flp_idx, :)= d_in.Q_B3F1.Data;
    q(phi_rot_idx, :)= unwrap(d_in.LSSTipPxa.Data/180*pi);
    q(vwind_idx, :)= d_in.RtVAvgxh.Data;
    q(h_shear_idx, :)= d_in.RtHSAvg.Data;
    q(v_shear_idx, :)= d_in.RtVSAvg.Data;

    q(tow_fa_d_idx, :)= d_in.QD_TFA1.Data;      % 8
    q(bld1_flp_d_idx, :)= d_in.QD_B1F1.Data;      % 10
    q(bld2_flp_d_idx, :)= d_in.QD_B2F1.Data;      % 10
    q(bld3_flp_d_idx, :)= d_in.QD_B3F1.Data;      % 10
    q(phi_rot_idx, :)= d_in.LSSTipVxa.Data/30*pi; %12
    q(vwind_d_idx, :)= 0;
    q(h_shear_idx, :)= 0;
    q(v_shear_idx, :)= 0;

    y= zeros(ny, nt);
    y(1, :)= d_in.YawBrTAxp.Data;
    y(2, :)= d_in.LSSTipVxa.Data/30*pi;
    y(3, :)= d_in.RootMxb1.Data*1000;
    y(4, :)= d_in.RootMyb1.Data*1000;
    y(5, :)= d_in.RootMxb2.Data*1000;
    y(6, :)= d_in.RootMyb2.Data*1000;
    y(7, :)= d_in.RootMxb3.Data*1000;
    y(8, :)= d_in.RootMyb3.Data*1000;

    varargout{1}= q;
    varargout{2}= y;
else
    t= varargin{1};
    q= varargin{2};
    dq= varargin{3};
    ddq= varargin{4};
    u= varargin{5};
    y= varargin{6};
    param= varargin{7};

    d_out= tscollection(t);
    d_out= addts(d_out, 'Q_B1F1', 'm', q(bld1_flp_idx, :));
    d_out= addts(d_out, 'Q_B2F1', 'm', q(bld2_flp_idx, :));
    d_out= addts(d_out, 'Q_B3F1', 'm', q(bld3_flp_idx, :));
    d_out= addts(d_out, 'QD_B1F1', 'm/s', dq(bld1_flp_idx, :));
    d_out= addts(d_out, 'QD_B2F1', 'm/s', dq(bld2_flp_idx, :));
    d_out= addts(d_out, 'QD_B3F1', 'm/s', dq(bld3_flp_idx, :));
    d_out= addts(d_out, 'PtchPMzc1', 'deg', -u(in_theta1_idx, :)/pi*180);
    d_out= addts(d_out, 'PtchPMzc2', 'deg', -u(in_theta2_idx, :)/pi*180);
    d_out= addts(d_out, 'PtchPMzc3', 'deg', -u(in_theta3_idx, :)/pi*180);
    d_out= addts(d_out, 'LSSTipPxa', 'deg', mod(q(phi_rot_idx, :), 2*pi)*180.0/pi);
    d_out= addts(d_out, 'Q_GeAz', 'rad', mod(q(phi_rot_idx, :)+3/2*pi, 2*pi));
    d_out= addts(d_out, 'LSSTipVxa', 'rpm', dq(phi_rot_idx, :)*30.0/pi);
    d_out= addts(d_out, 'LSSTipAxa', 'deg/s^2', ddq(phi_rot_idx, :)*180.0/pi);
    d_out= addts(d_out, 'YawBrTDxp', 'm', q(tow_fa_idx, :));
    d_out= addts(d_out, 'YawBrTVxp', 'm/s', dq(tow_fa_idx, :));
    d_out= addts(d_out, 'Q_TFA1', 'm', q(tow_fa_idx, :));
    d_out= addts(d_out, 'QD_TFA1', 'm/s', dq(tow_fa_idx, :));
    d_out= addts(d_out, 'YawBrTAxp', 'm/s^2', ddq(tow_fa_idx, :));
    d_out= addts(d_out, 'HSShftTq', 'kNm', u(in_Tgen_idx, :)/1000.0);
    d_out= addts(d_out, 'RtVAvgxh', 'm/s', q(vwind_idx, :));
    d_out= addts(d_out, 'RtHSAvg', 'm/s', q(h_shear_idx, :));
    d_out= addts(d_out, 'RtVSAvg', 'm/s', q(v_shear_idx, :));
    d_out= addts(d_out, 'BlPitchC1', 'deg', -u(in_theta1_idx, :)*180.0/pi);
    d_out= addts(d_out, 'BlPitchC2', 'deg', -u(in_theta2_idx, :)*180.0/pi);
    d_out= addts(d_out, 'BlPitchC3', 'deg', -u(in_theta3_idx, :)*180.0/pi);
    d_out= addts(d_out, 'GenTq', 'kNm', u(in_Tgen_idx, :)/1000.0);
    d_out= addts(d_out, 'RootMxb1', 'kNm', y(3, :)/1000);
    d_out= addts(d_out, 'RootMyb1', 'kNm', y(4, :)/1000);
    d_out= addts(d_out, 'RootMxb2', 'kNm', y(5, :)/1000);
    d_out= addts(d_out, 'RootMyb2', 'kNm', y(6, :)/1000);
    d_out= addts(d_out, 'RootMxb3', 'kNm', y(7, :)/1000);
    d_out= addts(d_out, 'RootMyb3', 'kNm', y(8, :)/1000);
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
