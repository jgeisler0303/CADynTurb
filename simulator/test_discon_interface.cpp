#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <stdint.h>
#include <cstring>
#include "discon_interface.h"
#include "fast_parameters.h"

int main(void) {
    DISCON_Interface DISCON;
     
    DISCON.comm_interval= 0.01;
    DISCON.min_pitch= 0.0;
    DISCON.max_pitch= 1.57;
    DISCON.min_pitch_rate= -0.15;
    DISCON.max_pitch_rate= 0.15;
    DISCON.pitch_actuator= 0;
    DISCON.opt_mode_gain= 1;
    DISCON.min_gen_speed= 83;
    DISCON.max_gen_speed= 188;
    DISCON.gen_speed_dem= 188;
    DISCON.gen_speed_meas= 188;
    DISCON.rot_speed_meas= 18.1;
    DISCON.gen_torque_sp= 20000;
    DISCON.gen_torque_meas= 20000;
    DISCON.ts_lut_idx= 0;
    DISCON.ts_lut_len= 0;
    DISCON.wind_speed_hub= 10;
    DISCON.pitch_ctrl_mode= 0;
    DISCON.yaw_ctrl_mode= 0;
    DISCON.num_blades= 3;
    
    if(DISCON.init())
        printf("%s\n", DISCON.getMessage().c_str());
    
    if(DISCON.run())
        printf("%s\n", DISCON.getMessage().c_str());
    
    if(DISCON.finish())
        printf("%s\n", DISCON.getMessage().c_str());
    
    
    FAST_Parameters p("/home/jgeisler/Projekte/Research/CADynTurb/5MW_Baseline/NRELOffshrBsline5MW_Onshore_ServoDyn.dat");
    std::cout << p;
    
    exit(EXIT_SUCCESS);
}
