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
#include "brent_zero.h"

#include "T2B1i1cG_direct.hpp"

bool simulate(T2B1i1cG &system, FAST_Wind* wind, double ts, double tfinal, const std::string &discon_path, const std::string &out_file_name, FAST_Parent_Parameters &p, double rpm0);
bool DISCON_Step(double t, DISCON_Interface &DISCON, T2B1i1cG &system);
void initTorquePitch(double vwind, double om_rot, double &torque, double &pitch, T2B1i1cGParameters &sys_param, FAST_Parent_Parameters &p);

double RotPwr;
double HSShftPwr;
double Q_GeAz;
double Q_DrTr;
double QD_DrTr;
double LSSTipPxa;
double wind_adjust;

int main(int argc, char* argv[]) {
    T2B1i1cG system;
    FAST_Wind* wind;
    double simtime;
    double simstep;
    double rpm0;
    std::string discon_dll;
    std::string out_name;
    FAST_Parent_Parameters p;
    
    cxxopts::Options argc_options(argv[0], "A simple wind turbine simulator");
    argc_options.add_options()
    ("p,paramfile", "Parameter file name", cxxopts::value<std::string>()->default_value("./params.txt"))
    ("t,simtime", "Simulation time", cxxopts::value<double>()->default_value("10"))
    ("s,simstep", "Simulation time", cxxopts::value<double>()->default_value("0.01"))
    ("d,discon_dll", "Path and name of the DISCON controller DLL", cxxopts::value<std::string>()->default_value("DISCON.dll"))
    ("o,output", "Output file name", cxxopts::value<std::string>()->default_value("default.outb"))
    ("a,adjust_wind", "Adjustment factor for wind speed", cxxopts::value<double>()->default_value("1.0"))
    ("x,dx_wind", "Offset into wind field in m", cxxopts::value<double>()->default_value("0.0"))
    ("r,rpm0", "Initial generator speed in rpm", cxxopts::value<double>()->default_value("0.0"))
    ("c,config", "Options file for the integration algorithm (default: newmark_options.txt)", cxxopts::value<std::string>()->default_value("newmark_options.txt"))
    ("fast", "OpenFAST main input file", cxxopts::value<std::string>())
    ;
    
    argc_options.parse_positional({"fast"});
    argc_options.positional_help("FAST_main_input_file.fst"); //.show_positional_help();

    if(argc<2) {
        std::cout << argc_options.help() << std::endl;
        exit (EXIT_SUCCESS);
    }
        
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
            p.readFile(argc_result["fast"].as<std::string>());

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
                wind= makeFAST_Wind(p, argc_result["dx_wind"].as<double>());
            } catch (const std::exception& e) {
                fprintf(stderr, "Inflow error: %s\n", e.what());
                exit (EXIT_FAILURE);
            }
            if(argc_result.count("rpm0")) {
                rpm0= argc_result["rpm0"].as<double>();
                if(rpm0<p["ServoFile.GenSpd_MinOM"]) rpm0= p["ServoFile.GenSpd_MinOM"];
                if(rpm0>p["ServoFile.GenSpd_MaxOM"]) rpm0= p["ServoFile.GenSpd_MaxOM"];                
            } else {
                rpm0= (p["ServoFile.GenSpd_MinOM"] + p["ServoFile.GenSpd_MaxOM"])/2.0;
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
        std::cout << "  rpm0=" << rpm0 << std::endl;
        std::cout << "  discon_dll=" << discon_dll << std::endl;
        std::cout << "  output=" << out_name << std::endl;
        
        std::clock_t startcputime = std::clock();
        bool res= simulate(system,
                           wind,
                           simstep,
                           simtime,
                           discon_dll,
                           out_name,
                           p,
                           rpm0);

        if(!res) {
            delete wind;
            exit (EXIT_FAILURE);
        }
        
        double cpu_duration = (std::clock() - startcputime) / (double)CLOCKS_PER_SEC;
        std::cout << "Run-time of integrator: " << cpu_duration << " seconds" << std::endl;
    }
    
    delete wind;
    
    exit (EXIT_SUCCESS);
}

void setupOutputs(FAST_Output &out, T2B1i1cG &system) {
    out.addChannel("PtchPMzc1", "deg", &system.theta_deg1);
    out.addChannel("PtchPMzc2", "deg", &system.theta_deg2);
    out.addChannel("PtchPMzc3", "deg", &system.theta_deg3);
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
    out.addChannel("YawBrTDyp", "m", &system.states.tow_ss);
    out.addChannel("YawBrTAyp", "m/s^2", &system.states.tow_ss_dd);
    out.addChannel("Q_TFA1", "m", &system.states.tow_fa);
    out.addChannel("QD_TFA1", "m/s", &system.states.tow_fa_d);
    out.addChannel("Q_TSS1", "m", &system.states.tow_ss, -1.0);
    out.addChannel("QD_TSS1", "m/s", &system.states.tow_ss_d, -1.0);
    out.addChannel("Q_B1F1", "m", &system.states.bld1_flp);
    out.addChannel("Q_B2F1", "m", &system.states.bld2_flp);
    out.addChannel("Q_B3F1", "m", &system.states.bld3_flp);
    out.addChannel("Q_BE1", "m", &system.states.bld_edg);
    out.addChannel("QD_B1F1", "m/s", &system.states.bld1_flp_d);
    out.addChannel("QD_B2F1", "m/s", &system.states.bld2_flp_d);
    out.addChannel("QD_B3F1", "m/s", &system.states.bld3_flp_d);
    out.addChannel("QD_BE1", "m/s", &system.states.bld_edg_d);
    out.addChannel("RootFxc1", "kN", &system.Fthrust1, 1.0/3000.0);
    out.addChannel("RootFxc2", "kN", &system.Fthrust2, 1.0/3000.0);
    out.addChannel("RootFxc3", "kN", &system.Fthrust3, 1.0/3000.0);
    out.addChannel("RootMxc1", "kNm", &system.Trot1, 1.0/3000.0);
    out.addChannel("RootMxc2", "kNm", &system.Trot2, 1.0/3000.0);
    out.addChannel("RootMxc3", "kNm", &system.Trot3, 1.0/3000.0);
    out.addChannel("RotPwr", "kW", &RotPwr, 1.0/1000.0);
    out.addChannel("HSShftTq", "kNm", &system.inputs.Tgen, 1.0/1000.0);
    out.addChannel("HSShftPwr", "kW", &HSShftPwr, 1.0/1000.0);
    out.addChannel("RtVAvgxh", "m/s", &system.inputs.vwind);
    out.addChannel("WindVxi", "m/s", &system.inputs.vwind);
    out.addChannel("Wind1VelX", "m/s", &system.inputs.vwind);
    out.addChannel("RtTSR", "-", &system.lam);
    out.addChannel("BlPitchC1", "deg", &system.inputs.theta1,  -180.0/M_PI);
    out.addChannel("BlPitchC2", "deg", &system.inputs.theta2,  -180.0/M_PI);
    out.addChannel("BlPitchC3", "deg", &system.inputs.theta3,  -180.0/M_PI);
    out.addChannel("GenTq", "kNm", &system.inputs.Tgen, 1.0/1000.0);
    out.addChannel("RootMyb1", "kNm", &system.y[3], 1.0/1000.0);
    out.addChannel("RootMxb1", "kNm", &system.y[4], 1.0/1000.0);
    out.addChannel("RootMyb2", "kNm", &system.y[5], 1.0/1000.0);
    out.addChannel("RootMxb2", "kNm", &system.y[6], 1.0/1000.0);
    out.addChannel("RootMyb3", "kNm", &system.y[7], 1.0/1000.0);
    out.addChannel("RootMxb3", "kNm", &system.y[8], 1.0/1000.0);
}

bool simulate(T2B1i1cG &system, FAST_Wind* wind, double ts, double tfinal, const std::string &discon_path, const std::string &out_file_name, FAST_Parent_Parameters &p, double rpm0) {
    FAST_Output out(tfinal/ts+2);
    out.setTime(0.0, ts);
    setupOutputs(out, system);
    
    system.t= 0.0;

    system.inputs.vwind= wind_adjust*wind->getWind(system.t);
    wind->getShear(system.t, system.inputs.h_shear, system.inputs.v_shear);
    
    system.states.phi_gen_d= rpm0/30.0*M_PI;
    system.states.phi_rot_d= system.states.phi_gen_d/system.param.GBRatio;
    
    double theta_deg;
    double torque;
    initTorquePitch(system.inputs.vwind, system.states.phi_rot_d, torque, theta_deg, system.param, p);
    
    system.inputs.Tgen= torque;
    system.inputs.theta1= -theta_deg/180.0*M_PI;
    system.inputs.theta2= -theta_deg/180.0*M_PI;
    system.inputs.theta3= -theta_deg/180.0*M_PI;
    
    system.states.phi_rot= 0.0;
    system.states.phi_gen= -system.inputs.Tgen*system.param.GBRatio/system.param.DTTorSpr;
     
    system.doflocked[system.states_idx.phi_rot]= true;
    system.doflocked[system.states_idx.phi_gen]= true;
    
    try {
        system.staticEquilibrium();
    } catch (const std::exception& e) {
        std::cout << system.Jacobian << std::endl;
        fprintf(stderr, "Static equilibrium could not be found: %s\n", e.what());
        exit (EXIT_FAILURE);
    }
    
    system.doflocked[system.states_idx.phi_rot]= false;
    system.doflocked[system.states_idx.phi_gen]= false;
    
    DISCON_Interface DISCON(discon_path, p.getFilename("ServoFile.DLL_InFile"));
    
    DISCON.comm_interval= ts;
    DISCON.wind_speed_hub= system.inputs.vwind;
    DISCON.min_pitch= p["ServoFile.Ptch_Min"]/180.0*M_PI;
    DISCON.max_pitch= p["ServoFile.Ptch_Max"]/180.0*M_PI;
    DISCON.min_pitch_rate= p["ServoFile.PtchRate_Min"]/180.0*M_PI;
    DISCON.max_pitch_rate= p["ServoFile.PtchRate_Max"]/180.0*M_PI;
    DISCON.pitch_actuator= 0; // position control
    DISCON.opt_mode_gain= p["ServoFile.Gain_OM"];
    DISCON.min_gen_speed= p["ServoFile.GenSpd_MinOM"]/30.0*M_PI; 
    DISCON.max_gen_speed= p["ServoFile.GenSpd_MaxOM"]/30.0*M_PI;
    DISCON.gen_speed_dem= p["ServoFile.GenSpd_Dem"]/30.0*M_PI;
    DISCON.gen_torque_sp= p["ServoFile.GenTrq_Dem"];
    DISCON.power_dem= p["ServoFile.GenPwr_Dem"];
    DISCON.gen_torque_meas= system.inputs.Tgen;
    DISCON.rot_speed_meas= system.states.phi_rot_d;
    DISCON.gen_speed_meas= system.states.phi_gen_d;
    DISCON.power_out_meas= DISCON.gen_speed_meas * DISCON.gen_torque_meas;
    
    DISCON.blade1_pitch= -system.inputs.theta;
    DISCON.blade2_pitch= -system.inputs.theta;
    DISCON.blade3_pitch= -system.inputs.theta;
    
    DISCON.sp_pitch_partial= p["ServoFile.Ptch_SetPnt"]/180.0*M_PI;
    DISCON.ts_lut_idx= 0;
    DISCON.ts_lut_len= 0;
    DISCON.yaw_ctrl_mode= 0; // 0= yaw rate control, 1= yaw torque
    DISCON.yaw_error_meas= 0;
    DISCON.abs_yaw= 0;

    DISCON.num_blades= 3;
    DISCON.pitch_ctrl_mode= p["ServoFile.Ptch_Cntrl"];
    DISCON.gen_contractor= 1; // 0= off, 1= main (high speed) or variable speed generator, 2= low speed generator
    DISCON.shaft_brake_status= 0; // 0= off, 1= brake 1 on
    DISCON.controller_state= 0; // 0= power production, 1= parked, 2= ideling, 3= startup, 4= normal stop, 5= emergency stop
    DISCON.time_to_output= 0;
    DISCON.pitch_dem= 0;
    
    DISCON.grid_volt_fact= 1.0;
    DISCON.grid_freq_fact= 1.0;
    
    DISCON.setOutfile("discon.out");
    DISCON.version= 0.0;
   
    if(DISCON.init())
        printf("%s\n", DISCON.getMessage().c_str());
    
    // printf("load_meas_request: %d\n", (int)DISCON.load_meas_request);
    

    printf("Starting simulation\n");
    system.newmarkOneStep(0.0);
    
    RotPwr= (system.Trot1+system.Trot2+system.Trot3)*system.states.phi_rot_d;
    HSShftPwr= system.inputs.Tgen*system.states.phi_gen_d;
    Q_GeAz= std::fmod(system.states.phi_rot+M_PI*3.0/2.0, 2*M_PI);
    LSSTipPxa= std::fmod(system.states.phi_rot, 2*M_PI);   
    Q_DrTr= system.states.phi_rot - system.states.phi_gen/system.param.GBRatio;
    QD_DrTr= system.states.phi_rot_d - system.states.phi_gen_d/system.param.GBRatio;
    system.calcOut();    
    out.collectData();
    
    int ipas= 0;
    bool res= true;
    double h= ts;
    while(system.t<tfinal) {
        try {
            if(!DISCON_Step(ts*ipas, DISCON, system)) {
                printf("DISCON finished at t= %f\n", ts*ipas);
                res= false;
                break;
            }
        } catch (const std::exception& e) {
            res= false;
            fprintf(stderr, "Error in DISCON at t= %f: %s\n", ts*ipas, e.what());
            break;
        }
        
        ipas++;
        system.inputs.vwind= wind_adjust*wind->getWind(system.t);
        wind->getShear(system.t, system.inputs.h_shear, system.inputs.v_shear);
        
        try {
            system.newmarkInterval(ts*ipas, h, ts);
        } catch (const std::exception& e) {
            res= false;
            fprintf(stderr, "Error in Integrator at t= %f: %s\n", ts*ipas, e.what());
            break;
        }
        
        RotPwr= (system.Trot1+system.Trot2+system.Trot3)*system.states.phi_rot_d;
        HSShftPwr= system.inputs.Tgen*system.states.phi_gen_d;
        Q_GeAz= std::fmod(system.states.phi_rot+M_PI*3.0/2.0, 2*M_PI);
        LSSTipPxa= std::fmod(system.states.phi_rot, 2*M_PI);        
        Q_DrTr= system.states.phi_rot - system.states.phi_gen/system.param.GBRatio;
        QD_DrTr= system.states.phi_rot_d - system.states.phi_gen_d/system.param.GBRatio;
        system.calcOut();
        out.collectData();
    }
    printf("Simulation done\n");
    out.write(out_file_name, "Output of TurbineSimulator simulation");
    
    if(DISCON.finish())
        printf("%s\n", DISCON.getMessage().c_str());

    return res;
}

bool DISCON_Step(double t, DISCON_Interface &DISCON, T2B1i1cG &system) {
    DISCON.current_time= t;
    
    DISCON.wind_speed_hub= system.inputs.vwind;
    DISCON.yaw_error_meas= 0;
    DISCON.abs_yaw= 0;
    DISCON.gen_torque_meas= system.inputs.Tgen;
    DISCON.rot_speed_meas= system.states.phi_rot_d;
    DISCON.gen_speed_meas= system.states.phi_gen_d;
    DISCON.power_out_meas= DISCON.gen_speed_meas * DISCON.gen_torque_meas;
    
    DISCON.blade1_pitch= -system.inputs.theta1;
    DISCON.blade2_pitch= -system.inputs.theta2;
    DISCON.blade3_pitch= -system.inputs.theta3;
    
    DISCON.f_a_acc= system.states.tow_fa_dd;
    DISCON.s_s_acc= system.states.tow_ss_dd;
    
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
    
//     system.inputs.theta1= -DISCON.blade1_dem;
//     system.inputs.theta2= -DISCON.blade2_dem;
//     system.inputs.theta3= -DISCON.blade3_dem;
    system.inputs.theta1= -DISCON.pitch_coll_dem;
    system.inputs.theta2= -DISCON.pitch_coll_dem;
    system.inputs.theta3= -DISCON.pitch_coll_dem;
    system.inputs.Tgen= DISCON.gen_torque_dem;
    
    if(((int)DISCON.safety_code_dem) != 0)
        printf("safety_code_dem: %f\n", DISCON.safety_code_dem);
    
    return DISCON.sim_status!=-1;
}

typedef decltype(std::declval<T2B1i1cG>().param.cm_lut) MatCx;

double interp1(const MatCx &tab, double lambdaFact, int lambdaIdx, double thetaFact, int thetaIdx) {
    return thetaFact*(lambdaFact*tab(lambdaIdx, thetaIdx) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx)) + (1.0-thetaFact)*(lambdaFact*tab(lambdaIdx, thetaIdx+1) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx+1));
}

double Trot(double vwind, double om_rot, double pitch, T2B1i1cGParameters *param) {
    double lam= om_rot*param->Rrot/vwind;
    double Fwind= param->rho/2.0*param->Arot*vwind*vwind;
    
    if(lam>param->lambdaMax-param->lambdaStep) lam= param->lambdaMax-param->lambdaStep;
    if(lam<param->lambdaMin) lam= param->lambdaMin;
    if(pitch>param->thetaMax-param->thetaStep) pitch= param->thetaMax-param->thetaStep;
    if(pitch<param->thetaMin) pitch= param->thetaMin;
    
    double lambdaScaled= (lam-param->lambdaMin)/param->lambdaStep;
    int lambdaIdx= std::floor(lambdaScaled);
    double thetaScaled= (pitch-param->thetaMin)/param->thetaStep;
    int thetaIdx= std::floor(thetaScaled);
    double lambdaFact= 1.0 - lambdaScaled + lambdaIdx;
    double thetaFact= 1.0 - thetaScaled + thetaIdx;
    
    double cm= interp1(param->cm_lut, lambdaFact, lambdaIdx, thetaFact, thetaIdx);
    return param->Rrot*Fwind*cm;
}

struct trq_zero_data {
    T2B1i1cGParameters *param;
    double vwind;
    double om_rot;
    double ref_trq;
};

double trq_zero(double pitch, void *data) {
    struct trq_zero_data *tz_data= (struct trq_zero_data*)data;
    
    return Trot(tz_data->vwind, tz_data->om_rot, pitch, tz_data->param) - tz_data->ref_trq;
}

void initTorquePitch(double vwind, double om_rot, double &torque, double &theta_deg, T2B1i1cGParameters &sys_param, FAST_Parent_Parameters &p) {
    theta_deg= 0.0;
    torque= Trot(vwind, om_rot, theta_deg, &sys_param) / sys_param.GBRatio;
    if(torque<0.0) torque= 0.0;
    
    if(torque<=p["ServoFile.GenTrq_Dem"]) {
        printf("Found initial torque: %f, initial pitch: %f.\n", torque, theta_deg);
        return;
    }
    
    struct trq_zero_data tz_data;
    tz_data.param= &sys_param;
    tz_data.vwind= vwind;
    tz_data.om_rot= om_rot;
    tz_data.ref_trq= p["ServoFile.GenTrq_Dem"] * sys_param.GBRatio;
    torque= p["ServoFile.GenTrq_Dem"];
    
    theta_deg= (sys_param.thetaMin+sys_param.thetaMax)/2.0;
    int it= brent(&trq_zero, theta_deg, sys_param.thetaMin, sys_param.thetaMax, &tz_data);
    printf("Found initial torque: %f, initial pitch: %f after %d interations.\n", torque, theta_deg, it);
}
