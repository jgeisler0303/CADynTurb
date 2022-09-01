#include <iostream>
#include <stdlib.h>
#include <chrono>
#include <cstdio>
#include <ctime>
#include <cmath>
#include <cxxopts.hpp>
#include "discon_interface.h"
#include "fast_output.h"
#include "fast_parent_param.h"
#include "fast_wind.h"

#include "turbine_T1B1cG_aero_direct.hpp"

bool simulate(turbine_T1B1cG_aeroSystem &system, FAST_Wind* wind, double ts, double tfinal, const std::string &discon_path, const std::string &out_file_name);
bool DISCON_Step(double t, DISCON_Interface &DISCON, turbine_T1B1cG_aeroSystem &system);

double RotPwr;
double HSShftPwr;
double Q_DrTr;
double QD_DrTr;
double Q_GeAz;
double LSSTipPxa;
double wind_adjust;

int main(int argc, char* argv[]) {
    turbine_T1B1cG_aeroSystem system;
    FAST_Wind* wind;
    double simtime;
    double simstep;
    std::string discon_dll;
    std::string out_name;
    
    cxxopts::Options argc_options("TurbineSimulator", "A simple wind turbine simulator");
    argc_options.add_options()
    ("p,paramfile", "Parameter file name", cxxopts::value<std::string>()->default_value("./params.txt"))
    ("t,simtime", "Simulation time", cxxopts::value<double>()->default_value("10"))
    ("s,simstep", "Simulation time", cxxopts::value<double>()->default_value("0.01"))
    ("d,discon_dll", "Path and name of the DISCON controller DLL", cxxopts::value<std::string>()->default_value("DISCON.dll"))
    ("o,output", "Output file name", cxxopts::value<std::string>()->default_value("default.outb"))
    ("a,adjust_wind", "Adjustment factor for wind speed", cxxopts::value<double>()->default_value("1.0"))
    ("c,config", "Options file for the integration algorithm (default: newmark_options.txt)", cxxopts::value<std::string>()->default_value("newmark_options.txt"))
    ("fast", "OpenFAST main input file", cxxopts::value<std::string>())
    ;
    
    argc_options.parse_positional({"fast"});
    
    auto argc_result = argc_options.parse(argc, argv);

    if(argc_result.count("config")) {
        try {
            system.setOptionsFromFile(argc_result["config"].as<std::string>());
        } catch (const std::exception& e) {
            fprintf(stderr, "Options file error: %s\n", e.what());
            exit (EXIT_FAILURE);
        }
    }
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
    
    if(argc_result.count("fast")) {
        try {
            FAST_Parent_Parameters p(argc_result["fast"].as<std::string>());

            simtime= (argc_result.count("simtime"))? argc_result["simtime"].as<double>(): p["TMax"];
            simstep= (argc_result.count("simstep"))? argc_result["simstep"].as<double>(): p["DT"];
            if(argc_result.count("output")) {
                out_name= argc_result["output"].as<std::string>();
            } else {
                out_name= argc_result["fast"].as<std::string>();
                out_name.replace(out_name.end()-3, out_name.end(), "outb");
            }
            if(argc_result.count("discon_dll")) {
                discon_dll= argc_result["discon_dll"].as<std::string>();
            } else {
                discon_dll= p.getFilename("ServoFile.DLL_FileName");
            }
            
            try {
                wind= makeFAST_Wind(p);
            } catch (const std::exception& e) {
                fprintf(stderr, "Inflow error: %s\n", e.what());
                exit (EXIT_FAILURE);
            }
        } catch (const std::exception& e) {
            fprintf(stderr, "FAST input error: %s\n", e.what());
            exit (EXIT_FAILURE);
        }
    } else {
        fprintf(stderr, "No FAST main input file was supplied\n");
        exit (EXIT_FAILURE);        
    }
    
    
    {
        wind_adjust= argc_result["adjust_wind"].as<double>();
        
        std::cout << "Simulating with options:" << std::endl;
        std::cout << "  wind_adjust=" << wind_adjust << std::endl;
        std::cout << "  simstep=" << simstep << std::endl;
        std::cout << "  simtime=" << simtime << std::endl;
        std::cout << "  discon_dll=" << discon_dll << std::endl;
        std::cout << "  output=" << out_name << std::endl;
        
        std::clock_t startcputime = std::clock();
        bool res= simulate(system,
                           wind,
                           simstep,
                           simtime,
                           discon_dll,
                           out_name);
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

void setupOutputs(FAST_Output &out, turbine_T1B1cG_aeroSystem &system) {
    out.addChannel("Q_BF1", "m", &system.states.bld_flp);
//     out.addChannel("TipDxb", "m", &system.q.data()[3]*blade_frame_49_phi0_1_1 + &system.q.data()[4]);
//     out.addChannel("TipDyb", "m", &system.q.data()[4]);
    out.addChannel("PtchPMzc", "deg", &system.theta_deg);
    out.addChannel("LSSTipPxa", "deg", &LSSTipPxa, 180.0/M_PI);
    out.addChannel("Q_GeAz", "rad", &Q_GeAz);
    out.addChannel("Q_DrTr", "rad", &Q_DrTr);    
    out.addChannel("QD_DrTr", "rad/s", &QD_DrTr);    
    out.addChannel("LSSTipVxa", "rpm", &system.states.phi_rot_d, 30.0/M_PI);
    out.addChannel("LSSTipAxa", "deg/s^2", &system.states.phi_rot_dd, 180.0/M_PI);
    out.addChannel("HSShftV", "rpm", &system.states.phi_gen_d, 30.0/M_PI);
    out.addChannel("HSShftA", "deg/s^2", &system.states.phi_gen_dd, 180.0/M_PI);
    out.addChannel("YawBrTDxp", "m", &system.states.tow_fa);
    out.addChannel("YawBrTAxp", "m/s^2", &system.states.tow_fa_dd);
    out.addChannel("Q_TFA1", "m", &system.states.tow_fa);
    out.addChannel("QD_TFA1", "m/s", &system.states.tow_fa_d);
//    out.addChannel("YawBrRDyt", "deg", &system.states.tow_fa, system.param.TwTrans2Roll*180.0/M_PI);
//    out.addChannel("YawBrRVyp", "deg/s", &system.states.tow_fa_d, system.param.TwTrans2Roll*180.0/M_PI);
    out.addChannel("RootFxc", "kN", &system.Fthrust, 1.0/3000.0);
    out.addChannel("RootMxc", "kNm", &system.Trot, 1.0/3000.0);
    out.addChannel("LSShftFxa", "kN", &system.Fthrust, 1.0/1000.0);
    out.addChannel("LSShftMxa", "kNm", &system.Trot, 1.0/1000.0);
    out.addChannel("RotPwr", "kW", &RotPwr, 1.0/1000.0);
    out.addChannel("HSShftTq", "kNm", &system.inputs.Tgen, 1.0/1000.0);
    out.addChannel("HSShftPwr", "kW", &HSShftPwr, 1.0/1000.0);
    out.addChannel("RtVAvgxh", "m/s", &system.inputs.vwind);
    out.addChannel("WindVxi", "m/s", &system.inputs.vwind);
    out.addChannel("Wind1VelX", "m/s", &system.inputs.vwind);
    out.addChannel("RtTSR", "-", &system.lam);
    out.addChannel("RtAeroCq", "-", &system.cm);
    out.addChannel("RtAeroCt", "-", &system.ct);
    out.addChannel("RotCf", "-", &system.cflp);
    out.addChannel("BlPitchC", "deg", &system.inputs.theta,  -180.0/M_PI);
    out.addChannel("GenTq", "kNm", &system.inputs.Tgen, 1.0/1000.0);
    out.addChannel("RootMxb", "-", &system.modalFlapForce);
}

bool simulate(turbine_T1B1cG_aeroSystem &system, FAST_Wind* wind, double ts, double tfinal, const std::string &discon_path, const std::string &out_file_name) {
    FAST_Output out(tfinal/ts+1);
    out.setTime(0.0, ts);
    setupOutputs(out, system);
    
    system.t= 0.0;

    system.inputs.vwind= wind_adjust*wind->getWind(system.t);
    system.inputs.Tgen= 10000; // TODO
    system.inputs.theta= 0;
    
    system.states.phi_gen= system.inputs.Tgen*system.param.GBRatio/system.param.DTTorSpr;
    system.states.phi_gen_d= 1000.0/30.0*M_PI; // TODO
    system.states.phi_rot= 0.0;
    system.states.phi_rot_d= system.states.phi_gen_d/system.param.GBRatio;
    
    system.doflocked[system.states_idx.phi_rot]= true;
    system.doflocked[system.states_idx.phi_gen]= true;
    
    if(!system.staticEquilibrium())
        printf("Static equilibrium could not be found\n");
    
    system.doflocked[system.states_idx.phi_rot]= false;
    system.doflocked[system.states_idx.phi_gen]= false;
    
    
    DISCON_Interface DISCON(discon_path);
    
    DISCON.comm_interval= ts;
    DISCON.wind_speed_hub= system.inputs.vwind;
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
    DISCON.gen_torque_meas= system.inputs.Tgen;
    DISCON.rot_speed_meas= system.states.phi_rot_d;
    DISCON.gen_speed_meas= system.states.phi_gen_d;
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
    
    RotPwr= system.Trot*system.states.phi_rot_d;
    HSShftPwr= system.inputs.Tgen*system.states.phi_gen_d;
    Q_GeAz= std::fmod(system.states.phi_gen/system.param.GBRatio+M_PI*3.0/2.0, 2*M_PI);
    LSSTipPxa= std::fmod(system.states.phi_rot, 2*M_PI);        
    Q_DrTr= system.states.phi_rot - system.states.phi_gen/system.param.GBRatio;
    QD_DrTr= system.states.phi_rot_d - system.states.phi_gen_d/system.param.GBRatio;
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
        system.inputs.vwind= wind_adjust*wind->getWind(system.t);
        if(!system.newmarkInterval(ts*ipas, h, ts)) {
            res= false;
            break;
        }
        
        RotPwr= system.Trot*system.states.phi_rot_d;
        HSShftPwr= system.inputs.Tgen*system.states.phi_gen_d;
        Q_GeAz= std::fmod(system.states.phi_gen/system.param.GBRatio+M_PI*3.0/2.0, 2*M_PI);
        LSSTipPxa= std::fmod(system.states.phi_rot, 2*M_PI);        
        Q_DrTr= system.states.phi_rot - system.states.phi_gen/system.param.GBRatio;
        QD_DrTr= system.states.phi_rot_d - system.states.phi_gen_d/system.param.GBRatio;
        out.collectData();
    }
    printf("Simulation done\n");
    out.write(out_file_name, "Output of TurbineSimulator simulation");
    
    if(DISCON.finish())
        printf("%s\n", DISCON.getMessage().c_str());

    return res;
}

bool DISCON_Step(double t, DISCON_Interface &DISCON, turbine_T1B1cG_aeroSystem &system) {
    DISCON.current_time= t;
    
    DISCON.wind_speed_hub= system.inputs.vwind;
    DISCON.yaw_error_meas= 0;
    DISCON.abs_yaw= 0;
    DISCON.gen_torque_meas= system.inputs.Tgen;
    DISCON.rot_speed_meas= system.states.phi_rot_d;
    DISCON.gen_speed_meas= system.states.phi_gen_d;
    DISCON.power_out_meas= DISCON.gen_speed_meas * DISCON.gen_torque_meas;
    
    DISCON.blade1_pitch= -system.inputs.theta;
    DISCON.blade2_pitch= -system.inputs.theta;
    DISCON.blade3_pitch= -system.inputs.theta;
    
    DISCON.f_a_acc= system.states.tow_fa_dd;
    DISCON.s_s_acc= 0.0;
    
    DISCON.rotor_pos= system.states.phi_rot;
    
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
    
//     system.inputs.theta= -(1.0/3.0)*(DISCON.blade1_dem + DISCON.blade2_dem + DISCON.blade3_dem);
    system.inputs.theta= -DISCON.pitch_coll_dem;
    system.inputs.Tgen= DISCON.gen_torque_dem;
    
    if(((int)DISCON.safety_code_dem) != 0)
        printf("safety_code_dem: %f\n", DISCON.safety_code_dem);
    
    return DISCON.sim_status!=-1;
}
