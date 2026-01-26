#include <stdio.h>
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

#include "acados/utils/print.h"
#include "acados/utils/math.h"
#include "acados_c/sim_interface.h"
#include "acados_sim_solver_T1_acados.h"

typedef double real_type;

#define WITH_CONSTANTS
#include "T1_param.hpp"

bool simulate(T1_acados_sim_solver_capsule *capsule, FAST_Wind* wind, double ts, double tfinal, const std::string &discon_path, const std::string &out_file_name, T1Parameters &param, FAST_Parent_Parameters &p, double rpm0);
bool DISCON_Step(double t, DISCON_Interface &DISCON, double *states, double *inputs, T1Parameters &param);
void initTorquePitch(double vwind, double om_rot, double &torque, double &theta_deg, T1Parameters &sys_param, FAST_Parent_Parameters &p);

double HSShftPwr;
double LSSTipPxa;
double wind_adjust;

int main(int argc, char* argv[]) {
    T1_acados_sim_solver_capsule *capsule = T1_acados_acados_sim_solver_create_capsule();
    FAST_Wind* wind;
    double simtime;
    double simstep;
    double rpm0;
    std::string discon_dll;
    std::string out_name;
    T1Parameters param;
    FAST_Parent_Parameters p;
    double *p_= NULL;
    
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

    if(int status= T1_acados_acados_sim_create(capsule)) {
        printf("acados_create() returned status %d. Exiting.\n", status);
        exit (EXIT_FAILURE);                    
    }
    
//     int tmp_int = 2;
//     sim_opts_set(T1_sim_config, T2B2cG_aero_sim_opts, "newton_iter", &tmp_int);
//     tmp_int = 2;
//     sim_opts_set(T1_sim_config, T2B2cG_aero_sim_opts, "num_stages", &tmp_int);
//     tmp_int = 1;
//     sim_opts_set(T1_sim_config, T2B2cG_aero_sim_opts, "num_steps", &tmp_int);
    {
        try {
            param.setFromFile(argc_result["paramfile"].as<std::string>());
        } catch (const std::exception& e) {
            fprintf(stderr, "Parameter file error: %s\n", e.what());
            if(int status= T1_acados_acados_sim_free(capsule)) {
                printf("T1_acados_acados_sim_free() returned status %d. \n", status);
            }
            T1_acados_acados_sim_solver_free_capsule(capsule);
            exit (EXIT_FAILURE);
        }
        if(param.unsetParamsWithMsg()) {
            fprintf(stderr, "\nAll parameters have to be set. Exiting.\n");
            if(int status= T1_acados_acados_sim_free(capsule)) {
                printf("T1_acados_acados_sim_free() returned status %d. \n", status);
            }
            T1_acados_acados_sim_solver_free_capsule(capsule);
            exit (EXIT_FAILURE);            
        }
        
        int nParams= param.getNumParameters();
        
        p_= (double *)malloc(sizeof(double)*nParams);
        param.getParamArray(p_);
//         std::ofstream p_out("param_echo.txt");
//         for(int i= 0; i<29655; ++i)
//             p_out << p[i] << std::endl;
//         p_out.close();
        T1_acados_acados_sim_update_params(capsule, p_, nParams);
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
        bool res= simulate(capsule,
                           wind,
                           simstep,
                           simtime,
                           discon_dll,
                           out_name,
                           param,
                           p,
                           rpm0);

        if(!res) {
            delete wind;
            free(p_);
            exit (EXIT_FAILURE);
        }
        
        double cpu_duration = (std::clock() - startcputime) / (double)CLOCKS_PER_SEC;
        std::cout << "Run-time of integrator: " << cpu_duration << " seconds" << std::endl;
    }
    
    delete wind;
    free(p_);
    
    if(int status= T1_acados_acados_sim_free(capsule)) {
        printf("T1_acados_acados_sim_free() returned status %d. \n", status);
    }

    T1_acados_acados_sim_solver_free_capsule(capsule);
    
    exit (EXIT_SUCCESS);
}

void setupOutputs(FAST_Output &out, double *states, double *inputs) {
    out.addChannel("PtchPMzc", "deg", &inputs[theta], -180.0/M_PI);
    out.addChannel("LSSTipPxa", "deg", &LSSTipPxa, 180.0/M_PI);
    out.addChannel("LSSTipVxa", "rpm", &states[phi_rot_d], 30.0/M_PI);
    out.addChannel("YawBrTDxp", "m", &states[tow_fa]);
    out.addChannel("YawBrTVyp", "m/s", &states[tow_fa_d]);
    out.addChannel("Q_TFA1", "m", &states[tow_fa]);
    out.addChannel("HSShftTq", "kNm", &inputs[Tgen], 1.0/1000.0);
    out.addChannel("RtVAvgxh", "m/s", &inputs[vwind]);
    out.addChannel("BlPitchC", "deg", &inputs[theta],  -180.0/M_PI);
    out.addChannel("GenTq", "kNm", &inputs[Tgen], 1.0/1000.0);
    out.addChannel("HSShftPwr", "kW", &HSShftPwr, 1.0/1000.0);
}

bool simulate(T1_acados_sim_solver_capsule *capsule, FAST_Wind* wind, double ts, double tfinal, const std::string &discon_path, const std::string &out_file_name, T1Parameters &param, FAST_Parent_Parameters &p, double rpm0) {
    double states[n_states] = {0.0};
    double inputs[n_inputs] = {0.0};

    FAST_Output out(tfinal/ts+2);
    out.setTime(0.0, ts);
    setupOutputs(out, states, inputs);
    
    // initial condition and inputs  
    inputs[vwind]= wind_adjust*wind->getWind(0.0);

    double phi_gen_d= rpm0/30.0*M_PI;
    states[phi_rot_d]= phi_gen_d/param.GBRatio;

    double theta_deg;
    double torque;
    initTorquePitch(inputs[vwind], states[phi_rot_d], torque, theta_deg, param, p);
    
    inputs[Tgen]= torque;
    inputs[theta]= -theta_deg/180.0*M_PI;;
    
    states[phi_rot]= 0.0;    

    sim_config *acados_sim_config = T1_acados_acados_get_sim_config(capsule);
    sim_in *acados_sim_in = T1_acados_acados_get_sim_in(capsule);
    sim_out *acados_sim_out = T1_acados_acados_get_sim_out(capsule);
    void *acados_sim_dims = T1_acados_acados_get_sim_dims(capsule);
    
    sim_in_set(acados_sim_config, acados_sim_dims, acados_sim_in, "T", &ts);
    
    
//     DISCON_Interface DISCON(discon_path, p.getFilename("ServoFile.DLL_InFile"));
    DISCON_Interface DISCON(discon_path);
    
    DISCON.comm_interval= ts;
    DISCON.wind_speed_hub= inputs[vwind];
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
    DISCON.gen_torque_meas= inputs[Tgen];
    DISCON.rot_speed_meas= states[phi_rot_d];
    DISCON.gen_speed_meas= states[phi_rot_d]*param.GBRatio;
    DISCON.power_out_meas= DISCON.gen_speed_meas * DISCON.gen_torque_meas;
    
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
    

    printf("Starting simulation\n");
    
    LSSTipPxa= std::fmod(states[phi_rot], 2*M_PI);        
    HSShftPwr= inputs[Tgen]*states[phi_rot_d]*param.GBRatio;
    out.collectData();
    
    int n_steps= tfinal/ts;
    bool res= true;
    for(int i_step= 0; i_step<n_steps; ++i_step) {
        double t= ts*i_step;
        
        if(!DISCON_Step(t, DISCON, states, inputs, param)) {
            printf("DISCON finished at t= %f\n", t);
            res= false;
            break;
        }
        
        inputs[vwind]= wind_adjust*wind->getWind(t);
        
        sim_in_set(acados_sim_config, acados_sim_dims, acados_sim_in, "u", inputs);
        sim_in_set(acados_sim_config, acados_sim_dims, acados_sim_in, "x", states);
        
        int status = T1_acados_acados_sim_solve(capsule);

        if (status != ACADOS_SUCCESS)
        {
            printf("acados_solve() failed with status %d.\n", status);
            res= false;
            break;
        }
        
        sim_out_get(acados_sim_config, acados_sim_dims, acados_sim_out, "x", states);
        
        LSSTipPxa= std::fmod(states[phi_rot], 2*M_PI);
        HSShftPwr= inputs[Tgen]*states[phi_rot_d]*param.GBRatio;

        try {
            out.collectData();
        } catch (const std::exception& e) {
            res= false;
            fprintf(stderr, "Error in Outputs at %f after %d interation: %s\n", t, i_step, e.what());
            break;
        }
    }
    printf("Simulation done\n");
    out.write(out_file_name, "Output of TurbineSimulator simulation");
    
    if(DISCON.finish())
        printf("%s\n", DISCON.getMessage().c_str());

    return res;
}

bool DISCON_Step(double t, DISCON_Interface &DISCON, double *states, double *inputs, T1Parameters &param) {
    DISCON.current_time= t;
    
    DISCON.wind_speed_hub= inputs[vwind];
    DISCON.yaw_error_meas= 0;
    DISCON.abs_yaw= 0;
    DISCON.gen_torque_meas= inputs[Tgen];
    DISCON.rot_speed_meas= states[phi_rot_d];
    DISCON.gen_speed_meas= states[phi_rot_d]*param.GBRatio;
    DISCON.power_out_meas= DISCON.gen_speed_meas * DISCON.gen_torque_meas;
    
    DISCON.blade1_pitch= -inputs[theta];
    DISCON.blade2_pitch= -inputs[theta];
    DISCON.blade3_pitch= -inputs[theta];
    
    DISCON.f_a_acc= 0.0; // TODO: states[tow_fa_dd];
    DISCON.s_s_acc= 0.0; // TODO: states[tow_ss_dd];
    
    DISCON.rotor_pos= states[phi_rot];
    
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
    
    inputs[theta]= -DISCON.pitch_coll_dem;
    inputs[Tgen]= DISCON.gen_torque_dem;
    
    if(((int)DISCON.safety_code_dem) != 0)
        printf("safety_code_dem: %f\n", DISCON.safety_code_dem);
    
    return DISCON.sim_status!=-1;
}

typedef decltype(std::declval<T1Parameters>().cm_lut) MatCx;

double interp1(const MatCx &tab, double lambdaFact, int lambdaIdx, double thetaFact, int thetaIdx) {
    return thetaFact*(lambdaFact*tab(lambdaIdx, thetaIdx) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx)) + (1.0-thetaFact)*(lambdaFact*tab(lambdaIdx, thetaIdx+1) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx+1));
}

double Trot(double vwind, double om_rot, double pitch, T1Parameters *param) {
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
    T1Parameters *param;
    double vwind;
    double om_rot;
    double ref_trq;
};

double trq_zero(double pitch, void *data) {
    struct trq_zero_data *tz_data= (struct trq_zero_data*)data;
    
    return Trot(tz_data->vwind, tz_data->om_rot, pitch, tz_data->param) - tz_data->ref_trq;
}

void initTorquePitch(double vwind, double om_rot, double &torque, double &theta_deg, T1Parameters &sys_param, FAST_Parent_Parameters &p) {
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
