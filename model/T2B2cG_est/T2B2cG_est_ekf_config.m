function ekf_config= T2B2cG_est_ekf_config
model_indices
ekf_config.x_ul= [  2;                  % tower FA deflection
                1;                  % tower SS deflection
                10;                  % blade flap defelction
                3;                  % blade edge defelction
                pi;                  % generator angle offset
                40; % wind speed

                100;                  % tower FA deflection speed
                100;                  % tower SS deflection speed
                100;                  % blade flap defelction speed
                100;                  % blade edge defelction speed
                50/30*pi; % rotor speed
                50/30*pi;                  % rotor generator speed difference
                ];                
ekf_config.x_ll= [  -2;                  % tower FA deflection
                -1;                  % tower SS deflection
                -10;                  % blade flap defelction
                -3;                  % blade edge defelction
                -pi;                  % generator angle offset
                2; % wind speed

                -100;                  % tower FA deflection speed
                -100;                  % tower SS deflection speed
                -100;                  % blade flap defelction speed
                -100;                  % blade edge defelction speed
                0; % rotor speed
                -500/30*pi;                  % rotor generator speed difference
                ];                 
                
ekf_config.estimated_states= [
    tow_fa_idx
    tow_ss_idx
    bld_flp_idx
    bld_edg_idx
    Dphi_gen_idx
    vwind_idx
    tow_fa_d_idx
    tow_ss_d_idx
    bld_flp_d_idx
    bld_edg_d_idx
    phi_rot_d_idx
    Dphi_gen_d_idx
    ];
ekf_config.n_estimated_dofs= 6;

ekf_config.out_idx= [out_tow_fa_acc_idx, out_tow_ss_acc_idx, out_gen_speed_idx];

ekf_config.x_scaling= ones(length(ekf_config.estimated_states), 1);
