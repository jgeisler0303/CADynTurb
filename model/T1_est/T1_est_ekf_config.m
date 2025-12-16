function ekf_config= T1_est_ekf_config
model_indices
ekf_config.x_ul= [  2;                  % tower FA deflection
                40; % wind speed

                100;                    % tower FA deflection speed
                50/30*pi; % rotor speed
                ];                
ekf_config.x_ll= [  -2;                  % tower FA deflection
                2; % wind speed
                -100;                    % tower FA deflection speed
                0; % rotor speed
                ];                 
                
ekf_config.estimated_states= [
    tow_fa_idx
    vwind_idx
    tow_fa_d_idx
    phi_rot_d_idx
    ];
ekf_config.n_estimated_dofs= 2;

ekf_config.out_idx= [out_tow_fa_acc_idx, out_gen_speed_idx];

ekf_config.x_scaling= ones(length(ekf_config.estimated_states), 1);
