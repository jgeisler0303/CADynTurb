#ifndef DISCON_SWAP_H_
#define DISCON_SWAP_H_

#define avr_size 256

typedef struct { union {
    float swap[avr_size];
    struct {
        float sim_status;       // 1, in, int, 0= first call at time zero, 1= all subsequent timesteps, -1= final call at the end of the simulation, 2= real time update step, dll may set value to -1 to request termination
        float current_time;     // 2, in, float, s
        float comm_interval;    // 3, in, float, s
        float blade1_pitch;     // 4, in, float, rad
        float sp_pitch_partial; // 5, in, float, rad
        float min_pitch;        // 6, in, float, rad
        float max_pitch;        // 7, in, float, rad
        float min_pitch_rate;   // 8, in, float, rad/s
        float max_pitch_rate;   // 9, in, float, rad/s
        float pitch_actuator;   // 10, in, int, - 0= position, 1=rate
        float pitch_dem;        // 11, in, float, rad
        float pitch_rate_dem;   // 12, in, float, rad/s
        float power_dem;        // 13, in, float, W
        float shaft_power_meas; // 14, in, float, W
        float power_out_meas;   // 15, in, float, W
        float opt_mode_gain;    // 16, in, float, Nm/(rad/s)^2, zero if ts-lookup is used, see rec. 25
        float min_gen_speed;    // 17, in, float, rad/s
        float max_gen_speed;    // 18, in, float, rad/s
        float gen_speed_dem;    // 19, in, float, rad/s
        float gen_speed_meas;   // 20, in, float, rad/s
        float rot_speed_meas;   // 21, in, float, rad/s
        float gen_torque_sp;   // 22, in, float, Nm
        float gen_torque_meas;  // 23, in, float, Nm
        float yaw_error_meas;   // 24, in, float, rad
        float ts_lut_idx;       // 25, in, int, -
        float ts_lut_len;       // 26, in, int, -
        float wind_speed_hub;   // 27, in, float, m/s
        float pitch_ctrl_mode;  // 28, in, int, - 0= collective, 1= individual
        float yaw_ctrl_mode;    // 29, in, int, - 0= yaw rate control, 1= yaw torque
        float blade1_oop_moment;// 30, in, float, Nm
        float blade2_oop_moment;// 31, in, float, Nm
        float blade3_oop_moment;// 32, in, float, Nm
        float blade2_pitch;     // 33, in, float, rad
        float blade3_pitch;     // 34, in, float, rad
        float gen_contractor;   // 35, io, int, -, 0= off, 1= main (high speed) or variable speed generator, 2= low speed generator
        float shaft_brake_status;// 36, io, int, - 0= off, 1= brake 1 on; for additional brakes this is a binary number: bit 0= shaft brake 1, bit 1= shaft brake 2, bit 2= generator brake, bit 3= shaft brake 3, bit 4= brake torque in rec. 107
        float abs_yaw;          // 37, in, float, rad
        float reserved1;        // 38, out
        float reserved2;        // 39, out
        float reserved3;        // 40, out
        float yaw_torque_dem;   // 41, out, float, Nm, depends on rec. 29
        float blade1_dem;       // 42, out, float, rad or rad/s, depends on rec. 28 and 10
        float blade2_dem;       // 43, out, float, rad or rad/s, depends on rec. 28 and 10
        float blade3_dem;       // 44, out, float, rad or rad/s, depends on rec. 28 and 10
        float pitch_coll_dem;   // 45, out, float, rad, depends on rec. 28
        float pitch_coll_rate_dem; // 46, out, float, rad/s, depends on rec. 28
        float gen_torque_dem;   // 47, out, float, Nm
        float yaw_rate_dem;     // 48, out, float, rad/s, depends on rec. 29
        float max_msg_char;     // 49, in, int, -
        float infile_len;       // 50, in, int, -
        float outfile_len;      // 51, in, int, -
        float version;          // 52, in, int, -
        float f_a_acc;          // 53, in, float, m/s^2
        float s_s_acc;          // 54, in, float, m/s^2
        float pitch_override;   // 55, out, int, -, 0= dll controls pitch
        float torque_override;  // 56, out, int, -
        float reserved4;        // 57, out
        float reserved5;        // 58, out
        float reserved6;        // 59, out
        float rotor_pos;        // 60, in, float, rad
        float num_blades;       // 61, in, int, -
        float logging_max;      // 62, in, int, -
        float logging_idx;      // 63, in, int, -
        float outfile_max;      // 64, in, int, -
        float logging_len;      // 65, out, int, -
        float reserved7;        // 66, in
        float reserved8;        // 67, in
        float reserved9;        // 68, in
        float blade1_ip_moment; // 69, in, float, Nm
        float blade2_ip_moment; // 70, in, float, Nm
        float blade3_ip_moment; // 71, in, float, Nm
        float gen_start_resist; // 72, out, float, ohm/phase
        float my_hub_r;         // 73, in, float, Nm
        float mz_hub_r;         // 74, in, float, Nm
        float my_hub_f;         // 75, in, float, Nm
        float mz_hub_f;         // 76, in, float, Nm
        float my_yaw;           // 77, in, float, Nm
        float mz_yaw;           // 78, in, float, Nm
        float load_meas_request;// 79, out, int, -, 0= nothing extra, 1= blade loads and accelerations, 2= 1 + hub rotating loads, 3= 2 + hub fixed loads, 4= 3 + yaw loads
        float var_slip_current; // 80, out, int, 1= var slip demand at pos 81, 0= default= torque demand in rec. 47
        float var_slip;         // 81, io, float, A
        float nac_roll_acc;     // 82, in, float, rad/s^2
        float nac_node_acc;     // 83, in, float, rad/s^2
        float nac_yaw_acc;      // 84, in, float, rad/s^2
        float reserved10;       // 85
        float reserved11;       // 86
        float reserved12;       // 87
        float reserved13;       // 88
        float reserved14;       // 89
        float real_time_sim_step; // 90, in, float, s, for real time simulation control
        float real_time_sim_fact; // 91, in, float, -, for real time simulation control
        float mean_wind_inc;    // 92, out, float, m/s, for real time simulation control
        float ti_inc;           // 93, out, float, %, for real time simulation control
        float wind_dir_inc;     // 94, out, float, rad, for real time simulation control
        float reserved15;       // 95
        float reserved16;       // 96
        float safety_code;      // 97, in, int, -
        float safety_code_dem;  // 98, out, int, -
        float reserved17;       // 99, in, int
        float reserved18;       // 100, in, int
        float reserved19;       // 101, in, float
        float yaw_ctrl_flag;    // 102, out, int, 0= default: rec. 48 sets the yaw rate demand, 1= as 0 but change the linear yaw stiffness according to  rec. 103, 2= as 0 but change the yaw damping according to  rec. 104, 3= as 1 but change the yaw damping according to  rec. 104, 4= use rec. 41 to override the yaw spring damper
        float yaw_stiff;        // 103, out, float, - if rec 102= 1 or 3
        float yaw_damp;         // 104, out, float, - if rec 102= 1 or 3
        float reserved20;       // 105, in, float
        float reserved21;       // 106, in, float
        float brake_torque_dem; // 107, out, float, Nm
        float yaw_brake_dem;    // 108, out, float, Nm
        float shaft_torque;     // 109, in, float, Nm
        float fx_hub_f;         // 110, in, float, N
        float fy_hub_f;         // 111, in, float, N
        float fz_hub_f;         // 112, in, float, N
        float grid_volt_fact;   // 113, in float, -
        float grid_freq_fact;   // 114, in float, -
        float reserved22;       // 115
        float reserved23;       // 116
        float controller_state; // 117, in, int, 0= power production, 1= parked, 2= ideling, 3= startup, 4= normal stop, 5= emergency stop
        float time_to_output;   // 118, in, float, s
        float reserved24;       // 119
        float user_var_1;       // 120, io, float
        float user_var_2;       // 121, io, float
        float user_var_3;       // 122, io, float
        float user_var_4;       // 123, io, float
        float user_var_5;       // 124, io, float
        float user_var_6;       // 125, io, float
        float user_var_7;       // 126, io, float
        float user_var_8;       // 127, io, float
        float user_var_9;       // 128, io, float
        float user_var_10;      // 129, io, float
        float reserved25;       // 130
        float reserved26;       // 131
        float reserved27;       // 132
        float reserved28;       // 133
        float reserved29;       // 134
        float reserved30;       // 135
        float reserved31;       // 136
        float reserved32;       // 137
        float reserved33;       // 138
        float reserved34;       // 139
        float reserved35;       // 140
        float reserved36;       // 141
        float reserved37;       // 142
        float teeter_angle;     // 143, in, float, rad
        float teeter_speed;     // 144, in, float, rad/s
        float reserved38;       // 145
        float reserved39;       // 146
        float reserved40;       // 147
        float reserved41;       // 148
        float reserved42;       // 149
        float reserved43;       // 150
        float reserved44;       // 151
        float reserved45;       // 152
        float reserved46;       // 153
        float reserved47;       // 154
        float reserved48;       // 155
        float reserved49;       // 156
        float reserved50;       // 157
        float reserved51;       // 158
        float reserved52;       // 159
        float reserved53;       // 160
        float controller_failure; // 161, in, int
        float yaw_angle;        // 162, in, float, rad
        float yaw_speed;        // 163, in, float, rad/s
        float yaw_acc;          // 164, in, float, rad/s^2
        float log[avr_size-164];
    };
};} avrSwap_t;

#endif /* DISCON_SWAP_H_ */
