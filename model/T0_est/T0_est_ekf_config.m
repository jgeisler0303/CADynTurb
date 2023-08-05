function ekf_config= T0_est_ekf_config
model_indices
ekf_config.x_ul= [
                40; % wind speed

                
                50/30*pi; % rotor speed
                ];                
ekf_config.x_ll= [ 
                2; % wind speed
               
                0; % rotor speed
                ];                 
                
ekf_config.estimated_states= [
    vwind_idx
    phi_rot_d_idx
    ];
ekf_config.n_estimated_dofs= 1;

ekf_config.out_idx= [out_gen_speed_idx];

ekf_config.x_scaling= ones(length(ekf_config.estimated_states), 1);
