LAM= 1:0.25:13;
TH= 0:0.25:40;

paramName.cm_tab= length(LAM)*length(TH);

cm_int= casadi.interpolant('cm_int', 'linear', {LAM, TH}, 1);
ct_int= casadi.interpolant('ct_int', 'linear', {LAM, TH}, 1);
cflp_int= casadi.interpolant('cflp_int', 'linear', {LAM, TH}, 1);
cedg_int= casadi.interpolant('cedg_int', 'linear', {LAM, TH}, 1);

dcm_dvf_v_int= casadi.interpolant('dcm_dvf_v_int', 'linear', {LAM, TH}, 1);
dcm_dve_v_int= casadi.interpolant('dcm_dve_v_int', 'linear', {LAM, TH}, 1);
dct_dvf_v_int= casadi.interpolant('dct_dvf_v_int', 'linear', {LAM, TH}, 1);
dct_dve_v_int= casadi.interpolant('dct_dve_v_int', 'linear', {LAM, TH}, 1);
dcs_dvy_v_int= casadi.interpolant('dcs_dvy_v_int', 'linear', {LAM, TH}, 1);
dcf_dvf_v_int= casadi.interpolant('dcf_dvf_v_int', 'linear', {LAM, TH}, 1);
dcf_dve_v_int= casadi.interpolant('dcf_dve_v_int', 'linear', {LAM, TH}, 1);
dce_dvf_v_int= casadi.interpolant('dce_dvf_v_int', 'linear', {LAM, TH}, 1);
dce_dve_v_int= casadi.interpolant('dce_dve_v_int', 'linear', {LAM, TH}, 1);


theta_deg= -theta/pi*180.0;
vwind_eff= vwind-qd1;
lam= qd3*Rrot/vwind_eff;
Fwind_v= rho/2.0*Arot*vwind_eff;

lam= min(max(lam, lambdaMin), lambdaMax);
theta_deg= min(max(theta_deg, thetaMin), thetaMax);

cm= cm_int([lam, theta_deg], cm_lut);
ct= ct_int([lam, theta_deg], ct_lut);
cflp= cflp_int([lam, theta_deg], cf_lut);
cedg= cedg_int([lam, theta_deg], ce_lut);

dcm_dvf_v= dcm_dvf_v_int([lam, theta_deg], dcm_dvf_v_lut);
dcm_dve_v= dcm_dve_v_int([lam, theta_deg], dcm_dve_v_lut);
dct_dvf_v= dct_dvf_v_int([lam, theta_deg], dct_dvf_v_lut);
dct_dve_v= dct_dve_v_int([lam, theta_deg], dct_dve_v_lut);
dcs_dvy_v= dcs_dvy_v_int([lam, theta_deg], dcs_dvy_v_lut);
dcf_dvf_v= dcf_dvf_v_int([lam, theta_deg], dcf_dvf_v_lut);
dcf_dve_v= dcf_dve_v_int([lam, theta_deg], dcf_dve_v_lut);
dce_dvf_v= dce_dvf_v_int([lam, theta_deg], dce_dvf_v_lut);
dce_dve_v= dce_dve_v_int([lam, theta_deg], dce_dve_v_lut);

Trot= Rrot*Fwind_v*(vwind_eff*cm + qd4*dcm_dvf_v + qd5*dcm_dve_v);
Fthrust= Fwind_v*(vwind_eff*ct + qd4*dct_dvf_v + qd5*dct_dve_v);
Ftow_y= 1.5*Fwind_v*qd2*dcs_dvy_v;
modalFlapForce= Fwind_v*(vwind_eff*cflp + qd4*dcf_dvf_v + qd5*dcf_dve_v);
modalEdgeForce= Fwind_v*(vwind_eff*cedg + qd4*dce_dvf_v + qd5*dce_dve_v);
