function param= calc_cx_poly(cx_name, param)

cx_min= -0.1;

stall_region_lambda_ofs= 1;
stall_region_theta_ofs= 2;
theta_min_ofs= 1;

weight_ofs= 1e-2;
weight_max= 100;

[cp_theta_max, idx_theta_opt]= max(param.cp, [], 1);
theta_opt= param.theta(idx_theta_opt);
[~, idx_lambda_op]= max(cp_theta_max);
lambda_opt= param.lambda(idx_lambda_op);

[LAM, TH]= meshgrid(param.lambda, param.theta);
lambda_theta_cx= [LAM(:) TH(:) param.(cx_name)(:)];

lambda_theta_cx= lambda_theta_cx(lambda_theta_cx(:, 3)>cx_min, :);
lambda_theta_cx= lambda_theta_cx(lambda_theta_cx(:, 2)>=interp1(param.lambda, theta_opt, lambda_theta_cx(:, 1), 'linear', 'extrap')-theta_min_ofs, :);

vwind= param.rpm_max/30*pi/param.GBRatio*param.Rrot./lambda_theta_cx(:, 1);
wpower= param.rho/2*param.Rrot^2*pi*vwind.^3.*lambda_theta_cx(:, 3);

idx_max_power= wpower>param.power_max;
lambda_partial_min= max(lambda_theta_cx(idx_max_power, 1));


% weighting for relative error instead of absolute error
w= 1./(abs(lambda_theta_cx(:, 3))+weight_ofs);
w(w>weight_max)= weight_max;

% no fit in stall region required
idx_stall_region= lambda_theta_cx(:, 1)>lambda_opt+stall_region_lambda_ofs & lambda_theta_cx(:, 2)>interp1(param.lambda, theta_opt, lambda_theta_cx(:, 1), 'linear', 'extrap')+stall_region_theta_ofs;
w(idx_stall_region)= 0;

% fir for negative cp not so important
w(lambda_theta_cx(:, 3)<0)= w(lambda_theta_cx(:, 3)<0)*0.1;

% better fit for partial operation
idx_theta_opt= abs(lambda_theta_cx(:, 2) - interp1(param.lambda, theta_opt, lambda_theta_cx(:, 1), 'linear', 'extrap'))<=1 & lambda_theta_cx(:, 1)>lambda_partial_min;
w(idx_theta_opt)= w(idx_theta_opt)*3;

% extra good fit for around rated production
idx_rated_power= wpower>0.9*param.power_max & wpower<1.1*param.power_max;
w(idx_rated_power)= w(idx_rated_power)*10;

% too high power needs less good fit
vwind_hi_lam= param.rpm_max/30*pi/param.GBRatio*param.Rrot./lambda_theta_cx(:, 1);
power_hi_lam= param.rho/2 * param.Rrot^2*pi * vwind_hi_lam.^3.*lambda_theta_cx(:, 3);

vwind_low_lam= param.rpm_min/30*pi/param.GBRatio*param.Rrot./lambda_theta_cx(:, 1);
power_low_lam= 1.1/2*param.Rrot^2*pi*vwind_low_lam.^3.*lambda_theta_cx(:, 3);

power_ref= min(power_hi_lam, 4*power_low_lam); % max 25% rated power @ rpm min
idx_above_rated= power_ref>1.2*param.power_max;
w(idx_above_rated)= w(idx_above_rated)*0.1;


% the exponents of the polynomial terms
lambda_theta_exponents= [0 1 2 3 4 5 6 0 1 2 3 4 5 0 1 2 3 4 0 1 2 3;
                         0 0 0 0 0 0 0 1 1 1 1 1 1 2 2 2 2 2 3 3 3 3]';

n= size(lambda_theta_exponents, 1);
X= zeros(size(lambda_theta_cx, 1), n);
for i= 1:n
    X(:, i)= w.*(lambda_theta_cx(:, 1).^lambda_theta_exponents(i, 1) .* lambda_theta_cx(:, 2).^lambda_theta_exponents(i, 2));
end
% calculate the coefficients
coeff_name= [cx_name '_coeff'];
exp_name= [cx_name '_exp'];
param.(coeff_name)= X\(w.*lambda_theta_cx(:, 3));
param.(exp_name)= lambda_theta_exponents;

if nargout==0
    plot_cx_poly(cx_name, lambda_theta_cx, param);
end
