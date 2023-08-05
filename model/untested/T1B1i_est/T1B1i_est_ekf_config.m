function ekf_config= T1B1i_est_ekf_config
model_indices

ekf_config.x_ul= [  2;                  % tower FA deflection
                10;                  % blade flap1 defelction
                10;                  % blade flap2 defelction
                10;                  % blade flap3 defelction
                inf;                 % rotor angle
                40; % wind speed
                4; % h_shear
                4; % v_shear

                100;                  % tower FA deflection speed
                100;                  % blade flap1 defelction speed
                100;                  % blade flap2 defelction speed
                100;                  % blade flap3 defelction speed
                50/30*pi; % rotor speed
                ];                
ekf_config.x_ll= [  -2;                  % tower FA deflection
                -10;                  % blade flap1 defelction
                -10;                  % blade flap2 defelction
                -10;                  % blade flap3 defelction
                -inf;                 % rotor angle
                2; % wind speed
                -4; % h_shear
                -4; % v_shear

                -100;                  % tower FA deflection speed
                -100;                  % blade flap1 defelction speed
                -100;                  % blade flap2 defelction speed
                -100;                  % blade flap3 defelction speed
                0.01; % rotor speed
                ];                 
                
ekf_config.estimated_states= [
    tow_fa_idx
    bld1_flp_idx
    bld2_flp_idx
    bld3_flp_idx
    phi_rot_idx
    vwind_idx
    h_shear_idx
    v_shear_idx
    
    tow_fa_d_idx
    bld1_flp_d_idx
    bld2_flp_d_idx
    bld3_flp_d_idx
    phi_rot_d_idx
    ];
ekf_config.n_estimated_dofs= 8;

ekf_config.out_idx= [out_tow_fa_acc_idx, out_rot_speed_idx, out_bld1_flp_mom_idx, out_bld1_edg_mom_idx, out_bld2_flp_mom_idx, out_bld2_edg_mom_idx, out_bld3_flp_mom_idx, out_bld3_edg_mom_idx];

ekf_config.x_scaling= ones(length(ekf_config.estimated_states), 1);
