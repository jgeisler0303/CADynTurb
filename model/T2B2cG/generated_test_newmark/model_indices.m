% File generated form template cadyn_indices.m.tem on 2023-08-04 09:37:42+02:00. Do not edit!
% Multibody system: Simulation of a simplified horizontal axis wind turbine


nq = 6;
nx = 2*6;
nu = 3;
ny = 7;

tow_fa_idx= 1;
tow_ss_idx= 2;
bld_flp_idx= 3;
bld_edg_idx= 4;
phi_rot_idx= 5;
phi_gen_idx= 6;

tow_fa_d_idx= 7;
tow_ss_d_idx= 8;
bld_flp_d_idx= 9;
bld_edg_d_idx= 10;
phi_rot_d_idx= 11;
phi_gen_d_idx= 12;

in_vwind_idx= 1;
in_Tgen_idx= 2;
in_theta_idx= 3;

out_tow_fa_acc_idx= 1;
out_tow_ss_acc_idx= 2;
out_gen_speed_idx= 3;
out_bld_flp_acc_idx= 4;
out_bld_edg_acc_idx= 5;
out_bld_edg_mom_idx= 6;
out_bld_flp_mom_idx= 7;

dof_names= {
    'tow_fa'
    'tow_ss'
    'bld_flp'
    'bld_edg'
    'phi_rot'
    'phi_gen'
};

dof_d_names= {
    'tow_fa_d'
    'tow_ss_d'
    'bld_flp_d'
    'bld_edg_d'
    'phi_rot_d'
    'phi_gen_d'
};

state_names= {
    'tow_fa'
    'tow_ss'
    'bld_flp'
    'bld_edg'
    'phi_rot'
    'phi_gen'
    'tow_fa_d'
    'tow_ss_d'
    'bld_flp_d'
    'bld_edg_d'
    'phi_rot_d'
    'phi_gen_d'
};

input_names= {
    'vwind'
    'Tgen'
    'theta'
};

output_names= {
    'tow_fa_acc'
    'tow_ss_acc'
    'gen_speed'
    'bld_flp_acc'
    'bld_edg_acc'
    'bld_edg_mom'
    'bld_flp_mom'
};
