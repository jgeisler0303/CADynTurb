function varargout= turbine_T2B1i1cG_aero_est_state_out(varargin)

model_indices

if length(varargin)==2
    d_in= varargin{1};
    nt= length(d_in.Time);

    param= varargin{2};

    x= zeros(nx, nt);
    x(tow_fa_idx, :)= d_in.Q_TFA1.Data;
    x(tow_ss_idx, :)= -d_in.Q_TSS1.Data;
    x(bld1_flp_idx, :)= d_in.Q_B1F1.Data;
    x(bld2_flp_idx, :)= d_in.Q_B2F1.Data;
    x(bld3_flp_idx, :)= d_in.Q_B3F1.Data;
    x(bld_edg_idx, :)= d_in.Q_BE1.Data;
    x(phi_rot_idx, :)= unwrap(d_in.LSSTipPxa.Data/180*pi);
    x(Dphi_gen_idx, :)= -(d_in.Q_DrTr.Data - d_in.YawBrTDyp.Data*param.TwTrans2Roll)*param.GBRatio;
    x(vwind_idx, :)= d_in.RtVAvgxh.Data;
    x(h_shear_idx, :)= d_in.RtHSAvg.Data;
    x(v_shear_idx, :)= d_in.RtVSAvg.Data;

    x(tow_fa_d_idx, :)= d_in.QD_TFA1.Data;
    x(tow_ss_d_idx, :)= -d_in.QD_TSS1.Data;
    x(bld1_flp_d_idx, :)= d_in.QD_B1F1.Data;
    x(bld2_flp_d_idx, :)= d_in.QD_B2F1.Data;
    x(bld3_flp_d_idx, :)= d_in.QD_B3F1.Data;
    x(bld_edg_d_idx, :)= d_in.QD_BE1.Data;
    x(phi_rot_idx, :)= d_in.LSSTipVxa.Data/30*pi; 
    x(Dphi_gen_d_idx, :)= -(d_in.QD_DrTr.Data + d_in.QD_TSS1.Data*param.TwTrans2Roll)*param.GBRatio;
    x(vwind_d_idx, :)= 0;
    x(h_shear_d_idx, :)= 0;
    x(v_shear_d_idx, :)= 0;

    y= zeros(ny, nt);
    y(out_tow_fa_acc_idx, :)= d_in.YawBrTAxp.Data;
    y(out_tow_ss_acc_idx, :)= d_in.YawBrTAyp.Data;
    y(out_gen_speed_idx, :)= d_in.HSShftV.Data/30*pi;
    y(out_bld1_edg_mom_idx, :)= d_in.RootMxb1.Data*1000;
    y(out_bld1_flp_mom_idx, :)= d_in.RootMyb1.Data*1000;
    y(out_bld2_edg_mom_idx, :)= d_in.RootMxb2.Data*1000;
    y(out_bld2_flp_mom_idx, :)= d_in.RootMyb2.Data*1000;
    y(out_bld3_edg_mom_idx, :)= d_in.RootMxb3.Data*1000;
    y(out_bld3_flp_mom_idx, :)= d_in.RootMyb3.Data*1000;

    varargout{1}= x;
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
    d_out= addts(d_out, 'Q_BE1', 'm', q(bld_edg_idx, :));
    d_out= addts(d_out, 'QD_BE1', 'm/s', dq(bld_edg_idx, :));
    d_out= addts(d_out, 'PtchPMzc1', 'deg', -u(in_theta1_idx, :)/pi*180);
    d_out= addts(d_out, 'PtchPMzc2', 'deg', -u(in_theta2_idx, :)/pi*180);
    d_out= addts(d_out, 'PtchPMzc3', 'deg', -u(in_theta3_idx, :)/pi*180);
    d_out= addts(d_out, 'LSSTipPxa', 'deg', mod(q(phi_rot_idx, :), 2*pi)*180.0/pi);
    d_out= addts(d_out, 'Q_GeAz', 'rad', mod(q(phi_rot_idx, :)+3/2*pi, 2*pi));
    d_out= addts(d_out, 'Q_DrTr', 'rad', -q(Dphi_gen_idx, :)/param.GBRatio + q(tow_ss_idx, :)*param.TwTrans2Roll);
    d_out= addts(d_out, 'QD_DrTr', 'rad', -dq(Dphi_gen_idx, :)/param.GBRatio + dq(tow_ss_idx, :)*param.TwTrans2Roll);
    d_out= addts(d_out, 'LSSTipVxa', 'rpm', dq(phi_rot_idx, :)*30.0/pi);
    d_out= addts(d_out, 'LSSTipAxa', 'deg/s^2', ddq(phi_rot_idx, :)*180.0/pi);
    d_out= addts(d_out, 'HSShftV', 'rpm', (dq(phi_rot_idx, :)*param.GBRatio + dq(Dphi_gen_idx, :))*30.0/pi);
    d_out= addts(d_out, 'HSShftA', 'deg/s^2', (ddq(phi_rot_idx, :)*param.GBRatio + ddq(Dphi_gen_idx, :))*180.0/pi);
    d_out= addts(d_out, 'YawBrTDxp', 'm', q(tow_fa_idx, :));
    d_out= addts(d_out, 'YawBrTVxp', 'm/s', dq(tow_fa_idx, :));
    d_out= addts(d_out, 'YawBrTDyp', 'm', q(tow_ss_idx, :));
    d_out= addts(d_out, 'YawBrTVyp', 'm/s', dq(tow_ss_idx, :));
    d_out= addts(d_out, 'Q_TFA1', 'm', q(tow_fa_idx, :));
    d_out= addts(d_out, 'QD_TFA1', 'm/s', dq(tow_fa_idx, :));
    d_out= addts(d_out, 'Q_TSS1', 'm', -q(tow_ss_idx, :));
    d_out= addts(d_out, 'QD_TSS1', 'm/s', -dq(tow_ss_idx, :));
    d_out= addts(d_out, 'YawBrTAxp', 'm/s^2', ddq(tow_fa_idx, :));
    d_out= addts(d_out, 'YawBrTAyp', 'm/s^2', ddq(tow_ss_idx, :));
    d_out= addts(d_out, 'HSShftTq', 'kNm', u(in_Tgen_idx, :)/1000.0);
    d_out= addts(d_out, 'RtVAvgxh', 'm/s', q(vwind_idx, :));
    d_out= addts(d_out, 'RtHSAvg', 'm/s', q(h_shear_idx, :));
    d_out= addts(d_out, 'RtVSAvg', 'm/s', q(v_shear_idx, :));
    d_out= addts(d_out, 'BlPitchC1', 'deg', -u(in_theta1_idx, :)*180.0/pi);
    d_out= addts(d_out, 'BlPitchC2', 'deg', -u(in_theta2_idx, :)*180.0/pi);
    d_out= addts(d_out, 'BlPitchC3', 'deg', -u(in_theta3_idx, :)*180.0/pi);
    d_out= addts(d_out, 'GenTq', 'kNm', u(in_Tgen_idx, :)/1000.0);
    d_out= addts(d_out, 'RootMxb1', 'kNm', y(out_bld1_edg_mom_idx, :)/1000);
    d_out= addts(d_out, 'RootMyb1', 'kNm', y(out_bld1_flp_mom_idx, :)/1000);
    d_out= addts(d_out, 'RootMxb2', 'kNm', y(out_bld2_edg_mom_idx, :)/1000);
    d_out= addts(d_out, 'RootMyb2', 'kNm', y(out_bld2_flp_mom_idx, :)/1000);
    d_out= addts(d_out, 'RootMxb3', 'kNm', y(out_bld3_edg_mom_idx, :)/1000);
    d_out= addts(d_out, 'RootMyb3', 'kNm', y(out_bld3_flp_mom_idx, :)/1000);
    d_out= addts(d_out, 'y', '-', y);
    d_out= addts(d_out, 'q', '-', q);
    d_out= addts(d_out, 'dq', '-', dq);
    d_out= addts(d_out, 'ddq', '-', ddq);

    varargout{1}= d_out;
end

function d= addts(d, name, unit, v)
ts= timeseries(name);
ts.Time= d.Time;
ts.Data= v';
ts.DataInfo.Units= unit;
ts.TimeInfo.Units= 's';
d= d.addts(ts);
