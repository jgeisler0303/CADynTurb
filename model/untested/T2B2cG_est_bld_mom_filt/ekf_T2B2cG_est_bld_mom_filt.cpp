#include <iostream>
#include <stdlib.h>
#include <chrono>
#include <cstdio>
#include <ctime>
#include <cmath>
#include <cxxopts.hpp>
#include <Eigen/Dense>

#include "fast_output.h"
#include "fast_input.h"
#include "fast_parent_param.h"
#include "fast_wind.h"

#include "T2B2cG_est_bld_mom_filt_direct.hpp"
#include "EKF_autotune.hpp"

const int estimated_q[]= {
    T2B2cG_est_bld_mom_filt::states_idx.tow_fa,
    T2B2cG_est_bld_mom_filt::states_idx.tow_ss,
    T2B2cG_est_bld_mom_filt::states_idx.bld_flp,
    T2B2cG_est_bld_mom_filt::states_idx.bld_edg,
    T2B2cG_est_bld_mom_filt::states_idx.Dphi_gen,
    T2B2cG_est_bld_mom_filt::states_idx.vwind 
};
const int estimated_dq[]= {
    T2B2cG_est_bld_mom_filt::states_idx.tow_fa,
    T2B2cG_est_bld_mom_filt::states_idx.tow_ss,
    T2B2cG_est_bld_mom_filt::states_idx.bld_flp,
    T2B2cG_est_bld_mom_filt::states_idx.bld_edg,
    T2B2cG_est_bld_mom_filt::states_idx.phi_rot,
    T2B2cG_est_bld_mom_filt::states_idx.Dphi_gen 
};

const double x_ul[]= { 2.0,  1.0,  10.0,  3.0,  M_PI, 40.0,  100.0,  100.0,  100.0,  100.0, 50.0/30.0*M_PI,  500.0/30.0*M_PI};
const double x_ll[]= {-2.0, -1.0, -10.0, -3.0, -M_PI,  2.0, -100.0, -100.0, -100.0, -100.0,            0.0, -500.0/30.0*M_PI};  
const double adaptScale[]= {1.0, 1.0, 1.0, 100.0, 100.0};

typedef EKF_autotune<12, T2B2cG_est_bld_mom_filt> T2B2cG_bld_mom_filt_ekf;

double HSShftV;
double HSShftA;
double RotPwr;
double HSShftPwr;
double Q_DrTr;
double QD_DrTr;
double Q_GeAz;
double LSSTipPxa;
double wind_adjust;

void setupOutputs(FAST_Output &out, const T2B2cG_est_bld_mom_filt &system);
void setExtraOutputs(const T2B2cG_est_bld_mom_filt &system);

int main(int argc, char* argv[]) {
    bool error_flag= false;
    T2B2cG_bld_mom_filt_ekf ekf;
    std::string in_name;
    std::string out_name;
    double ts= 0.01;
    int NT= 0;
    Eigen::Matrix<double, Eigen::Dynamic, Eigen::Dynamic> uu;
    Eigen::Matrix<double, Eigen::Dynamic, Eigen::Dynamic> yy;

    // set states to estimate
    {
        int x_idx= 0;
        for(int i= 0; i<ekf.nbrdof; ++i) {
            ekf.qx_idx(i)= -1;
            for(int j= 0; j<(int)(sizeof(estimated_q)/sizeof(estimated_q[0])); ++j) {
                if(i==estimated_q[j]) {
                    ekf.qx_idx(i)= x_idx;
                    x_idx++;
                    break;
                }
            }
        }
        for(int i= 0; i<ekf.nbrdof; ++i) {
            ekf.dqx_idx(i)= -1;
            for(int j= 0; j<(int)(sizeof(estimated_dq)/sizeof(estimated_dq[0])); ++j) {
                if(i==estimated_dq[j]) {
                    ekf.dqx_idx(i)= x_idx;
                    x_idx++;
                    break;
                }
            }
        }
    }      
    
    // set state clipping limits
    for(int i=0; i<ekf.nbrstates; ++i)
        ekf.x_ul(i)= x_ul[i];
    for(int i=0; i<ekf.nbrstates; ++i)
        ekf.x_ll(i)= x_ll[i];
    
    // set adaption scaling
    for(int i=0; i<ekf.nbrout; ++i)
        ekf.adaptScale(i)= adaptScale[i];
    
    ekf.system.StepTol= 1e6;
    ekf.system.AbsTol= 1e6;
    ekf.system.RelTol= 1e6;
    ekf.system.hminmin= 1E-8;
    ekf.system.jac_recalc_step= 10;
    ekf.system.max_steps= 1;

    
    cxxopts::Options argc_options(argv[0], "Stand alone execution of EKF for outb input data");
    argc_options.add_options()
    ("p,paramfile", "Parameter file name", cxxopts::value<std::string>()->default_value("./params.txt"))
    ("i,input", "Input file name", cxxopts::value<std::string>()->default_value("input.outb"))
    ("o,output", "Output file name", cxxopts::value<std::string>()->default_value("default.outb"))
    ("a,t_adapt", "EKF tuning adaption time constant", cxxopts::value<double>()->default_value("30.0"))
    ("c,config", "Options file for the integration algorithm (default: newmark_options.txt)", cxxopts::value<std::string>()->default_value("newmark_options.txt"))
    ;
    
    argc_options.parse_positional({"input"});
    argc_options.positional_help("Input file name from OpenFAST simulation"); //.show_positional_help();
    
    if(argc<2) {
        std::cout << argc_options.help() << std::endl;
        exit (EXIT_SUCCESS);
    }
        
    auto argc_result = argc_options.parse(argc, argv);

    {
        double t_adapt;
        try {
            t_adapt= argc_result["t_adapt"].as<double>();
            ekf.T_adapt= t_adapt;
        } catch (const std::exception& e) {
            fprintf(stderr, "Could not set t_adapt: %f\n", t_adapt);
        }
    }

    if(argc_result.count("config")) {
        try {
            ekf.system.setOptionsFromFile(argc_result["config"].as<std::string>());
        } catch (const std::exception& e) {
            fprintf(stderr, "Options file error: %s\n", e.what());
            exit (EXIT_FAILURE);
        }
    }
    try {
        ekf.system.param.setFromFile(argc_result["paramfile"].as<std::string>());
    } catch (const std::exception& e) {
        fprintf(stderr, "Parameter file error: %s\n", e.what());
        exit (EXIT_FAILURE);
    }
    if(ekf.system.param.unsetParamsWithMsg()) {
        fprintf(stderr, "\nAll parameters have to be set. Exiting.\n");
        exit (EXIT_FAILURE);            
    }
    if(argc_result.count("input")) {
        try {
            in_name= argc_result["input"].as<std::string>();
            FAST_Input in(in_name);
            ts= in.time[1]-in.time[0];
            NT= in.NT;
            
            uu.resize(ekf.system.nbrin, NT);
            yy.resize(ekf.system.nbrout, NT);

            std::string sensor_name;
            try {
                ekf.system.q.setZero();
                sensor_name= "Wind1VelX";
                ekf.system.q(ekf.system.states_idx.vwind)= in.data.at(sensor_name)[0];
                ekf.system.qd.setZero();
                sensor_name= "HSShftV";
                ekf.system.qd(ekf.system.states_idx.phi_rot)= in.data.at(sensor_name)[0]/30.0*M_PI/ekf.system.param.GBRatio;
                ekf.system.qdd.setZero();
                
                uu.row(ekf.system.inputs_idx.dvwind).setZero();
                
                sensor_name= "GenTq";
                uu.row(ekf.system.inputs_idx.Tgen)= Eigen::Map<Eigen::VectorXd> (in.data.at(sensor_name).data(), NT);
                uu.row(ekf.system.inputs_idx.Tgen)*= 1000.0;
                
                sensor_name= "BlPitchC";
                if(in.data.find(sensor_name)!=in.data.end()) {
                    uu.row(ekf.system.inputs_idx.theta)= Eigen::Map<Eigen::VectorXd> (in.data.at(sensor_name).data(), NT);
                } else {
                    sensor_name= "BlPitchC1";
                    auto& BlPitchC1= in.data.at(sensor_name);
                    sensor_name= "BlPitchC2";
                    auto& BlPitchC2= in.data.at(sensor_name);
                    sensor_name= "BlPitchC3";
                    auto& BlPitchC3= in.data.at(sensor_name);
                    uu.row(ekf.system.inputs_idx.theta)= (Eigen::Map<Eigen::VectorXd> (BlPitchC1.data(), NT) + Eigen::Map<Eigen::VectorXd> (BlPitchC2.data(), NT) + Eigen::Map<Eigen::VectorXd> (BlPitchC3.data(), NT))/3.0;
                }
                uu.row(ekf.system.inputs_idx.theta)*= -M_PI/180.0;

                sensor_name= "RootMxb";
                if(in.data.find(sensor_name)!=in.data.end()) {
                    uu.row(ekf.system.inputs_idx.bld_edg_mom_meas)= Eigen::Map<Eigen::VectorXd> (in.data.at(sensor_name).data(), NT);
                } else {
                    sensor_name= "RootMxb1";
                    auto& RootMxb1= in.data.at(sensor_name);
                    sensor_name= "RootMxb2";
                    auto& RootMxb2= in.data.at(sensor_name);
                    sensor_name= "RootMxb3";
                    auto& RootMxb3= in.data.at(sensor_name);
                    uu.row(ekf.system.inputs_idx.bld_edg_mom_meas)= (Eigen::Map<Eigen::VectorXd> (RootMxb1.data(), NT) + Eigen::Map<Eigen::VectorXd> (RootMxb2.data(), NT) + Eigen::Map<Eigen::VectorXd> (RootMxb3.data(), NT))/3.0;
                }
                uu.row(ekf.system.inputs_idx.bld_edg_mom_meas)*= 1000.0;

                sensor_name= "RootMyb";
                if(in.data.find(sensor_name)!=in.data.end()) {
                    uu.row(ekf.system.inputs_idx.bld_flp_mom_meas)= Eigen::Map<Eigen::VectorXd> (in.data.at(sensor_name).data(), NT);
                } else {
                    sensor_name= "RootMyb1";
                    auto& RootMyb1= in.data.at(sensor_name);
                    sensor_name= "RootMyb2";
                    auto& RootMyb2= in.data.at(sensor_name);
                    sensor_name= "RootMyb3";
                    auto& RootMyb3= in.data.at(sensor_name);
                    uu.row(ekf.system.inputs_idx.bld_flp_mom_meas)= (Eigen::Map<Eigen::VectorXd> (RootMyb1.data(), NT) + Eigen::Map<Eigen::VectorXd> (RootMyb2.data(), NT) + Eigen::Map<Eigen::VectorXd> (RootMyb3.data(), NT))/3.0;
                }
                uu.row(ekf.system.inputs_idx.bld_flp_mom_meas)*= 1000.0;

                sensor_name= "YawBrTAxp";
                yy.row(ekf.system.outputs_idx.tow_fa_acc)= Eigen::Map<Eigen::VectorXd> (in.data.at(sensor_name).data(), NT);

                sensor_name= "YawBrTAyp";
                yy.row(ekf.system.outputs_idx.tow_ss_acc)= Eigen::Map<Eigen::VectorXd> (in.data.at(sensor_name).data(), NT);

                sensor_name= "HSShftV";
                yy.row(ekf.system.outputs_idx.gen_speed)= Eigen::Map<Eigen::VectorXd> (in.data.at(sensor_name).data(), NT);
                yy.row(ekf.system.outputs_idx.gen_speed)*= M_PI/30.0;
                
                yy.row(ekf.system.outputs_idx.r_bld_edg_mom_filt).setZero();
                yy.row(ekf.system.outputs_idx.r_bld_flp_mom_filt).setZero();                

            } catch (const std::exception& e) {
                fprintf(stderr, "Error reading input sensor \"%s\", cause: %s\n", sensor_name.c_str(), e.what());
                exit (EXIT_FAILURE);
            }            
        } catch (const std::exception& e) {
            fprintf(stderr, "Error reading input file: %s\n", e.what());
            exit (EXIT_FAILURE);
        }            
    } else {
        fprintf(stderr, "No input file was supplied\n");
        exit (EXIT_FAILURE);        
    }
    
    if(argc_result.count("output")) {
        out_name= argc_result["output"].as<std::string>();
    } else {
        out_name= argc_result["input"].as<std::string>();
        out_name.replace(out_name.end()-5, out_name.end(), "_ekf.outb");
    }
    
    FAST_Output out(NT);
    out.setTime(0.0, ts);
    setupOutputs(out, ekf.system);
    
    ekf.system.precalcConsts();

    printf("Starting simulation\n");
    std::clock_t startcputime = std::clock();
    int i= 0;
    try {
        for(i= 0; i<NT; ++i) {
            if(i>0) {
                ekf.system.u= uu.col(i-1);
                    
                ekf.next(ts, yy.col(i));
            } else {
                ekf.system.u= uu.col(0);
                ekf.system.newmarkOneStep(0.0);
                ekf.system.calcOut();
            }                
            setExtraOutputs(ekf.system);
            out.collectData();
        }
    } catch(std::exception &e) {
        fprintf(stderr, "Error in EKF loop: %s\n", e.what());
        error_flag= true;
    }
    double cpu_duration = (std::clock() - startcputime) / (double)CLOCKS_PER_SEC;
    
    out.write(out_name, "Output of EKF simulation");
    std::cout << "Run-time of ekf: " << cpu_duration << " seconds after " << i << " time steps" << std::endl;        
    
    if(error_flag)
        exit (EXIT_FAILURE);
    else
        exit (EXIT_SUCCESS);
}

void setupOutputs(FAST_Output &out, const T2B2cG_est_bld_mom_filt &system) {
    out.addChannel("Q_BF1", "m", &system.states.bld_flp);
    out.addChannel("Q_BE1", "m", &system.states.bld_edg);
    out.addChannel("QD_BF1", "m/s", &system.states.bld_flp_d);
    out.addChannel("QD_BE1", "m/s", &system.states.bld_edg_d);
//     out.addChannel("TipDxb", "m", &system.q.data()[3]*blade_frame_49_phi0_1_1 + &system.q.data()[4]);
//     out.addChannel("TipDyb", "m", &system.q.data()[4]);
    out.addChannel("PtchPMzc", "deg", &system.theta_deg);
    out.addChannel("LSSTipPxa", "deg", &LSSTipPxa, 180.0/M_PI);
    out.addChannel("Q_GeAz", "rad", &Q_GeAz);
    out.addChannel("Q_DrTr", "rad", &Q_DrTr);    
    out.addChannel("QD_DrTr", "rad/s", &QD_DrTr);    
    out.addChannel("LSSTipVxa", "rpm", &system.states.phi_rot_d, 30.0/M_PI);
    out.addChannel("LSSTipAxa", "deg/s^2", &system.states.phi_rot_dd, 180.0/M_PI);
    out.addChannel("HSShftV", "rpm", &HSShftV);
    out.addChannel("HSShftA", "deg/s^2", &HSShftA);
    out.addChannel("YawBrTDxp", "m", &system.states.tow_fa);
    out.addChannel("YawBrTDyp", "m", &system.states.tow_ss);
    out.addChannel("YawBrTVxp", "m/s", &system.states.tow_fa_d);
    out.addChannel("YawBrTVyp", "m/s", &system.states.tow_ss_d);
    out.addChannel("YawBrTAxp", "m/s^2", &system.states.tow_fa_dd);
    out.addChannel("YawBrTAyp", "m/s^2", &system.states.tow_ss_dd);
    out.addChannel("Q_TFA1", "m", &system.states.tow_fa);
    out.addChannel("QD_TFA1", "m/s", &system.states.tow_fa_d);
    out.addChannel("Q_TSS1", "m", &system.states.tow_ss, -1.0);
    out.addChannel("QD_TSS1", "m/s", &system.states.tow_ss_d, -1.0);
//    out.addChannel("YawBrRDyt", "deg", &system.states.tow_fa, system.param.TwTrans2Roll*180.0/M_PI);
//    out.addChannel("YawBrRDxt", "deg", &system.states.tow_ss, system.param.TwTrans2Roll*180.0/M_PI);
//    out.addChannel("YawBrRVyp", "deg/s", &system.states.tow_fa_d, system.param.TwTrans2Roll*180.0/M_PI);
//    out.addChannel("YawBrRVxp", "deg/s", &system.states.tow_ss_d, system.param.TwTrans2Roll*180.0/M_PI);
    out.addChannel("RootFxc", "kN", &system.Fthrust, 1.0/3000.0);
    out.addChannel("RootMxc", "kNm", &system.Trot, 1.0/3000.0);
    out.addChannel("LSShftFxa", "kN", &system.Fthrust, 1.0/1000.0);
    out.addChannel("LSShftMxa", "kNm", &system.Trot, 1.0/1000.0);
    out.addChannel("RotPwr", "kW", &RotPwr, 1.0/1000.0);
    out.addChannel("HSShftTq", "kNm", &system.inputs.Tgen, 1.0/1000.0);
    out.addChannel("HSShftPwr", "kW", &HSShftPwr, 1.0/1000.0);
    out.addChannel("RtVAvgxh", "m/s", &system.states.vwind);
    out.addChannel("RtTSR", "-", &system.lam);
    out.addChannel("RtAeroCq", "-", &system.cm);
    out.addChannel("RtAeroCt", "-", &system.ct);
    out.addChannel("RotCf", "-", &system.cflp);
    out.addChannel("RotCe", "-", &system.cedg);
    out.addChannel("BlPitchC", "deg", &system.inputs.theta,  -180.0/M_PI);
    out.addChannel("GenTq", "kNm", &system.inputs.Tgen, 1.0/1000.0);
}

void setExtraOutputs(const T2B2cG_est_bld_mom_filt &system) {
    HSShftV= (system.states.phi_rot_d*system.param.GBRatio + system.states.Dphi_gen_d)*30.0/M_PI;
    HSShftA= (system.states.phi_rot_dd*system.param.GBRatio + system.states.Dphi_gen_dd)*180.0/M_PI;
    RotPwr= system.Trot*system.states.phi_rot_d;
    HSShftPwr= system.inputs.Tgen * HSShftV/30.0*M_PI;
    Q_GeAz= std::fmod(system.states.phi_rot + system.states.Dphi_gen/system.param.GBRatio+M_PI*3.0/2.0, 2*M_PI);
    LSSTipPxa= std::fmod(system.states.phi_rot, 2*M_PI);
    Q_DrTr= -system.states.Dphi_gen/system.param.GBRatio + system.states.tow_ss*system.param.TwTrans2Roll;
    QD_DrTr= -system.states.Dphi_gen_d/system.param.GBRatio + system.states.tow_ss_d*system.param.TwTrans2Roll;    
}
