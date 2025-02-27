LAM= 1:0.5:13;
TH= 0:0.5:45;

cm_int= casadi.interpolant('cm_int', 'linear', {LAM, TH}, 1);
ct_int= casadi.interpolant('ct_int', 'linear', {LAM, TH}, 1);

theta_deg= -theta/pi*180.0;
vwind_eff= vwind-tow_fa_d;
lam= phi_rot_d*Rrot/vwind_eff;
Fwind_v= rho/2.0*Arot*vwind_eff;

lam= min(max(lam, lambdaMin), lambdaMax);
theta_deg= min(max(theta_deg, thetaMin), thetaMax);

cm= cm_int([lam, theta_deg], cm_lut);
ct= ct_int([lam, theta_deg], ct_lut);

Trot= Rrot*Fwind_v*(vwind_eff*cm);
Fthrust= Fwind_v*(vwind_eff*ct);
