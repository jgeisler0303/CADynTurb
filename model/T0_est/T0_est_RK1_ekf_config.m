function ekf_config= T0_est_RK1_ekf_config

ekf_config.x_ul= [
                50/30*pi; % rotor speed
                40; % wind speed
                ];                
ekf_config.x_ll= [ 
                0; % rotor speed
                2; % wind speed
                ];           
