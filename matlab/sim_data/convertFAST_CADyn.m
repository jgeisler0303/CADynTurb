function varargout= convertFAST_CADyn(varargin)

model_indices

if length(varargin)==2 || length(varargin)==3
    if length(varargin)==3
        est_or_predict= varargin{3};
    else
        est_or_predict= 0;
    end

    d_in= varargin{1};
    nt= length(d_in.Time);

    param= varargin{2};

    x= zeros(nx, nt);
    try x(tow_fa_idx, :)= d_in.Q_TFA1.Data; catch, end
    try x(tow_ss_idx, :)= -d_in.Q_TSS1.Data; catch, end
    try x(bld_flp_idx, :)= d_in.Q_BF1.Data; catch, end
    try x(bld_edg_idx, :)= d_in.Q_BE1.Data; catch, end
    try x(phi_rot_idx, :)= unwrap(d_in.LSSTipPxa.Data/180*pi); catch, end
    % Q_GeAz is on the low speed side
    try x(Dphi_gen_idx, :)= -d_in.Q_DrTr.Data*param.GBRatio; catch, end
    try x(phi_gen_idx, :)= unwrap((d_in.LSSTipPxa.Data-d_in.Q_DrTr.Data)*param.GBRatio);  catch, end
    try x(vwind_idx, :)= d_in.RtVAvgxh.Data; catch, end
    try x(bld1_flp_idx, :)= d_in.Q_B1F1.Data; catch, end
    try x(bld2_flp_idx, :)= d_in.Q_B2F1.Data; catch, end
    try x(bld3_flp_idx, :)= d_in.Q_B3F1.Data; catch, end
    try x(h_shear_idx, :)= d_in.RtHSAvg.Data; catch, end
    try x(v_shear_idx, :)= d_in.RtVSAvg.Data; catch, end

    try x(tow_fa_d_idx, :)= d_in.QD_TFA1.Data; catch, end
    try x(tow_ss_d_idx, :)= -d_in.QD_TSS1.Data; catch, end
    try x(bld_flp_d_idx, :)= d_in.QD_BF1.Data;  catch, end
    try x(bld_edg_d_idx, :)= d_in.QD_BE1.Data;  catch, end
    try x(phi_rot_d_idx, :)= d_in.LSSTipVxa.Data/30*pi; catch, end
    try x(Dphi_gen_d_idx, :)= -d_in.QD_DrTr.Data*param.GBRatio; catch, end
    try x(phi_gen_d_idx, :)= d_in.HSShftV.Data*pi/30; catch, end
    try x(vwind_d_idx, :)= 0; catch, end
    try x(bld1_flp_d_idx, :)= d_in.QD_B1F1.Data; catch, end
    try x(bld2_flp_d_idx, :)= d_in.QD_B2F1.Data; catch, end
    try x(bld3_flp_d_idx, :)= d_in.QD_B3F1.Data; catch, end
    try x(h_shear_d_idx, :)= 0; catch, end
    try x(v_shear_d_idx, :)= 0; catch, end

    u= zeros(nu, nt);
    if est_or_predict
        try u(in_dvwind_idx, :)= 0; catch, end
        try u(in_dh_shear_idx, :)= 0; catch, end
        try u(in_dv_shear_idx, :)= 0; catch, end
    else
        try u(in_dvwind_idx, :)= gradient(d_in.RtVAvgxh.Data, d_in.Time); catch, end
        try u(in_dh_shear_idx, :)= gradient(d_in.RtHSAvg.Data, d_in.Time); catch, end
        try u(in_dv_shear_idx, :)= gradient(d_in.RtVSAvg.Data, d_in.Time); catch, end
    end
    try u(in_vwind_idx, :)= d_in.RtVAvgxh.Data; catch, end
    try u(in_Tgen_idx, :)= d_in.GenTq.Data*1000; catch, end
    try u(in_theta_idx, :)= -d_in.BlPitchC.Data/180*pi; catch, end
    try u(in_theta1_idx, :)= -d_in.BlPitchC1.Data/180*pi; catch, end
    try u(in_theta2_idx, :)= -d_in.BlPitchC2.Data/180*pi; catch, end
    try u(in_theta3_idx, :)= -d_in.BlPitchC3.Data/180*pi; catch, end
    try u(in_bld_edg_mom_meas_idx, :)= d_in.RootMxb.Data*1000; catch, end
    try u(in_bld_flp_mom_meas_idx, :)= d_in.RootMyb.Data*1000; catch, end
    
    y= zeros(ny, nt);
    try y(out_tow_fa_acc_idx, :)= d_in.YawBrTAxp.Data; catch, end
    try y(out_tow_ss_acc_idx, :)= d_in.YawBrTAyp.Data; catch, end
    try y(out_gen_speed_idx, :)= d_in.HSShftV.Data/30*pi; catch, end
    try y(out_r_bld_flp_mom_filt_idx, :)= 0; catch, end
    try y(out_r_bld_edg_mom_filt_idx, :)= 0; catch, end
    try y(out_rot_speed_idx, :)= d_in.LSSTipVxa.Data/30*pi; catch, end
    try y(out_bld1_flp_mom_idx, :)= d_in.RootMyb1.Data*1000; catch, end
    try y(out_bld1_edg_mom_idx, :)= d_in.RootMxb1.Data*1000; catch, end
    try y(out_bld2_flp_mom_idx, :)= d_in.RootMyb2.Data*1000; catch, end
    try y(out_bld2_edg_mom_idx, :)= d_in.RootMxb2.Data*1000; catch, end
    try y(out_bld3_flp_mom_idx, :)= d_in.RootMyb3.Data*1000; catch, end
    try y(out_bld3_edg_mom_idx, :)= d_in.RootMxb3.Data*1000; catch, end
    try y(out_bld_flp_acc_idx, :)= d_in.Spn1ALxb1.Data; catch, end
    try y(out_bld_edg_acc_idx, :)= d_in.Spn1ALyb1.Data; catch, end
    try y(out_bld_flp_mom_idx, :)= d_in.RootMyb.Data*1000; catch, end
    try y(out_bld_edg_mom_idx, :)= d_in.RootMxb.Data*1000; catch, end

    x0_est= zeros(nx, 1);
%     try x0_est(vwind_idx)= d_in.Wind1VelX.Data(1); catch, end
%     try x0_est(phi_rot_d_idx)= d_in.HSShftV.Data(1)/30*pi/param.GBRatio; catch, end
    try x0_est(vwind_idx)= 8; catch, end
    try x0_est(phi_rot_d_idx)= 1000/30*pi/param.GBRatio; catch, end

    varargout{1}= x;
    varargout{2}= u;
    varargout{3}= y;
    varargout{4}= x0_est;
else
    t= varargin{1};
    q= varargin{2};
    dq= varargin{3};
    ddq= varargin{4};
    u= varargin{5};
    y= varargin{6};
    param= varargin{7};

    d_out= tscollection(t);
    try d_out= addts(d_out, 'Q_B1F1', 'm', q(bld1_flp_idx, :)); catch, end
    try d_out= addts(d_out, 'Q_B2F1', 'm', q(bld2_flp_idx, :)); catch, end
    try d_out= addts(d_out, 'Q_B3F1', 'm', q(bld3_flp_idx, :)); catch, end
    try d_out= addts(d_out, 'QD_B1F1', 'm/s', dq(bld1_flp_idx, :)); catch, end
    try d_out= addts(d_out, 'QD_B2F1', 'm/s', dq(bld2_flp_idx, :)); catch, end
    try d_out= addts(d_out, 'QD_B3F1', 'm/s', dq(bld3_flp_idx, :)); catch, end
    try d_out= addts(d_out, 'PtchPMzc1', 'deg', -u(in_theta1_idx, :)/pi*180); catch, end
    try d_out= addts(d_out, 'PtchPMzc2', 'deg', -u(in_theta2_idx, :)/pi*180); catch, end
    try d_out= addts(d_out, 'PtchPMzc3', 'deg', -u(in_theta3_idx, :)/pi*180); catch, end
    try d_out= addts(d_out, 'Q_BF1', 'm', q(bld_flp_idx, :)); catch, end
    try d_out= addts(d_out, 'Q_BE1', 'm', q(bld_edg_idx, :)); catch, end
    try d_out= addts(d_out, 'QD_BF1', 'm/s', dq(bld_flp_idx, :)); catch, end
    try d_out= addts(d_out, 'QD_BE1', 'm/s', dq(bld_edg_idx, :)); catch, end
    try d_out= addts(d_out, 'PtchPMzc', 'deg', -u(in_theta_idx, :)/pi*180); catch, end
    try d_out= addts(d_out, 'LSSTipPxa', 'deg', mod(q(phi_rot_idx, :), 2*pi)*180.0/pi); catch, end
    try d_out= addts(d_out, 'Q_GeAz', 'rad', mod(q(phi_rot_idx, :) + q(Dphi_gen_idx, :)/param.GBRatio+3/2*pi, 2*pi)); catch, end
    try d_out= addts(d_out, 'Q_GeAz', 'rad', mod(q(phi_gen_idx, :)/param.GBRatio+pi*3.0/2.0, 2*pi)); catch, end
    try d_out= addts(d_out, 'Q_DrTr', 'rad', -q(Dphi_gen_idx, :)/param.GBRatio); catch, end
    try d_out= addts(d_out, 'Q_DrTr', 'rad', q(phi_rot_idx, :) - q(phi_gen_idx, :)/param.GBRatio); catch, end
    try d_out= addts(d_out, 'QD_DrTr', 'rad', -dq(Dphi_gen_idx, :)/param.GBRatio); catch, end
    try d_out= addts(d_out, 'QD_DrTr', 'rad', dq(phi_rot_idx, :) - dq(phi_gen_idx, :)/param.GBRatio); catch, end
    try d_out= addts(d_out, 'LSSTipVxa', 'rpm', dq(phi_rot_idx, :)*30.0/pi); catch, end
    try d_out= addts(d_out, 'LSSTipAxa', 'deg/s^2', ddq(phi_rot_idx, :)*180.0/pi); catch, end
    try d_out= addts(d_out, 'HSShftV', 'rpm', (dq(phi_rot_idx, :)*param.GBRatio + dq(Dphi_gen_idx, :))*30.0/pi); catch, end
    try d_out= addts(d_out, 'HSShftV', 'rpm', dq(phi_gen_idx, :)*30.0/pi); catch, end
    try d_out= addts(d_out, 'HSShftA', 'deg/s^2', (ddq(phi_rot_idx, :)*param.GBRatio + ddq(Dphi_gen_idx, :))*180.0/pi); catch, end
    try d_out= addts(d_out, 'HSShftA', 'deg/s^2', ddq(phi_gen_idx, :)*180.0/pi); catch, end
    try d_out= addts(d_out, 'YawBrTDxp', 'm', q(tow_fa_idx, :)); catch, end
    try d_out= addts(d_out, 'YawBrTDyp', 'm', q(tow_ss_idx, :)); catch, end
    try d_out= addts(d_out, 'YawBrTVxp', 'm/s', dq(tow_fa_idx, :)); catch, end
    try d_out= addts(d_out, 'YawBrTVyp', 'm/s', dq(tow_ss_idx, :)); catch, end
    try d_out= addts(d_out, 'Q_TFA1', 'm', q(tow_fa_idx, :)); catch, end
    try d_out= addts(d_out, 'Q_TSS1', 'm', -q(tow_ss_idx, :)); catch, end
    try d_out= addts(d_out, 'QD_TFA1', 'm/s', dq(tow_fa_idx, :)); catch, end
    try d_out= addts(d_out, 'QD_TSS1', 'm/s', -dq(tow_ss_idx, :)); catch, end
    try d_out= addts(d_out, 'YawBrTAxp', 'm/s^2', ddq(tow_fa_idx, :)); catch, end
    try d_out= addts(d_out, 'YawBrTAyp', 'm/s^2', ddq(tow_ss_idx, :)); catch, end
    % try d_out= addts(d_out, 'RootFxc', 'kN', &system.Fthrust, 1.0/3000.0); catch, end
    % try d_out= addts(d_out, 'RootMxc', 'kNm', &system.Trot, 1.0/3000.0); catch, end
    % try d_out= addts(d_out, 'LSShftFxa', 'kN', &system.Fthrust, 1.0/1000.0); catch, end
    % try d_out= addts(d_out, 'LSShftMxa', 'kNm', &system.Trot, 1.0/1000.0); catch, end
    % try d_out= addts(d_out, 'RotPwr', 'kW', system.Trot*system.states.phi_rot_d/1000.0); catch, end
    try d_out= addts(d_out, 'HSShftTq', 'kNm', u(in_Tgen_idx, :)/1000.0); catch, end
    % try d_out= addts(d_out, 'HSShftPwr', 'kW', system.inputs.Tgen*system.states.phi_gen_d/1000.0); catch, end
    try d_out= addts(d_out, 'RtVAvgxh', 'm/s', q(vwind_idx, :)); catch, end
    try d_out= addts(d_out, 'RtVAvgxh', 'm/s', u(in_vwind_idx, :)); catch, end
    try d_out= addts(d_out, 'RtHSAvg', 'm/s', q(h_shear_idx, :)); catch, end
    try d_out= addts(d_out, 'RtVSAvg', 'm/s', q(v_shear_idx, :)); catch, end
    % try d_out= addts(d_out, 'RtTSR', '-', &system.lam); catch, end
    % try d_out= addts(d_out, 'RtAeroCq', '-', &system.cm); catch, end
    % try d_out= addts(d_out, 'RtAeroCt', '-', &system.ct); catch, end
    % try d_out= addts(d_out, 'RotCf', '-', &system.cflp); catch, end
    % try d_out= addts(d_out, 'RotCe', '-', &system.cedg); catch, end
    try d_out= addts(d_out, 'BlPitchC', 'deg', -u(in_theta_idx, :)*180.0/pi); catch, end
    try d_out= addts(d_out, 'BlPitchC1', 'deg', -u(in_theta1_idx, :)*180.0/pi); catch, end
    try d_out= addts(d_out, 'BlPitchC2', 'deg', -u(in_theta2_idx, :)*180.0/pi); catch, end
    try d_out= addts(d_out, 'BlPitchC3', 'deg', -u(in_theta3_idx, :)*180.0/pi); catch, end
    try d_out= addts(d_out, 'GenTq', 'kNm', u(in_Tgen_idx, :)/1000.0); catch, end
%     try d_out= addts(d_out, 'RootMxb_filt', 'kNm', y(out_bld_edg_mom_filt_idx, :)/1000); catch, end
%     try d_out= addts(d_out, 'RootMyb_filt', 'kNm', y(out_bld_flp_mom_filt_idx, :)/1000); catch, end
%     try d_out= addts(d_out, 'RootMxb', 'kNm', (y(out_bld_edg_mom_filt_idx, :)+q(m_bld_edg_mom_idx, :))/1000); catch, end
%     try d_out= addts(d_out, 'RootMyb', 'kNm', (y(out_bld_flp_mom_filt_idx, :)+q(m_bld_flp_mom_idx, :))/1000); catch, end
    try d_out= addts(d_out, 'RootMyb1', 'kNm', y(out_bld1_flp_mom_idx, :)/1000); catch, end
    try d_out= addts(d_out, 'RootMxb1', 'kNm', y(out_bld1_edg_mom_idx, :)/1000); catch, end
    try d_out= addts(d_out, 'RootMyb2', 'kNm', y(out_bld2_flp_mom_idx, :)/1000); catch, end
    try d_out= addts(d_out, 'RootMxb2', 'kNm', y(out_bld2_edg_mom_idx, :)/1000); catch, end
    try d_out= addts(d_out, 'RootMyb3', 'kNm', y(out_bld3_flp_mom_idx, :)/1000); catch, end
    try d_out= addts(d_out, 'RootMxb3', 'kNm', y(out_bld3_edg_mom_idx, :)/1000); catch, end
    try d_out= addts(d_out, 'y', '-', y); catch, end
    try d_out= addts(d_out, 'q', '-', q); catch, end
    try d_out= addts(d_out, 'dq', '-', dq); catch, end
    try d_out= addts(d_out, 'ddq', '-', ddq); catch, end

    varargout{1}= d_out;
end

function d= addts(d, name, unit, v)
ts= timeseries(name);
ts.Time= d.Time;
ts.Data= v';
ts.DataInfo.Units= unit;
ts.TimeInfo.Units= 's';
d= d.addts(ts);
