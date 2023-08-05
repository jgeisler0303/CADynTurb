// run compiler in main directory of generated code
// g++ -fpermissive -g -std=c++17 -I. -I../../simulator -Ic_generated_code -I$ACADOS_INSTALL_DIR/include -I$ACADOS_INSTALL_DIR/include/blasfeo/include -I$ACADOS_INSTALL_DIR/include/hpipm/include ../../simulator/T2B2cG_acados.cpp c_generated_code/acados_sim_solver_T2B2cG.c c_generated_code/T2B2cG_model/T2B2cG_impl_dae_fun_jac_x_xdot_u.c c_generated_code/T2B2cG_model/T2B2cG_impl_dae_fun_jac_x_xdot_z.c c_generated_code/T2B2cG_model/T2B2cG_impl_dae_fun.c c_generated_code/T2B2cG_model/T2B2cG_impl_dae_hess.c c_generated_code/T2B2cG_model/T2B2cG_impl_dae_jac_x_xdot_u_z.c -L$ACADOS_INSTALL_DIR/lib -ldl -lacados -lblasfeo -lhpipm -o T2B2cG_acados

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

#include "acados/utils/print.h"
#include "acados/utils/math.h"
#include "acados_c/sim_interface.h"
#include "acados_sim_solver_T2B2cG.h"

typedef double real_type;
#include "T2B2cG_param.hpp"

const int tow_fa= 0;
const int tow_ss= 1;
const int bld_flp= 2;
const int bld_edg= 3;
const int phi_rot= 4;
const int phi_gen= 5;
const int tow_fa_d= 6;
const int tow_ss_d= 7;
const int bld_flp_d= 8;
const int bld_edg_d= 9;
const int phi_rot_d= 10;
const int phi_gen_d= 11;
const int vwind= 0;
const int Tgen= 1;
const int theta= 2;

bool simulate(sim_solver_capsule *capsule, FAST_Wind* wind, double ts, double tfinal, const std::string &discon_path, const std::string &out_file_name);
bool DISCON_Step(double t, DISCON_Interface &DISCON, double *states, double *inputs);

double Q_DrTr;
double QD_DrTr;
double Q_GeAz;
double LSSTipPxa;
double GBRatio;
double DTTorSpr;
double TwTrans2Roll;
double wind_adjust;

int main(int argc, char* argv[]) {
    sim_solver_capsule *capsule = T2B2cG_acados_sim_solver_create_capsule();
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
    ("fast", "OpenFAST main input file", cxxopts::value<std::string>())
    ;
    
    argc_options.parse_positional({"fast"});
    
    auto argc_result = argc_options.parse(argc, argv);

    if(int status= T2B2cG_acados_sim_create(capsule)) {
        printf("acados_create() returned status %d. Exiting.\n", status);
        exit (EXIT_FAILURE);                    
    }
    
//     int tmp_int = 2;
//     sim_opts_set(T2B2cG_sim_config, T2B2cG_sim_opts, "newton_iter", &tmp_int);
//     tmp_int = 2;
//     sim_opts_set(T2B2cG_sim_config, T2B2cG_sim_opts, "num_stages", &tmp_int);
//     tmp_int = 1;
//     sim_opts_set(T2B2cG_sim_config, T2B2cG_sim_opts, "num_steps", &tmp_int);
    {
        T2B2cGParameters param;
        try {
            param.setFromFile(argc_result["paramfile"].as<std::string>());
        } catch (const std::exception& e) {
            fprintf(stderr, "Parameter file error: %s\n", e.what());
            if(int status= T2B2cG_acados_sim_free(capsule)) {
                printf("T2B2cG_acados_sim_free() returned status %d. \n", status);
            }
            T2B2cG_acados_sim_solver_free_capsule(capsule);
            exit (EXIT_FAILURE);
        }
        if(param.unsetParamsWithMsg()) {
            fprintf(stderr, "\nAll parameters have to be set. Exiting.\n");
            if(int status= T2B2cG_acados_sim_free(capsule)) {
                printf("T2B2cG_acados_sim_free() returned status %d. \n", status);
            }
            T2B2cG_acados_sim_solver_free_capsule(capsule);
            exit (EXIT_FAILURE);            
        }
        double p[29655];
        param.getParamArray(p);
//         std::ofstream p_out("param_echo.txt");
//         for(int i= 0; i<29655; ++i)
//             p_out << p[i] << std::endl;
//         p_out.close();
        T2B2cG_acados_sim_update_params(capsule, p, 29655);
        
        GBRatio= param.getParam("GBRatio");
        DTTorSpr= param.getParam("DTTorSpr");
        TwTrans2Roll= param.getParam("TwTrans2Roll");
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
        bool res= simulate(capsule,
                           wind,
                           simstep,
                           simtime,
                           discon_dll,
                           out_name);
        double cpu_duration = (std::clock() - startcputime) / (double)CLOCKS_PER_SEC;

        if(!res) {
            exit (EXIT_FAILURE);
        }
        
        std::cout << "Run-time of integrator: " << cpu_duration << " seconds" << std::endl;
    }
    
    delete wind;
    
    if(int status= T2B2cG_acados_sim_free(capsule)) {
        printf("T2B2cG_acados_sim_free() returned status %d. \n", status);
    }

    T2B2cG_acados_sim_solver_free_capsule(capsule);
    
    exit (EXIT_SUCCESS);
}

void setupOutputs(FAST_Output &out, double *states, double *inputs) {
    out.addChannel("Q_BF1", "m", &states[bld_flp]);
    out.addChannel("Q_BE1", "m", &states[bld_edg]);
    out.addChannel("QD_BF1", "m/s", &states[bld_flp_d]);
    out.addChannel("QD_BE1", "m/s", &states[bld_edg_d]);
//     out.addChannel("TipDxb", "m", &system.q.data()[3]*blade_frame_49_phi0_1_1 + &system.q.data()[4]);
//     out.addChannel("TipDyb", "m", &system.q.data()[4]);
    out.addChannel("PtchPMzc", "deg", &inputs[theta], -180.0/M_PI);
    out.addChannel("LSSTipPxa", "deg", &LSSTipPxa, 180.0/M_PI);
    out.addChannel("Q_GeAz", "rad", &Q_GeAz);
    out.addChannel("Q_DrTr", "rad", &Q_DrTr);    
    out.addChannel("QD_DrTr", "rad/s", &Q_DrTr);    
    out.addChannel("LSSTipVxa", "rpm", &states[phi_rot_d], 30.0/M_PI);
//     out.addChannel("LSSTipAxa", "deg/s^2", &states[phi_rot_dd], 180.0/M_PI);
    out.addChannel("HSShftV", "rpm", &states[phi_gen_d], 30.0/M_PI);
//     out.addChannel("HSShftA", "deg/s^2", &states[phi_gen_dd], 180.0/M_PI);
    out.addChannel("YawBrTDxp", "m", &states[tow_fa]);
    out.addChannel("YawBrTDyp", "m", &states[tow_ss]);
    out.addChannel("YawBrTVyp", "m/s", &states[tow_fa_d]);
    out.addChannel("YawBrTVxp", "m/s", &states[tow_ss_d]);
    out.addChannel("Q_TFA1", "m", &states[tow_fa);
    out.addChannel("QD_TFA1", "m/s", &states[tow_fa_d]);
    out.addChannel("Q_TSS1", "m", &states[tow_ss], -1.0);
    out.addChannel("QD_TSS1", "m/s", &states[tow_ss_d], -1.0);
//     out.addChannel("YawBrTAxp", "m/s^2", &states[tow_fa_dd]);
//     out.addChannel("YawBrTAyp", "m/s^2", &states[tow_ss_dd]);
//    out.addChannel("YawBrRDyt", "deg", &states[tow_fa, system.param.TwTrans2Roll*180.0/M_PI);
//    out.addChannel("YawBrRDxt", "deg", &states[tow_ss, system.param.TwTrans2Roll*180.0/M_PI);
//    out.addChannel("YawBrRVyp", "deg/s", &states[tow_fa_d, system.param.TwTrans2Roll*180.0/M_PI);
//    out.addChannel("YawBrRVxp", "deg/s", &states[tow_ss_d, system.param.TwTrans2Roll*180.0/M_PI);
//     out.addChannel("RootFxc", "kN", &system.Fthrust, 1.0/3000.0);
//     out.addChannel("RootMxc", "kNm", &system.Trot, 1.0/3000.0);
//     out.addChannel("LSShftFxa", "kN", &system.Fthrust, 1.0/1000.0);
//     out.addChannel("LSShftMxa", "kNm", &system.Trot, 1.0/1000.0);
//     out.addChannel("RotPwr", "kW", &RotPwr, 1.0/1000.0);
    out.addChannel("HSShftTq", "kNm", &inputs[Tgen], 1.0/1000.0);
//     out.addChannel("HSShftPwr", "kW", &HSShftPwr, 1.0/1000.0);
    out.addChannel("RtVAvgxh", "m/s", &inputs[vwind]);
//     out.addChannel("RtTSR", "-", &system.lam);
//     out.addChannel("RtAeroCq", "-", &system.cm);
//     out.addChannel("RtAeroCt", "-", &system.ct);
//     out.addChannel("RotCf", "-", &system.cflp);
//     out.addChannel("RotCe", "-", &system.cedg);
    out.addChannel("BlPitchC", "deg", &inputs[theta],  -180.0/M_PI);
    out.addChannel("GenTq", "kNm", &inputs[Tgen], 1.0/1000.0);
//     out.addChannel("RootMxb", "-", &system.modalFlapForce);
//     out.addChannel("RootMyb", "-", &system.modalEdgeForce);
}

bool simulate(sim_solver_capsule *capsule, FAST_Wind* wind, double ts, double tfinal, const std::string &discon_path, const std::string &out_file_name) {
    FAST_Output out(tfinal/ts+1);
    
    // initial condition and inputs
    double states[12];
    double inputs[3];


    out.setTime(0.0, ts);
    setupOutputs(out, states, inputs);
    
    sim_config *acados_sim_config = T2B2cG_acados_get_sim_config(capsule);
    sim_in *acados_sim_in = T2B2cG_acados_get_sim_in(capsule);
    sim_out *acados_sim_out = T2B2cG_acados_get_sim_out(capsule);
    void *acados_sim_dims = T2B2cG_acados_get_sim_dims(capsule);
    
    sim_in_set(acados_sim_config, acados_sim_dims, acados_sim_in, "T", &ts);

    inputs[vwind]= wind_adjust*wind->getWind(0.0);
    inputs[Tgen]= 10000; // TODO
    inputs[theta]= 0;
    
    states[phi_gen]= inputs[Tgen]*GBRatio/DTTorSpr;
    states[phi_gen_d]= 1000.0/30.0*M_PI; // TODO
    states[phi_rot]= 0.0;
    states[phi_rot_d]= states[phi_gen_d]/GBRatio;
    
    
    DISCON_Interface DISCON(discon_path);
    
    DISCON.comm_interval= ts;
    DISCON.wind_speed_hub= inputs[vwind];
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
    DISCON.gen_torque_meas= inputs[Tgen];
    DISCON.rot_speed_meas= states[phi_rot_d];
    DISCON.gen_speed_meas= states[phi_gen_d];
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
    

    printf("Starting simulation\n");

    Q_GeAz= std::fmod(states[phi_gen]/GBRatio+M_PI*3.0/2.0, 2*M_PI);
    LSSTipPxa= std::fmod(states[phi_rot], 2*M_PI);        
    Q_DrTr= states[phi_rot] - states[phi_gen]/GBRatio + states[tow_ss]*TwTrans2Roll;
    QD_DrTr= states[phi_rot_d] - states[phi_gen_d]/GBRatio + states[tow_ss_d]*TwTrans2Roll;
    out.collectData();
    
    int n_steps= tfinal/ts;
    bool res= true;
    for(int i_step= 0; i_step<n_steps; ++i_step) {
        double t= ts*i_step;
        
        if(!DISCON_Step(t, DISCON, states, inputs)) {
            printf("DISCON finished at t= %f\n", t);
            res= false;
            break;
        }
        
        inputs[vwind]= wind_adjust*wind->getWind(t);
        
        sim_in_set(acados_sim_config, acados_sim_dims, acados_sim_in, "u", inputs);
        sim_in_set(acados_sim_config, acados_sim_dims, acados_sim_in, "x", states);
        
        int status = T2B2cG_acados_sim_solve(capsule);

        if (status != ACADOS_SUCCESS)
        {
            printf("acados_solve() failed with status %d.\n", status);
            res= false;
            break;
        }
        
        sim_out_get(acados_sim_config, acados_sim_dims, acados_sim_out, "x", states);
        
        Q_GeAz= std::fmod(system.states.phi_gen/system.param.GBRatio+M_PI*3.0/2.0, 2*M_PI);
        LSSTipPxa= std::fmod(system.states.phi_rot, 2*M_PI);        
        Q_DrTr= system.states.phi_rot - system.states.phi_gen/system.param.GBRatio + system.states.tow_ss*system.param.TwTrans2Roll;
        QD_DrTr= states[phi_rot_d] - states[phi_gen_d]/GBRatio + states[tow_ss_d]*TwTrans2Roll;
        out.collectData();
    }
    
    printf("Simulation done\n");
    out.write(out_file_name, "Output of TurbineSimulator simulation");
    
    if(DISCON.finish())
        printf("%s\n", DISCON.getMessage().c_str());

    return res;
}

bool DISCON_Step(double t, DISCON_Interface &DISCON, double *states, double *inputs) {
    DISCON.current_time= t;
    
    DISCON.wind_speed_hub= inputs[vwind];
    DISCON.yaw_error_meas= 0;
    DISCON.abs_yaw= 0;
    DISCON.gen_torque_meas= inputs[Tgen];
    DISCON.rot_speed_meas= states[phi_rot_d];
    DISCON.gen_speed_meas= states[phi_gen_d];
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
