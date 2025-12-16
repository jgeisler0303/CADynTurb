function [multi_cost, theta_min]= eco_multi_cost(param, sym_p, vwind, GBRatio, Rrot, phi_rot_d, Tgen, theta, dTgen, dtheta, tow_fa_d, rho, rpm_max, power_max, w_cost)

[xs, ys, theta_opt_poly, lambda_opt]= calc_cp_max_spline(param);
cp_lam= casadi.interpolant('cp_lam', 'bspline', {xs}, ys);

% 1 economic cost
lambda= phi_rot_d*Rrot/vwind;
cp_opt= w_cost(1) * cp_lam(lambda); % TODO: maybe with vwind_eff?
multi_cost.eco= -cp_opt; % TODO: add normalizing offset in case of stagewise wind speeds

% 2 maximal rpm cost
% slope of cp_opt at rpm_max
% needed for a smooth transition between cp_opt und rpm_max costs
omgen_= casadi.MX.sym('omgen_', 1); 
lam_g= omgen_/GBRatio*Rrot/vwind;
cp_g= cp_lam(lam_g);
dcp_lam_fun = casadi.Function('dcp_lam_fun', {omgen_, sym_p}, {gradient(cp_g, omgen_)});
om_gen_max= rpm_max/30*pi;
dcp_dom_rot= dcp_lam_fun(om_gen_max, sym_p); % TODO: maybe with vwind_eff?

w_cp= w_cost(1);
w_rpm_max= w_cost(2);
slope= dcp_dom_rot*w_cp/w_rpm_max;
slope= min(slope, 0.98); % slope too steep should not occur by choice of w_rpm_max
slope= max(slope, 0.02); % slope too flat or negativ will always occur in partial load

rpm_rounding= 40;
om_rounding= rpm_rounding/30*pi;
% diff smooth_plus= x/(2*sqrt(x^2 + r)) + 1/2
% setequal to slope and solve for x
slope_comp= -sqrt(om_rounding^2/(4*(slope-slope^2)) - om_rounding^2);
multi_cost.rpm_max= w_cost(2) * smooth_plus(phi_rot_d*GBRatio-om_gen_max+slope_comp, om_rounding^2);

% 3,4 torque-pitch fading cost
omrot_= casadi.MX.sym('omrot_', 1); 
lam_= omrot_*Rrot/vwind;
cp_= cp_lam(lam_);
cp_lam_fun= casadi.Function('cp_lam_fun', {omrot_, sym_p}, {cp_});

Pwind= 0.5*rho*pi*Rrot*Rrot*vwind^3;
om_rot_max= om_gen_max/GBRatio;
Pmech= Pwind*cp_lam_fun(om_rot_max, sym_p);
rated_operation= 0.5*(1+tanh(((Pmech-power_max)/power_max*100-10)*2/10));

% min opt pitch angle
om_gen_opt= lambda_opt*vwind/Rrot*GBRatio;
om_gen_opt= min(om_gen_max, om_gen_opt); % TODO: add rpm min
lambda_opt= om_gen_opt/GBRatio*Rrot/vwind;
lambda_opt2= lambda_opt*lambda_opt;
lambda_opt3= lambda_opt2*lambda_opt;
theta_set= lambda_opt3*theta_opt_poly(1) + lambda_opt2*theta_opt_poly(2) + lambda_opt*theta_opt_poly(3) + theta_opt_poly(4);

multi_cost.theta= w_cost(4) * (1-rated_operation) * ((theta-theta_set)/(10/180*pi))^2; % Maybe add torque dependent offset

trq_max= power_max/om_gen_max;
multi_cost.trq=  w_cost(5) * rated_operation * ((Tgen-trq_max)/trq_max)^2; % Maybe add pitch dependent offset

% 5,6 actuator rate smoothing
multi_cost.dgen_trq= w_cost(8) * dTgen^2;
multi_cost.dtheta_ref= w_cost(9) * dtheta^2; % TODO: make smooth abs for bang bang action

% drivetrain damping
% cost.dtdamp= (phi_gen_d/GBRatio-phi_rot_d)^2;

% 7 tower damper
multi_cost.twrdamp= w_cost(6) * tow_fa_d^2;
% blade damper
% multi_cost.blddamp= bld_flp_d^2;

lambda2= lambda*lambda;
lambda3= lambda2*lambda;
theta_min= lambda3*theta_opt_poly(1) + lambda2*theta_opt_poly(2) + lambda*theta_opt_poly(3) + theta_opt_poly(4);