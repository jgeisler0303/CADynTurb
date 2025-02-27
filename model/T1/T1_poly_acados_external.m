theta_deg= -theta/pi*180.0;
vwind_eff= vwind-tow_fa_d;
lam= phi_rot_d*Rrot/vwind_eff;
Fwind= rho/2.0*Arot*vwind_eff*vwind_eff;

lam= min(max(lam, lambdaMin), lambdaMax);
theta_deg= min(max(theta_deg, thetaMin), thetaMax);

cp= eval_poly(lam, theta_deg, param.cp_coeff, param.cp_exp);
cp= min(0.6, max(-0.1, cp));

ct= eval_poly(lam, theta_deg, param.ct_coeff, param.ct_exp);
ct= min(1.2, max(-0.1, ct));

Trot= Fwind*vwind_eff*cp / phi_rot_d;
Fthrust= Fwind_v*(vwind_eff*ct);
