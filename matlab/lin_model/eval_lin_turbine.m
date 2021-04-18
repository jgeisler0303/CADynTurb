function [A, B, C, D, E]= eval_lin_turbine(lin_fun, param, q, qd, qdd, vwind, vwind_ref, theta_ref)
vTLng= qd(1);
vTLat= qd(2);
omrot= qd(3);
vBEdge= qd(4);
vBFlap= qd(5);

[lam, theta_deg]= eff_values(param, vwind_ref, theta_ref, omrot, vTLng);
cm_ref= interp2(param.lambda, param.theta, param.cm_lut', lam, theta_deg);

lam= eff_values(param, vwind, theta_deg, omrot, vTLng);
theta_deg= fzero(@(th)interp2(param.lambda, param.theta, param.cm_lut', lam, th)-cm_ref, [2 30]);

[lam, theta_deg, theta, vwind_eff, Fwind, Fwind_v]= eff_values(param, vwind, theta_deg, omrot, vTLng);

cm= interp2(param.lambda, param.theta, param.cm_lut', lam, theta_deg);
ct= interp2(param.lambda, param.theta, param.ct_lut', lam, theta_deg);
cflp= interp2(param.lambda, param.theta, param.cf_lut', lam, theta_deg);
cedg= interp2(param.lambda, param.theta, param.ce_lut', lam, theta_deg);

dcm_dvf_v= interp2(param.lambda, param.theta, param.dcm_dvf_v_lut', lam, theta_deg);
dcm_dve_v= interp2(param.lambda, param.theta, param.dcm_dve_v_lut', lam, theta_deg);
dct_dvf_v= interp2(param.lambda, param.theta, param.dct_dvf_v_lut', lam, theta_deg);
dct_dve_v= interp2(param.lambda, param.theta, param.dct_dve_v_lut', lam, theta_deg);
dcs_dvy_v= interp2(param.lambda, param.theta, param.dcs_dvy_v_lut', lam, theta_deg);
dcf_dvf_v= interp2(param.lambda, param.theta, param.dcf_dvf_v_lut', lam, theta_deg);
dcf_dve_v= interp2(param.lambda, param.theta, param.dcf_dve_v_lut', lam, theta_deg);
dce_dvf_v= interp2(param.lambda, param.theta, param.dce_dvf_v_lut', lam, theta_deg);
dce_dve_v= interp2(param.lambda, param.theta, param.dce_dve_v_lut', lam, theta_deg);

Trot= param.Rrot*Fwind_v*(vwind_eff*cm + vBFlap*dcm_dvf_v + vBEdge*dcm_dve_v);
Fthrust= Fwind_v*(vwind_eff*ct + vBFlap*dct_dvf_v + vBEdge*dct_dve_v);
Ftow_y= 1.5*Fwind_v*vTLat*dcs_dvy_v;
modalFlapForce= Fwind_v*(vwind_eff*cflp + vBFlap*dcf_dvf_v + vBEdge*dcf_dve_v);
modalEdgeForce= Fwind_v*(vwind_eff*cedg + vBFlap*dce_dvf_v + vBEdge*dce_dve_v);

dFwind_dvw   =  2*Fwind_v; % 2*Fwind/vwind;
dFwind_dvtow = -2*Fwind_v; % -2*Fwind/vwind;

dlam_dvw   = -lam/vwind;
dlam_dvtow =  lam/vwind;
dlam_domrot= lam/omrot;

[dTrot_dqd1, dTrot_dqd3, dTrot_dqd4, dTrot_dqd5, dTrot_dvwind, dTrot_dtheta]= aeroForceDerivs(cm, DLAM_interp(param, param.cm_lut, lam, theta_deg), DTH_interp(param, param.cm_lut, lam, theta_deg), ...
                dcm_dvf_v, dcm_dve_v, ...
                dlam_dvw, dlam_dvtow, dlam_domrot, ...
                Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw);

[dFthrust_dqd1, dFthrust_dqd3, dFthrust_dqd4, dFthrust_dqd5, dFthrust_dvwind, dFthrust_dtheta]= aeroForceDerivs(ct, DLAM_interp(param, param.ct_lut, lam, theta_deg), DTH_interp(param, param.ct_lut, lam, theta_deg), ...
                dct_dvf_v, dct_dve_v, ...
                dlam_dvw, dlam_dvtow, dlam_domrot, ...
                Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw);

[dmodalFlapForce_dqd1, dmodalFlapForce_dqd3, dmodalFlapForce_dqd4, dmodalFlapForce_dqd5, dmodalFlapForce_dvwind, dmodalFlapForce_dtheta]= aeroForceDerivs(cflp, DLAM_interp(param, param.cf_lut, lam, theta_deg), DTH_interp(param, param.cf_lut, lam, theta_deg), ...
                dcf_dvf_v, dcf_dve_v, ...
                dlam_dvw, dlam_dvtow, dlam_domrot, ...
                Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw);

[dmodalEdgeForce_dqd1, dmodalEdgeForce_dqd3, dmodalEdgeForce_dqd4, dmodalEdgeForce_dqd5, dmodalEdgeForce_dvwind, dmodalEdgeForce_dtheta]= aeroForceDerivs(cedg, -1.0*DLAM_interp(param, param.ce_lut, lam, theta_deg), -1.0*DTH_interp(param, param.ce_lut, lam, theta_deg), ...
                dce_dvf_v, dce_dve_v, ...
                dlam_dvw, dlam_dvtow, dlam_domrot, ...
                Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw);

dFtow_y_dqd2= 1.5*Fwind_v*dcs_dvy_v;
% TODO to be exact, the derivative with respect to qd3, wind and theta are missing here 

run(lin_fun)

function [lam, theta_deg, theta, vwind_eff, Fwind, Fwind_v]= eff_values(param, vwind, theta_deg, omrot, vTLng)
theta= -theta_deg/180*pi;
vwind_eff= vwind-vTLng;
lam= omrot*param.Rrot/vwind_eff;
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
