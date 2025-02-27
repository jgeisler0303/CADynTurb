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
Fthrust= Fwind*ct;

% cost
[xs, ys]= calc_cp_max_spline(param);
cp_lam= casadi.interpolant('cp_lam', 'bspline', {xs}, ys);

omrot_= casadi.MX.sym('omrot_', 1); 
vwind_= casadi.MX.sym('vwind_', 1); 
lam_= omrot_*Rrot/vwind_;
cp_= cp_lam(lam_);

cp_lam_fun= casadi.Function('cp_lam_fun', {omrot_, vwind_, sym_p}, {cp_});

% slope of cp_opt at rpm_max
% needed for a smooth transition between cp_opt und rpm_max costs
dcp_lam_fun = casadi.Function('dcp_lam_fun', {omrot_, vwind_, sym_p}, {gradient(cp_, omrot_)});
om_rot_max= rpm_max/30*pi/GBRatio;
dcp_dom_rot= dcp_lam_fun(om_rot_max, vwind_eff, sym_p);

% 1 economic cost
cp_opt= w_cost(1) * cp_lam(phi_rot_d*Rrot/vwind); % TODO: maybe with vwind_eff?
multi_cost.eco= -cp_opt; % TODO: add normalizing offset in case of stagewise wind speeds

% 2 maximal rpm cost
w_cp= w_cost(1);
w_rpm_max= w_cost(2);
rpm_rounding= 10;
om_rounding= rpm_rounding/30*pi/GBRatio;
eff_rounding= max(4*(w_cp*dcp_dom_rot)^2/w_rpm_max^2, om_rounding^2);
multi_cost.rpm_max= w_cost(2) * smooth_plus(phi_rot_d-om_rot_max, eff_rounding)^2;

% 3,4 torque-pitch fading cost
Pwind= 0.5*rho*Arot*vwind^3;
Pmech= Pwind*cp_lam_fun(om_rot_max, vwind, sym_p);
rated_operation= 0.5*(1+tanh(((Pmech-power_max)/power_max*100-10)*2/10));
multi_cost.theta= w_cost(3) * (1-rated_operation) * ((theta-pit_min)/(10/180*pi))^2; % Maybe add torque dependent offset
trq_set= param.power_max/(om_rot_max*GBRatio);
multi_cost.trq=  w_cost(4) * rated_operation * ((Tgen-trq_set)/trq_set)^2; % Maybe add pitch dependent offset

% 5,6 actuator rate smoothing
multi_cost.dgen_trq= w_cost(5) * dTgen^2;
multi_cost.dtheta_ref= w_cost(6) * dtheta^2;

% drivetrain damping
% cost.dtdamp= (phi_gen_d/GBRatio-phi_rot_d)^2;

% 7 tower damper
multi_cost.twrdamp= w_cost(7) * tow_fa_d^2;
% blade damper
% multi_cost.blddamp= bld_flp_d^2;

model.cost_expr_ext_cost_0= multi_cost.dgen_trq + multi_cost.dtheta_ref;
model.cost_expr_ext_cost= multi_cost.eco + multi_cost.rpm_max + multi_cost.theta + multi_cost.trq + multi_cost.dgen_trq + multi_cost.dtheta_ref + multi_cost.twrdamp;
model.cost_expr_ext_cost_e= multi_cost.eco + multi_cost.rpm_max + multi_cost.theta + multi_cost.trq + multi_cost.twrdamp;