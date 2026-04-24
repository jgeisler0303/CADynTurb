LAM= 1:0.5:13;
TH= 0:0.5:45;

cm_int= casadi.interpolant('cm_int', 'linear', {LAM, TH}, 1);
ct_int= casadi.interpolant('ct_int', 'linear', {LAM, TH}, 1);
cflp_int= casadi.interpolant('cflp_int', 'linear', {LAM, TH}, 1);

dcm_dvf_v_int= casadi.interpolant('dcm_dvf_v_int', 'linear', {LAM, TH}, 1);
dct_dvf_v_int= casadi.interpolant('dct_dvf_v_int', 'linear', {LAM, TH}, 1);
dcf_dvf_v_int= casadi.interpolant('dcf_dvf_v_int', 'linear', {LAM, TH}, 1);


theta_deg= -theta/pi*180.0;
vwind_eff= vwind-tow_fa_d;
lam= phi_rot_d*Rrot/vwind_eff;
Fwind_v= rho/2.0*Arot*vwind_eff;

lam= min(max(lam, lambdaMin), lambdaMax);
theta_deg= min(max(theta_deg, thetaMin), thetaMax);

cm= cm_int([lam, theta_deg], cm_lut);
ct= ct_int([lam, theta_deg], ct_lut);
cflp= cflp_int([lam, theta_deg], cf_lut);

dcm_dvf_v= dcm_dvf_v_int([lam, theta_deg], dcm_dvf_v_lut);
dct_dvf_v= dct_dvf_v_int([lam, theta_deg], dct_dvf_v_lut);
dcf_dvf_v= dcf_dvf_v_int([lam, theta_deg], dcf_dvf_v_lut);

Trot= Rrot*Fwind_v*(vwind_eff*cm + bld_flp_d*dcm_dvf_v);
Fthrust= Fwind_v*(vwind_eff*ct + bld_flp_d*dct_dvf_v);
modalFlapForce= Fwind_v*(vwind_eff*cflp + bld_flp_d*dcf_dvf_v);
