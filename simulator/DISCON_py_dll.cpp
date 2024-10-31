// compile g++ -D_USE_MATH_DEFINES -shared DISCON_py_dll.cpp -o DISCON_py_dll.dll
 
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "discon_interface.h"

#ifdef _WIN32
    #define DECLSPEC __declspec(dllexport) 
#else
    #define DECLSPEC
#endif

// global variable for DISCON dll
DISCON_Interface* DISCON= nullptr;

void DISCON_Step(DISCON_Interface& DISCON, double &theta_out, double &Tgen_out, int &sim_status, double t, double vwind, double Tgen_in, double om_rot, double om_gen, double theta_in, double tow_fa_acc, double tow_ss_acc, double phi_rot);

extern "C" {

DECLSPEC void init(const char *discon_path) {
    if(DISCON!=nullptr) {
        printf("DISCON already loaded.\n");
        return;
    }
    try {
        DISCON= new DISCON_Interface(std::string(discon_path));
            
        // hard coded DISCON parameters
        DISCON->comm_interval= 0.01;
        DISCON->min_pitch= 0/180.0*M_PI;;
        DISCON->max_pitch= 90/180.0*M_PI;;
        DISCON->min_pitch_rate= -15/180.0*M_PI;;
        DISCON->max_pitch_rate= 15/180.0*M_PI;;
        DISCON->pitch_actuator= 0;
        DISCON->opt_mode_gain= 1;
        DISCON->min_gen_speed= 800/30.0*M_PI;;
        DISCON->max_gen_speed= 1200/30.0*M_PI;;
        DISCON->gen_speed_dem= 1200/30.0*M_PI;;
        DISCON->gen_torque_sp= 40000;
        DISCON->power_dem= 0;
        DISCON->sp_pitch_partial= 0/180.0*M_PI;;
        DISCON->yaw_ctrl_mode= 0;
        DISCON->num_blades= 3;
        DISCON->pitch_ctrl_mode= 0;
        DISCON->gen_contractor= 1;
        DISCON->controller_state= 0;
        DISCON->time_to_output= 0;
        DISCON->version= 0.0;
        
        DISCON->ts_lut_idx= 0;
        DISCON->ts_lut_len= 0;

        if(DISCON->init())
            printf("Init DISCON: %s\n", DISCON->getMessage().c_str());
        
    } catch (const std::exception& e) {
        printf("DISCON Error: %s\n", e.what());
        return;
    }
}

DECLSPEC void terminate() {
    if(DISCON==nullptr) {
        printf("DISCON currently not loaded.\n");
        return;
    }
    if(DISCON->finish())
        printf("DISCON message: %s\n", DISCON->getMessage().c_str());
    
    delete DISCON;
    DISCON= nullptr;
}

DECLSPEC void step(const double t, const double vwind, const double Tgen_in, const double om_rot, const double om_gen, const double theta_in, const double tow_fa_acc, const double tow_ss_acc, const double phi_rot, double *theta_out, double *Tgen_out, int *sim_status) {
    if(DISCON==nullptr) {
        printf("DISCON currently not loaded.\n");
        return;
    }
    try {
        DISCON_Step(*DISCON, *theta_out, *Tgen_out, *sim_status, t, vwind, Tgen_in, om_rot, om_gen, theta_in, tow_fa_acc, tow_ss_acc, phi_rot);
    } catch (const std::exception& e) {
        printf("DISCON Error: %s\n", e.what());
        return;
    }
}

} // extern "C"

void DISCON_Step(DISCON_Interface& DISCON, double &theta_out, double &Tgen_out, int &sim_status, double t, double vwind, double Tgen_in, double om_rot, double om_gen, double theta_in, double tow_fa_acc, double tow_ss_acc, double phi_rot) {
    DISCON.current_time= t;
    
    DISCON.wind_speed_hub= vwind;
    DISCON.yaw_error_meas= 0;
    DISCON.abs_yaw= 0;
    DISCON.gen_torque_meas= Tgen_in;
    DISCON.rot_speed_meas= om_rot;
    DISCON.gen_speed_meas= om_gen;
    DISCON.power_out_meas= DISCON.gen_speed_meas * DISCON.gen_torque_meas;
    
    DISCON.blade1_pitch= theta_in;
    DISCON.blade2_pitch= theta_in;
    DISCON.blade3_pitch= theta_in;
    DISCON.pitch_dem= 0;
    
    DISCON.f_a_acc= tow_fa_acc;
    DISCON.s_s_acc= tow_ss_acc;
    
    DISCON.rotor_pos= phi_rot;
    
    DISCON.blade1_oop_moment= 0;
    DISCON.blade2_oop_moment= 0;
    DISCON.blade3_oop_moment= 0;
    DISCON.blade1_ip_moment= 0;
    DISCON.blade2_ip_moment= 0;
    DISCON.blade3_ip_moment= 0;
    DISCON.shaft_brake_status= 0; // 0= off, 1= brake 1 on
    
    DISCON.grid_volt_fact= 1.0;
    DISCON.grid_freq_fact= 1.0;
//     DISCON.shaft_torque
//     DISCON.fx_hub_f
//     DISCON.fy_hub_f
//     DISCON.fz_hub_f
    
    if(DISCON.run())
        printf("%s\n", DISCON.getMessage().c_str());
    
//     system.inputs.theta= -(1.0/3.0)*(DISCON.blade1_dem + DISCON.blade2_dem + DISCON.blade3_dem);
    theta_out= DISCON.pitch_coll_dem;
    Tgen_out= DISCON.gen_torque_dem;
    
    if(((int)DISCON.safety_code_dem) != 0)
        printf("safety_code_dem: %f\n", DISCON.safety_code_dem);
    
    sim_status=  DISCON.sim_status;
    
    // printf("theta: %f, Tgen: %f\n", theta_out, Tgen_out);
}
