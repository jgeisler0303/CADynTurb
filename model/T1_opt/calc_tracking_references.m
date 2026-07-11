function [om_rot_ref, Tgen_ref, theta_ref, P_ref] = calc_tracking_references(vwind, param)
    % Calculate optimal generator speed, power, and pitch reference for given wind speed
    % 
    % Inputs:
    %   vwind      - Wind speed [m/s]
    %   param      - Parameter structure with cp surface and power limits
    %
    % Outputs:
    %   om_rot_ref - Rotor angular velocity reference [rad/s]
    %   Tgen_ref   - Generator torque reference [Nm]
    %   theta_ref  - Pitch angle reference [rad]
    %   P          - Power [W]
    
    % Compute lambda_opt from cp surface, consistent with eco_multi_cost
    [cp_max, idx_theta_opt] = max(param.cp, [], 1);
    [~, idx_lam_opt] = max(cp_max);
    lambda_opt = param.lambda(idx_lam_opt);

    % Build a lookup table for the optimal pitch angle over lambda
    theta_opt_lut = param.theta(idx_theta_opt);

    % Calculate optimal rotor speed and clip to limits
    om_rot_opt = lambda_opt * vwind / param.Rrot;
    om_rot_ref = max(min(om_rot_opt, param.rpm_max/30*pi/param.GBRatio), param.rpm_min/30*pi/param.GBRatio);
    
    % Calculate tip speed ratio, optimal pitch, and power coefficient at optimal pitch
    lam = clip(om_rot_ref * param.Rrot / vwind, param.lambda(1), param.lambda(end));
    theta_opt = interp1(param.lambda, theta_opt_lut, lam, 'linear');
    cp_opt = max(interp2(param.lambda, param.theta, param.cp, lam, theta_opt, 'linear', 0), 0);
    
    % Calculate power at optimal pitch
    P_opt = param.rho/2.0 * param.Arot * vwind^3 * cp_opt;
    P_ref = min(P_opt, param.power_max);

    % Calculate torque from rated or optimal power
    Tgen_ref = P_ref / om_rot_ref / param.GBRatio;

    % Determine pitch reference
    if P_opt <= param.power_max
        % Below rated power: use optimal pitch for maximum power extraction
        theta_ref = theta_opt;
    else
        % Above rated power: use calculated pitch to limit power to rated value
        theta_ref = interp1(param.vwind_vec, param.theta_full_lut, vwind, 'linear');
    end

    theta_ref = -theta_ref/180*pi;
end
