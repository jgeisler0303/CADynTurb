load('param.mat')
param.TwTrans2Roll= tw_sid.frame(11).Psi.M0(2, 1);
param.cf_lut= param.cb1';
param.ce_lut= param.cb2';
param.ct_lut= param.ct';
param.cm_lut= param.cm';
param.dcm_dvf_v_lut= param.dcm_dvb1_v';
param.dct_dvf_v_lut= param.dct_dvb1_v';
param.dcf_dvf_v_lut= param.dcb1_dvb1_v';
param.dce_dvf_v_lut= param.dcb2_dvb1_v';
param.dcm_dve_v_lut= param.dcm_dvb2_v';
param.dct_dve_v_lut= param.dct_dvb2_v';
param.dcf_dve_v_lut= param.dcb1_dvb2_v';
param.dce_dve_v_lut= param.dcb2_dvb2_v';
param.lambdaMin= param.lambda(1);
param.lambdaMax= param.lambda(end);
param.lambdaStep= mean(diff(param.lambda));

param.thetaMin= param.theta(1);
param.thetaMax= param.theta(end);
param.thetaStep= mean(diff(param.theta));
