function ekf_config= T1B1cG_est_ekf_config
model_indices
ekf_config.x_ul= [  2;                  % tower FA deflection
                10;                  % blade flap defelction
                pi;                  % generator angle offset
                40; % wind speed

                100;                  % tower FA deflection speed
                100;                  % blade flap defelction speed
                50/30*pi; % rotor speed
                50/30*pi;                  % rotor generator speed difference
                ];                
ekf_config.x_ll= [  -2;                  % tower FA deflection
                -10;                  % blade flap defelction
                -pi;                  % generator angle offset
                2; % wind speed

                -100;                  % tower FA deflection speed
                -100;                  % blade flap defelction speed
                0; % rotor speed
                -500/30*pi;                  % rotor generator speed difference
                ];                 
                
ekf_config.estimated_states= [
    tow_fa_idx
    bld_flp_idx
    Dphi_gen_idx
    vwind_idx
    tow_fa_d_idx
    bld_flp_d_idx
    phi_rot_d_idx
    Dphi_gen_d_idx
    ];
ekf_config.n_estimated_dofs= 4;

ekf_config.out_idx= [out_tow_fa_acc_idx, out_gen_speed_idx];

ekf_config.x_scaling= ones(length(ekf_config.estimated_states), 1);
