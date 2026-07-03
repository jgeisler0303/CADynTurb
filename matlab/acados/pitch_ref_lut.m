function [VW, theta_full_lut, theta_opt_lut, lambda_opt] = pitch_ref_lut(param)
    % Build LUT for full-load pitch reference as a function of wind speed.
    VW = 3:25;
    theta_full_lut = zeros(size(VW));

    theta_min = min(param.theta);
    theta_max = max(param.theta);
    om_rot_max = param.rpm_max/30*pi/param.GBRatio;

    for i = 1:length(VW)
        cp_target = param.power_max / (param.rho/2.0 * param.Arot * VW(i)^3);
        lambda_full = om_rot_max * param.Rrot / VW(i);
        theta_full_lut(i) = fminbnd(@(theta) (interp2(param.lambda, param.theta, param.cp, lambda_full, theta, 'linear', 0) - cp_target)^2, theta_min, theta_max);
    end

    % Build a lookup table for the optimal pitch angle over lambda
    [cp_max, idx_theta_opt] = max(param.cp, [], 1);
    theta_opt_lut = param.theta(idx_theta_opt);

    [~, idx_lam_opt] = max(cp_max);
    lambda_opt = param.lambda(idx_lam_opt);
end
