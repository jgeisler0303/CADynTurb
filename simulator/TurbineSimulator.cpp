#include <iostream>
#include <stdlib.h>
#include <chrono>
#include <cstdio>
#include <ctime>
#include <cmath>
#include <cxxopts.hpp>
#include "discon_interface.h"
#include "fast_output.h"
#include "fast_parameters.h"
#include "fast_wind.h"

#include "turbine_coll_flap_edge_pitch_aeroSystem2.hpp"

bool simulate(turbine_coll_flap_edge_pitch_aeroSystem &system, FAST_Wind* wind, double ts, double tfinal, const std::string &discon_path, const std::string &out_file_name);
bool DISCON_Step(double t, DISCON_Interface &DISCON, turbine_coll_flap_edge_pitch_aeroSystem &system);

double RotPwr;
double HSShftPwr;
double wind_adjust;

int main(int argc, char* argv[]) {
    turbine_coll_flap_edge_pitch_aeroSystem system;
    FAST_Wind* wind;
    
    cxxopts::Options argc_options("TurbineSimulator", "A simple wind turbine simulator");
    argc_options.add_options()
    // ("i,icfile", "Initial conditions file name", cxxopts::value<std::string>()->default_value("./icfile.txt"))
    ("p,paramfile", "Parameter file name", cxxopts::value<std::string>()->default_value("./params.txt"))
    ("t,simtime", "Simulation time", cxxopts::value<double>()->default_value("10.0"))
    ("s,simstep", "Simulation time", cxxopts::value<double>()->default_value("0.01"))
    ("w,vwind", "Inflow wind definition file name", cxxopts::value<std::string>()->default_value("Inflow.dat"))
    ("d,discon_dll", "Path and name of the DISCON controller DLL", cxxopts::value<std::string>()->default_value("./discon.dll"))
    ("o,output", "Output file name", cxxopts::value<std::string>()->default_value("sim_output.outb"))
    ("a,adjust_wind", "Adjustment factor for wind speed", cxxopts::value<double>()->default_value("1.0"))
    ;
    
    auto argc_result = argc_options.parse(argc, argv);

//     {   
//         std:string ic_file_name= argc_result["icfile"].as<std::string>();
//         std::ifstream ic_file(ic_file_name);
//         
//         for(int i= 0; i<6; ++i) {
//             ic_file >> system.q(i);
//             if(ic_file.fail()) {
//                 std::cout << "Not all initial conditions could be read from file \"" << ic_file_name << "\"" << std::endl;
//                 exit (EXIT_FAILURE);
//             }
//         }
//         for(int i= 0; i<6; ++i) {
//             ic_file >> system.qd(i);
//             if(ic_file.fail()) {
//                 std::cout << "Not all initial conditions could be read from file \"" << ic_file_name << "\"" << std::endl;
//                 exit (EXIT_FAILURE);
//             }
//         }
//     }
    
    try {
        system.param.setFromFile(argc_result["paramfile"].as<std::string>());
    } catch (const std::exception& e) {
        fprintf(stderr, "Parameter file error: %s\n", e.what());
        exit (EXIT_FAILURE);
    }
    if(system.param.unsetParamsWithMsg()) {
        fprintf(stderr, "\nAll parameters have to be set. Exiting.\n");
        exit (EXIT_FAILURE);            
    }
    
    try {
        FAST_Parameters p(argc_result["vwind"].as<std::string>());
        wind= makeFAST_Wind(p);
    } catch (const std::exception& e) {
        fprintf(stderr, "Inflow error: %s\n", e.what());
        exit (EXIT_FAILURE);
    }
    
    
    {
        wind_adjust= argc_result["adjust_wind"].as<double>();
        std::clock_t startcputime = std::clock();
        bool res= simulate(system,
                           wind,
                           argc_result["simstep"].as<double>(),
                           argc_result["simtime"].as<double>(),
                           argc_result["discon_dll"].as<std::string>(),
                           argc_result["output"].as<std::string>());
        double cpu_duration = (std::clock() - startcputime) / (double)CLOCKS_PER_SEC;

        if(!res) {
            std::cerr << "Error in integrator" << std::endl;
            exit (EXIT_FAILURE);
        }
        
        std::cout << "Run-time of integrator: " << cpu_duration << " seconds" << std::endl;
    }
    
    delete wind;
    
    exit (EXIT_SUCCESS);
}

void setupOutputs(FAST_Output &out, turbine_coll_flap_edge_pitch_aeroSystem &system) {
    out.addChannel("Q_BF1", "m", &system.q.data()[3]);
    out.addChannel("Q_BE1", "m", &system.q.data()[4]);
//     out.addChannel("TipDxb", "m", &system.q.data()[3]*blade_frame_49_phi0_1_1 + &system.q.data()[4]);
//     out.addChannel("TipDyb", "m", &system.q.data()[4]);
    out.addChannel("PtchPMzc", "deg", &system.theta_deg);
    out.addChannel("LSSTipPxa", "deg", &system.q.data()[2], 180.0/M_PI);
    out.addChannel("LSSTipVxa", "rpm", &system.qd.data()[2], 30.0/M_PI);
    out.addChannel("LSSTipAxa", "deg/s^2", &system.qdd.data()[2], 180.0/M_PI);
    out.addChannel("HSShftV", "rpm", &system.qd.data()[5], 30.0/M_PI);
    out.addChannel("HSShftA", "deg/s^2", &system.qdd.data()[2], 180.0/M_PI);
    out.addChannel("YawBrTDxp", "m", &system.q.data()[0]);
    out.addChannel("YawBrTDyp", "m", &system.q.data()[1]);
    out.addChannel("YawBrTAxp", "m/s^2", &system.qdd.data()[0]);
    out.addChannel("YawBrTAyp", "m/s^2", &system.qdd.data()[1]);
//    out.addChannel("YawBrRDyt", "deg", &system.q.data()[0], system.param.TwTrans2Roll*180.0/M_PI);
//    out.addChannel("YawBrRDxt", "deg", &system.q.data()[1], system.param.TwTrans2Roll*180.0/M_PI);
//    out.addChannel("YawBrRVyp", "deg/s", &system.qd.data()[0], system.param.TwTrans2Roll*180.0/M_PI);
//    out.addChannel("YawBrRVxp", "deg/s", &system.qd.data()[1], system.param.TwTrans2Roll*180.0/M_PI);
    out.addChannel("RootFxc", "kN", &system.Fthrust, 1.0/3000.0);
    out.addChannel("RootMxc", "kNm", &system.Trot, 1.0/3000.0);
    out.addChannel("LSShftFxa", "kN", &system.Fthrust, 1.0/1000.0);
    out.addChannel("LSShftMxa", "kNm", &system.Trot, 1.0/1000.0);
    out.addChannel("RotPwr", "kW", &RotPwr, 1.0/1000.0);
    out.addChannel("HSShftTq", "kNm", &system.u.data()[1], 1.0/1000.0);
    out.addChannel("HSShftPwr", "kW", &HSShftPwr, 1.0/1000.0);
    out.addChannel("WindVxi", "m/s", &system.u.data()[0]);
    out.addChannel("RtTSR", "-", &system.lam);
    out.addChannel("RtAeroCq", "-", &system.cm);
    out.addChannel("RtAeroCt", "-", &system.ct);
    out.addChannel("RotCf", "-", &system.cflp);
    out.addChannel("RotCe", "-", &system.cedg);
    out.addChannel("BlPitchC", "deg", &system.u.data()[2],  -180.0/M_PI);
    out.addChannel("GenTq", "kNm", &system.u.data()[1], 1.0/1000.0);
    out.addChannel("RootMxb", "-", &system.modalFlapForce);
    out.addChannel("RootMyb", "-", &system.modalEdgeForce);
}

bool simulate(turbine_coll_flap_edge_pitch_aeroSystem &system, FAST_Wind* wind, double ts, double tfinal, const std::string &discon_path, const std::string &out_file_name) {
    FAST_Output out(tfinal/ts+1);
    out.setTime(0.0, ts);
    setupOutputs(out, system);
    
    system.t= 0.0;

    system.u(0)= wind_adjust*wind->getWind(system.t);
    system.u(1)= 10000; // TODO
    system.u(2)= 0;
    
    system.q(5)= system.u(1)*system.param.GBRatio/system.param.DTTorSpr;
    system.qd(5)= 1000.0/30.0*M_PI; // TODO
    system.q(2)= 0.0;
    system.qd(2)= system.qd(5)/system.param.GBRatio;
    
    system.doflocked[2]= true;
    system.doflocked[5]= true;
    
    if(!system.staticEquilibrium())
        printf("Static equilibrium could not be found\n");
    
    system.doflocked[2]= false;
    system.doflocked[5]= false;
    
    
    DISCON_Interface DISCON(discon_path);
    
    DISCON.comm_interval= ts;
    DISCON.wind_speed_hub= system.u(0);
    DISCON.min_pitch= 0.0;
    DISCON.max_pitch= 1.57;
    DISCON.min_pitch_rate= -0.15;
    DISCON.max_pitch_rate= 0.15;
    DISCON.pitch_actuator= 0;
    DISCON.opt_mode_gain= 1;
    DISCON.min_gen_speed= 83; // TODO
    DISCON.max_gen_speed= 188;
    DISCON.gen_speed_dem= 188;
    DISCON.gen_torque_sp= 40000;
    DISCON.gen_torque_meas= system.u(1);
    DISCON.rot_speed_meas= system.qd(2);
    DISCON.gen_speed_meas= system.qd(5);
    DISCON.power_out_meas= DISCON.gen_speed_meas * DISCON.gen_torque_meas;
    
    DISCON.sp_pitch_partial= 0;
    DISCON.ts_lut_idx= 0;
    DISCON.ts_lut_len= 0;
    DISCON.yaw_ctrl_mode= 0;
    DISCON.yaw_error_meas= 0;
    DISCON.abs_yaw= 0;

    DISCON.num_blades= 3;
    DISCON.pitch_ctrl_mode= 0;
    DISCON.gen_contractor= 1;
    DISCON.shaft_brake_status= 0;
    DISCON.controller_state= 0;
    DISCON.time_to_output= 0;
    DISCON.pitch_dem= 0;
    DISCON.setOutfile("discon.out");
   
    if(DISCON.init())
        printf("%s\n", DISCON.getMessage().c_str());
    
    // printf("load_meas_request: %d\n", (int)DISCON.load_meas_request);
    

    printf("Starting simulation\n");
    system.newmarkOneStep(0.0);
    out.collectData();
    
    int ipas= 0;
    bool res= true;
    double h= ts;
    while(system.t<tfinal)    {
        if(!DISCON_Step(ts*ipas, DISCON, system)) {
            printf("DISCON finished at t= %f\n", ts*ipas);
            res= false;
            break;
        }
        
        ipas++;
        system.u(0)= wind_adjust*wind->getWind(system.t);
        if(!system.newmarkInterval(ts*ipas, h, ts)) {
            res= false;
            break;
        }
        
        RotPwr= system.Trot*system.qd(2);
        HSShftPwr= system.u(1)*system.qd(5);
        out.collectData();
    }
    printf("Simulation done\n");
    out.write(out_file_name, "Output of TurbineSimulator simulation");
    
    if(DISCON.finish())
        printf("%s\n", DISCON.getMessage().c_str());

    return res;
}

bool DISCON_Step(double t, DISCON_Interface &DISCON, turbine_coll_flap_edge_pitch_aeroSystem &system) {
    DISCON.current_time= t;
    
    DISCON.wind_speed_hub= system.u(0);
    DISCON.yaw_error_meas= 0;
    DISCON.abs_yaw= 0;
    DISCON.gen_torque_meas= system.u(1);
    DISCON.rot_speed_meas= system.qd(2);
    DISCON.gen_speed_meas= system.qd(5);
    DISCON.power_out_meas= DISCON.gen_speed_meas * DISCON.gen_torque_meas;
    
    DISCON.blade1_pitch= -system.u(2);
    DISCON.blade2_pitch= -system.u(2);
    DISCON.blade3_pitch= -system.u(2);
    
    DISCON.f_a_acc= system.qdd(0);
    DISCON.s_s_acc= system.qdd(1);
    
    DISCON.rotor_pos= system.q(2);
    
    DISCON.blade1_oop_moment= 0;
    DISCON.blade2_oop_moment= 0;
    DISCON.blade3_oop_moment= 0;
    DISCON.blade1_ip_moment= 0;
    DISCON.blade2_ip_moment= 0;
    DISCON.blade3_ip_moment= 0;
    
    
//     DISCON.shaft_torque
//     DISCON.fx_hub_f
//     DISCON.fy_hub_f
//     DISCON.fz_hub_f
    
    if(DISCON.run())
        printf("%s\n", DISCON.getMessage().c_str());
    
//     system.u(2)= -(1.0/3.0)*(DISCON.blade1_dem + DISCON.blade2_dem + DISCON.blade3_dem);
    system.u(2)= -DISCON.pitch_coll_dem;
    system.u(1)= DISCON.gen_torque_dem;
    
    if(((int)DISCON.safety_code_dem) != 0)
        printf("safety_code_dem: %f\n", DISCON.safety_code_dem);
    
    return DISCON.sim_status!=-1;
}
