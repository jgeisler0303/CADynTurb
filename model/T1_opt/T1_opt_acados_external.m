LAM= 1:0.5:13;
TH= 0:0.5:45;

% cm_lut= param.cm_lut;
% cm_int= casadi.interpolant('cm_int', 'linear', {LAM, TH}, cm_lut(:));
cp_lut= param.cp';
cp_int= casadi.interpolant('cp_int', 'linear', {LAM, TH}, cp_lut(:));
ct_lut= param.ct_lut;
ct_int= casadi.interpolant('ct_int', 'linear', {LAM, TH}, ct_lut(:));

theta_deg= -theta/pi*180.0;
vwind_eff= vwind-tow_fa_d;
lam= phi_rot_d*Rrot/vwind_eff;
Fwind_v= rho/2.0*Arot*vwind_eff;

lam= min(max(lam, lambdaMin), lambdaMax);
theta_deg= min(max(theta_deg, thetaMin), thetaMax);

% Alternative formulation via polynomials
% cp= eval_poly(lam, theta_deg, param.cp_coeff, param.cp_exp);
% cp= min(0.6, max(-0.1, cp));
% cm=cp/phi_rot_d/Rrot;

% ct= eval_poly(lam, theta_deg, param.ct_coeff, param.ct_exp);
% ct= min(1.2, max(-0.1, ct));

% LUT formulation
% cm= cm_int([lam, theta_deg]);
cp= cp_int([lam, theta_deg]);
ct= ct_int([lam, theta_deg]);

% Trot= Rrot*Fwind_v*(vwind_eff*cm);
P = rho/2.0*Arot*vwind_eff^3*cp;
Trot = P / phi_rot_d;
Fthrust= Fwind_v*(vwind_eff*ct);