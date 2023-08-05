function [A, B, C, D, E]= eval_lin_turbine(lin_fun, param, q, qd, qdd, vwind, vwind_ref, theta_ref)
model_indices
tow_fa= q(tow_fa_idx);
tow_ss= q(tow_ss_idx);
bld_flp= q(bld_flp_idx);
bld_edg= q(bld_edg_idx);
phi_rot= q(phi_rot_idx);

tow_fa_d= qd(tow_fa_idx);
tow_ss_d= qd(tow_ss_idx);
bld_flp_d= qd(bld_flp_idx);
bld_edg_d= qd(bld_edg_idx);
phi_rot_d= qd(phi_rot_idx);
phi_gen_d= qd(phi_gen_idx);

tow_fa_dd= qdd(tow_fa_idx);
tow_ss_dd= qdd(tow_ss_idx);
bld_flp_dd= qdd(bld_flp_idx);
bld_edg_dd= qdd(bld_edg_idx);
phi_rot_dd= qdd(phi_rot_idx);
phi_gen_dd= qdd(phi_gen_idx);

[lam, theta_deg]= eff_values(param, vwind_ref, theta_ref, phi_rot_d, tow_fa_d);
cm_ref= interp2(param.lambda, param.theta, param.cm_lut', lam, theta_deg);

lam= eff_values(param, vwind, theta_deg, phi_rot_d, tow_fa_d);
theta_deg= fzero(@(th)interp2(param.lambda, param.theta, param.cm_lut', lam, th)-cm_ref, [0 30]);

[lam, theta_deg, theta, vwind_eff, Fwind, Fwind_v]= eff_values(param, vwind, theta_deg, phi_rot_d, tow_fa_d);

cm= interp2(param.lambda, param.theta, param.cm_lut', lam, theta_deg);
ct= interp2(param.lambda, param.theta, param.ct_lut', lam, theta_deg);
cflp= interp2(param.lambda, param.theta, param.cf_lut', lam, theta_deg);
cedg= interp2(param.lambda, param.theta, param.ce_lut', lam, theta_deg);
cmy_D23= interp2(param.lambda, param.theta, param.cmy_D23_lut', lam, theta_deg);

dcm_dvf_v= interp2(param.lambda, param.theta, param.dcm_dvf_v_lut', lam, theta_deg);
dcm_dve_v= interp2(param.lambda, param.theta, param.dcm_dve_v_lut', lam, theta_deg);
dct_dvf_v= interp2(param.lambda, param.theta, param.dct_dvf_v_lut', lam, theta_deg);
dct_dve_v= interp2(param.lambda, param.theta, param.dct_dve_v_lut', lam, theta_deg);
dcs_dvy_v= interp2(param.lambda, param.theta, param.dcs_dvy_v_lut', lam, theta_deg);
dcf_dvf_v= interp2(param.lambda, param.theta, param.dcf_dvf_v_lut', lam, theta_deg);
dcf_dve_v= interp2(param.lambda, param.theta, param.dcf_dve_v_lut', lam, theta_deg);
dce_dvf_v= interp2(param.lambda, param.theta, param.dce_dvf_v_lut', lam, theta_deg);
dce_dve_v= interp2(param.lambda, param.theta, param.dce_dve_v_lut', lam, theta_deg);

Trot= param.Rrot*Fwind_v*(vwind_eff*cm + bld_flp_d*dcm_dvf_v + bld_edg_d*dcm_dve_v);
Fthrust= Fwind_v*(vwind_eff*ct + bld_flp_d*dct_dvf_v + bld_edg_d*dct_dve_v);
MyD23= param.Rrot*Fwind_v*vwind_eff*cmy_D23;

Ftow_y= 1.5*Fwind_v*tow_ss_d*dcs_dvy_v;
modalFlapForce= Fwind_v*(vwind_eff*cflp + bld_flp_d*dcf_dvf_v + bld_edg_d*dcf_dve_v);
modalEdgeForce= Fwind_v*(vwind_eff*cedg + bld_flp_d*dce_dvf_v + bld_edg_d*dce_dve_v);

dFwind_dvw   =  2*Fwind_v; % 2*Fwind/vwind;
dFwind_dvtow = -2*Fwind_v; % -2*Fwind/vwind;

dlam_dvw   = -lam/vwind;
dlam_dvtow =  lam/vwind;
dlam_dphi_rot_d= lam/phi_rot_d;

[dTrot_dtow_fa_d, dTrot_dbld_flp_d, dTrot_dbld_edg_d, dTrot_dphi_rot_d, dTrot_dvwind, dTrot_dtheta]= aeroForceDerivs( ...
    param.Rrot, cm, DLAM_interp(param, param.cm_lut, lam, theta_deg), DTH_interp(param, param.cm_lut, lam, theta_deg), ...
    dcm_dvf_v, dcm_dve_v, ...
    dlam_dvw, dlam_dvtow, dlam_dphi_rot_d, ...
    Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw);

[dFthrust_dtow_fa_d, dFthrust_dbld_flp_d, dFthrust_dbld_edg_d, dFthrust_dphi_rot_d, dFthrust_dvwind, dFthrust_dtheta]= aeroForceDerivs( ...
    1, ct, DLAM_interp(param, param.ct_lut, lam, theta_deg), DTH_interp(param, param.ct_lut, lam, theta_deg), ...
    dct_dvf_v, dct_dve_v, ...
    dlam_dvw, dlam_dvtow, dlam_dphi_rot_d, ...
    Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw);

[dmodalFlapForce_dtow_fa_d, dmodalFlapForce_dbld_flp_d, dmodalFlapForce_dbld_edg_d, dmodalFlapForce_dphi_rot_d, dmodalFlapForce_dvwind, dmodalFlapForce_dtheta]= aeroForceDerivs( ...
    1, cflp, DLAM_interp(param, param.cf_lut, lam, theta_deg), DTH_interp(param, param.cf_lut, lam, theta_deg), ...
    dcf_dvf_v, dcf_dve_v, ...
    dlam_dvw, dlam_dvtow, dlam_dphi_rot_d, ...
    Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw);

[dmodalEdgeForce_dtow_fa_d, dmodalEdgeForce_dbld_flp_d, dmodalEdgeForce_dbld_edg_d, dmodalEdgeForce_dphi_rot_d, dmodalEdgeForce_dvwind, dmodalEdgeForce_dtheta]= aeroForceDerivs( ...
    1, cedg, -1.0*DLAM_interp(param, param.ce_lut, lam, theta_deg), -1.0*DTH_interp(param, param.ce_lut, lam, theta_deg), ...
    dce_dvf_v, dce_dve_v, ...
    dlam_dvw, dlam_dvtow, dlam_dphi_rot_d, ...
    Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw);

dMyD23_dlam=  DLAM_interp(param, param.cmy_D23_lut, lam, theta_deg);
dMyD23_dphi_rot_d= param.Rrot*dMyD23_dlam * dlam_dphi_rot_d;
dMyD23_dvwind= param.Rrot*dMyD23_dlam * dlam_dvw;
dMyD23_dtheta= param.Rrot*DTH_interp(param, param.cmy_D23_lut, lam, theta_deg);


dFtow_y_dtow_ss_d= 1.5*Fwind_v*dcs_dvy_v;
% TODO to be exact, the derivative with respect to qd3, wind and theta are missing here 

run(lin_fun)

function [lam, theta_deg, theta, vwind_eff, Fwind, Fwind_v]= eff_values(param, vwind, theta_deg, phi_rot_d, tow_fa_d)
theta= -theta_deg/180*pi;
vwind_eff= vwind-tow_fa_d;
lam= phi_rot_d*param.Rrot/vwind_eff;
Fwind= param.rho/2.0*param.Arot*vwind_eff*vwind_eff;
Fwind_v= param.rho/2.0*param.Arot*vwind_eff;

if lam>param.lambdaMax-param.lambdaStep
    lam= param.lambdaMax-param.lambdaStep;
end
if lam<param.lambdaMin 
    lam= param.lambdaMin;
end
if theta_deg>param.thetaMax-param.thetaStep
    theta_deg= param.thetaMax-param.thetaStep;
end
if theta_deg<param.thetaMin
    theta_deg= param.thetaMin;
end
