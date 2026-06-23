function [om_rot_ref, Tgen_ref, theta_ref, P] = calc_tracking_references(param)
    % Calculate optimal generator speed, power, and pitch reference for given wind speed
    % 
    % Inputs:
    %   param      - Parameter structure with lambda_opt, cp surface, power limits
    %
    % Outputs:
    %   om_rot_ref - Rotor angular velocity reference [rad/s]
    %   Tgen_ref   - Generator torque reference [Nm]
    %   theta_ref  - Pitch angle reference [rad]
    %   P          - Power [W]
    
    % Calculate optimal rotor speed and clip to limits
    om_rot_opt = param.lambda_opt * param.vwind / param.Rrot;
    om_rot_ref = clip(om_rot_opt, param.rpm_min/30*pi/param.GBRatio, param.rpm_max/30*pi/param.GBRatio);
    
    % Calculate tip speed ratio, optimal pitch, and power coefficient at optimal pitch
    lam = om_rot_ref * param.Rrot / param.vwind;
    theta_min = min(param.theta);
    theta_max = max(param.theta);
    theta_opt = fminbnd(@(theta) -interp2(param.lambda, param.theta, param.cp, lam, theta, 'linear', 0), theta_min, theta_max);
    cp_opt = max(interp2(param.lambda, param.theta, param.cp, lam, theta_opt, 'linear', 0), 0);
    
    % Calculate power at optimal pitch
    P_opt = param.rho/2.0 * param.Arot * param.vwind^3 * cp_opt;
    
    % Determine pitch reference
    if P_opt <= param.power_max
        % Below rated power: use optimal pitch for maximum power extraction
        P = P_opt;
        theta_ref = theta_opt;
    else
        % Above rated power: find pitch angle to limit power to rated value
        P = param.power_max;
        
        % Target power coefficient to achieve rated power
        cp_target = param.power_max / (param.rho/2.0 * param.Arot * param.vwind^3);
        theta_ref = fminbnd(@(theta) (interp2(param.lambda, param.theta, param.cp, lam, theta, 'linear', 0) - cp_target)^2, theta_min, theta_max);
    end
    
    % Calculate torque from rated or optimal power
    Tgen_ref = P / om_rot_ref / param.GBRatio;
end
