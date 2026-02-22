function ekf_config= T1_est_RK1_ekf_config

ekf_config.x_ul= [
    2;          % tower FA deflection
    100;        % tower FA deflection speed
    50/30*pi;   % rotor speed
    40;         % wind speed
                ];                
ekf_config.x_ll= [
    -2;         % tower FA deflection
    -100;       % tower FA deflection speed
    0;          % rotor speed
    2;          % wind speed
                ];                 
