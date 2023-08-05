// g++ -rdynamic -DBOOST_ALL_NO_LIB -DBOOST_ATOMIC_DYN_LINK -DBOOST_RANDOM_DYN_LINK -DBOOST_SYSTEM_DYN_LINK -DBOOST_TEST_DYN_LINK -DBOOST_THREAD_DYN_LINK -DNDEBUG -D_WEBSOCKETPP_CPP11_STL_ -g -std=c++17 -I. -I.. -Igen -I../../../CADyn/src -I../../../websocketpp turbine_T2B2cG_aero_server.cpp -ldl -o turbine_T2B2cG_aero_server -lpthread -lrt

#include <fstream>
#include <set>
#include <streambuf>
#include <string>
#include <sys/time.h>
#include <iostream>
#include <stdlib.h>
#include <chrono>
#include <cstdio>
#include <ctime>
#include <cmath>

#include <cxxopts.hpp>

#include <boost/bind.hpp>

#include <websocketpp/config/asio_no_tls.hpp>
#include <websocketpp/server.hpp>

#include "discon_interface.h"
#include "fast_output.h"
#include "fast_parent_param.h"
#include "fast_wind.h"

#include "turbine_T2B2cG_aero_direct.hpp"

bool DISCON_Step(double t, DISCON_Interface &DISCON, turbine_T2B2cG_aeroSystem &system);


class telemetry_server {
public:
    typedef websocketpp::connection_hdl connection_hdl;
    typedef websocketpp::server<websocketpp::config::asio> server;

    telemetry_server(std::string docroot,
                     uint16_t port,
                     turbine_T2B2cG_aeroSystem &system,
                     FAST_Wind *wind,
                     double simstep,
                     double simtime,
                     int down_sampling,
                     std::string discon_path) :
                     
                     m_docroot(docroot),
                     port(port),
                     system(system),
                     wind(wind),
                     simstep(simstep),
                     simtime(simtime),
                     down_sampling(down_sampling),
                     DISCON(discon_path),
                     curr_step(simtime),
                     sim_err(false),
                     timer_intervall(lround(simstep*1e6*double(down_sampling)))
    {
        // set up access channels to only log interesting things
        m_endpoint.clear_access_channels(websocketpp::log::alevel::all);
        m_endpoint.set_access_channels(websocketpp::log::alevel::access_core);
        m_endpoint.set_access_channels(websocketpp::log::alevel::app);

        // Initialize the Asio transport policy
        m_endpoint.init_asio();

        // Bind the handlers we are using
        using websocketpp::lib::placeholders::_1;
        using websocketpp::lib::bind;
        m_endpoint.set_open_handler(bind(&telemetry_server::on_open,this,_1));
        m_endpoint.set_close_handler(bind(&telemetry_server::on_close,this,_1));
        m_endpoint.set_http_handler(bind(&telemetry_server::on_http,this,_1));
        
        m_timer= new boost::asio::steady_timer(m_endpoint.get_io_service());
        
        init_sim();
    }

    void run() {
        std::stringstream ss;
        ss << "Running telemetry server on port "<< port <<" using docroot=" << m_docroot << " with timer intervall " << timer_intervall.count();
        m_endpoint.get_alog().write(websocketpp::log::alevel::app,ss.str());
        
        // listen on specified port
        m_endpoint.listen(port);

        // Start the server accept loop
        m_endpoint.start_accept();

        // Set the initial timer to start telemetry
        m_timer->expires_after(timer_intervall);
        m_timer->async_wait(boost::bind(&telemetry_server::on_timer, this, boost::asio::placeholders::error));


        // Start the ASIO io_service run loop
        try {
            m_endpoint.run();
        } catch (websocketpp::exception const & e) {
            std::cout << e.what() << std::endl;
        }
    }

    void on_timer(websocketpp::lib::error_code const & ec) {
        if (ec) {
            // there was an error, stop telemetry
            m_endpoint.get_alog().write(websocketpp::log::alevel::app,
                    "Timer Error: "+ec.message());
            return;
        }
        
        if(!sim_err && system.t<simtime) {
            std::stringstream val;
            val << "{" << std::endl
                << "\"DOFcontrols\" : {" << std::endl
                << "\"yawAngle\" : " << "0" << "," << std::endl
                << "\"pitchAngle\" : [" << system.theta_deg << "," << system.theta_deg << "," << system.theta_deg << "]," << std::endl
                << "\"rotationAngle\" : " << system.states.phi_rot << "," << std::endl
                << "\"q_BldFl1\" : " << system.states.bld_flp << "," << std::endl
                << "\"q_BldFl2\" : " << "0" << "," << std::endl
                << "\"q_BldEdg\" : " << system.states.bld_edg << "," << std::endl
                << "\"q_TwrFa1\" : " << system.states.tow_fa << "," << std::endl
                << "\"q_TwrFa2\" : " << "0" << "," << std::endl
                << "\"q_TwrSs1\" : " << system.states.tow_ss << "," << std::endl
                << "\"q_TwrSs2\" : " << "0" << std::endl
                << "}," << std::endl
                << "\"time\" : " << system.t << ","  << std::endl
                << "\"wind\" : " << system.inputs.vwind << std::endl
                << "}" << std::endl;            
            
            // m_endpoint.get_alog().write(websocketpp::log::alevel::app,val.str());
            // Broadcast count to all connections
            con_list::iterator it;
            for (it = m_connections.begin(); it != m_connections.end(); ++it) {
                // m_endpoint.get_alog().write(websocketpp::log::alevel::app,"Send");
                m_endpoint.send(*it,val.str(),websocketpp::frame::opcode::text);
            }
            
            sim_err= !sim_step();
            
            do {
                m_timer->expires_at(m_timer->expiry() + timer_intervall);
            } while(m_timer->expiry() < std::chrono::steady_clock::now());
            
//             if(m_timer->expiry() < std::chrono::steady_clock::now()) {
//                 std::stringstream ss;
//                 ss << "Error:  Timer overrun";
//                 
//                 DISCON.finish();
//                 
//                 m_endpoint.get_alog().write(websocketpp::log::alevel::app,ss.str());
//                 
//     //             m_endpoint.stop_perpetual();
//     //             m_endpoint.stop_listening();
//                 m_endpoint.stop();
//                 
//             } else {
                m_timer->async_wait(boost::bind(&telemetry_server::on_timer, this, boost::asio::placeholders::error));
//             }
        } else {
            std::stringstream ss;
            ss << "Simulation done";
            
            if(DISCON.finish())
                ss << ", DISCON message: " << DISCON.getMessage();
            
            m_endpoint.get_alog().write(websocketpp::log::alevel::app,ss.str());
            
//             m_endpoint.stop_perpetual();
//             m_endpoint.stop_listening();
            m_endpoint.stop();
        }
    }

    void on_http(connection_hdl hdl) {
        // Upgrade our connection handle to a full connection_ptr
        server::connection_ptr con = m_endpoint.get_con_from_hdl(hdl);
    
        std::ifstream file;
        std::string filename = con->get_resource();
        std::string response;
    
        m_endpoint.get_alog().write(websocketpp::log::alevel::app,
            "http request1: "+filename);
    
        if (filename == "/") {
            filename = m_docroot+"index.html";
        } else {
            filename = m_docroot+filename.substr(1);
        }
        
        m_endpoint.get_alog().write(websocketpp::log::alevel::app,
            "http request2: "+filename);
    
        file.open(filename.c_str(), std::ios::in);
        if (!file) {
            // 404 error
            std::stringstream ss;
        
            ss << "<!doctype html><html><head>"
               << "<title>Error 404 (Resource not found)</title><body>"
               << "<h1>Error 404</h1>"
               << "<p>The requested URL " << filename << " was not found on this server.</p>"
               << "</body></head></html>";
        
            con->set_body(ss.str());
            con->set_status(websocketpp::http::status_code::not_found);
            return;
        }
    
        file.seekg(0, std::ios::end);
        response.reserve(file.tellg());
        file.seekg(0, std::ios::beg);
    
        response.assign((std::istreambuf_iterator<char>(file)),
                        std::istreambuf_iterator<char>());
    
        con->set_body(response);
        con->set_status(websocketpp::http::status_code::ok);
        if(filename.compare(filename.size()-3, 3, ".js") == 0)
            con->append_header("Content-Type", "text/javascript");
    }

    void on_open(connection_hdl hdl) {
        m_connections.insert(hdl);
    }

    void on_close(connection_hdl hdl) {
        m_connections.erase(hdl);
    }
    
    void init_sim() {
        system.t= 0.0;

        system.inputs.vwind= wind->getWind(system.t);
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
        
        DISCON.comm_interval= simstep;
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
        
        if(DISCON.init()) {
            std::stringstream ss;
            ss << "DISCON message: " << DISCON.getMessage();
            m_endpoint.get_alog().write(websocketpp::log::alevel::app,ss.str());
        } 
    
        system.newmarkOneStep(0.0);
    }
    
    bool sim_step() {
        bool res= true;
        
        if(!DISCON_Step(system.t, DISCON, system)) {
            std::stringstream ss;
            ss << "DISCON finished at t=" << system.t;
            m_endpoint.get_alog().write(websocketpp::log::alevel::app,ss.str());
            res= false;
        }
            
        system.inputs.vwind= wind->getWind(system.t);
        if(!system.newmarkInterval(system.t+simstep*down_sampling, curr_step, simstep)) {
            res= false;
        }
            
        return res;
    }
    
private:
    typedef std::set<connection_hdl,std::owner_less<connection_hdl>> con_list;
    
    server m_endpoint;
    con_list m_connections;
    boost::asio::steady_timer *m_timer;
    
    std::string m_docroot;
    uint16_t port;
    turbine_T2B2cG_aeroSystem &system;
    FAST_Wind *wind;
    double simstep;
    double simtime;
    int down_sampling;
    DISCON_Interface DISCON;
    double curr_step;
    bool sim_err;
    std::chrono::microseconds timer_intervall;
};


double RotPwr;
double HSShftPwr;

int main(int argc, char* argv[]) {
    std::string docroot= "./";
    uint16_t port = 9002;
    
    turbine_T2B2cG_aeroSystem system;
    FAST_Wind* wind;
    double simtime;
    double simstep;
    int down_sampling;
    std::string discon_dll;
    
    cxxopts::Options argc_options(argv[0], "A simple wind turbine simulator");
    argc_options.add_options()
    ("p,paramfile", "Parameter file name", cxxopts::value<std::string>()->default_value("./params.txt"))
    ("t,simtime", "Simulation time", cxxopts::value<double>()->default_value("10"))
    ("s,simstep", "Simulation time", cxxopts::value<double>()->default_value("0.01"))
    ("d,discon_dll", "Path and name of the DISCON controller DLL", cxxopts::value<std::string>()->default_value("DISCON.dll"))
    ("o,output", "Output file name", cxxopts::value<std::string>()->default_value("default.outb"))
    ("n,num_steps", "Number of steps per update (down sampling)", cxxopts::value<int>()->default_value("1"))
    ("x,dx_wind", "Offset into wind field in m", cxxopts::value<double>()->default_value("0.0"))
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
            FAST_Parent_Parameters p(argc_result["fast"].as<std::string>());

            simtime= (argc_result.count("simtime"))? argc_result["simtime"].as<double>(): p["TMax"];
            simstep= (argc_result.count("simstep"))? argc_result["simstep"].as<double>(): p["DT"];
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
        } catch (const std::exception& e) {
            fprintf(stderr, "FAST input error: %s\n", e.what());
            exit (EXIT_FAILURE);
        }
    } else {
        fprintf(stderr, "No FAST main input file was supplied\n");
        exit (EXIT_FAILURE);        
    }
    
    down_sampling= argc_result["num_steps"].as<int>();
    
    std::cout << "Simulating with options:" << std::endl;
    std::cout << "  simstep=" << simstep << std::endl;
    std::cout << "  simtime=" << simtime << std::endl;
    std::cout << "  down sampling=" << down_sampling << std::endl;
    std::cout << "  discon_dll=" << discon_dll << std::endl;
    
    telemetry_server s(docroot,
                       port,
                       system,
                       wind,
                       simstep,
                       simtime,
                       down_sampling,
                       discon_dll);
    
    s.run();

    delete wind;
    exit (EXIT_SUCCESS);
}

// void setupOutputs(FAST_Output &out, turbine_T2B2cG_aeroSystem &system) {
//     out.addChannel("Q_BF1", "m", &system.states.bld_flp);
//     out.addChannel("Q_BE1", "m", &system.states.bld_edg);
//     out.addChannel("QD_BF1", "m/s", &system.states.bld_flp_d);
//     out.addChannel("QD_BE1", "m/s", &system.states.bld_edg_d);
//     out.addChannel("TipDxb", "m", &system.q.data()[3]*blade_frame_49_phi0_1_1 + &system.q.data()[4]);
//     out.addChannel("TipDyb", "m", &system.q.data()[4]);
//     out.addChannel("PtchPMzc", "deg", &system.theta_deg);
//     out.addChannel("LSSTipPxa", "deg", &system.states.phi_rot, 180.0/M_PI);
//     out.addChannel("Q_GeAz", "rad", &system.states.phi_gen);
//     out.addChannel("LSSTipVxa", "rpm", &system.states.phi_rot_d, 30.0/M_PI);
//     out.addChannel("LSSTipAxa", "deg/s^2", &system.states.phi_rot_dd, 180.0/M_PI);
//     out.addChannel("HSShftV", "rpm", &system.states.phi_gen_d, 30.0/M_PI);
//     out.addChannel("HSShftA", "deg/s^2", &system.states.phi_gen_dd, 180.0/M_PI);
//     out.addChannel("YawBrTDxp", "m", &system.states.tow_fa);
//     out.addChannel("YawBrTDyp", "m", &system.states.tow_ss);
//     out.addChannel("YawBrTVyp", "m/s", &system.states.tow_fa_d);
//     out.addChannel("YawBrTVxp", "m/s", &system.states.tow_ss_d);
//     out.addChannel("YawBrTAxp", "m/s^2", &system.states.tow_fa_dd);
//     out.addChannel("YawBrTAyp", "m/s^2", &system.states.tow_ss_dd);
//    out.addChannel("YawBrRDyt", "deg", &system.states.tow_fa, system.param.TwTrans2Roll*180.0/M_PI);
//    out.addChannel("YawBrRDxt", "deg", &system.states.tow_ss, system.param.TwTrans2Roll*180.0/M_PI);
//    out.addChannel("YawBrRVyp", "deg/s", &system.states.tow_fa_d, system.param.TwTrans2Roll*180.0/M_PI);
//    out.addChannel("YawBrRVxp", "deg/s", &system.states.tow_ss_d, system.param.TwTrans2Roll*180.0/M_PI);
//     out.addChannel("RootFxc", "kN", &system.Fthrust, 1.0/3000.0);
//     out.addChannel("RootMxc", "kNm", &system.Trot, 1.0/3000.0);
//     out.addChannel("LSShftFxa", "kN", &system.Fthrust, 1.0/1000.0);
//     out.addChannel("LSShftMxa", "kNm", &system.Trot, 1.0/1000.0);
//     out.addChannel("RotPwr", "kW", &RotPwr, 1.0/1000.0);
//     out.addChannel("HSShftTq", "kNm", &system.inputs.Tgen, 1.0/1000.0);
//     out.addChannel("HSShftPwr", "kW", &HSShftPwr, 1.0/1000.0);
//     out.addChannel("RtVAvgxh", "m/s", &system.inputs.vwind);
//     out.addChannel("WindVxi", "m/s", &system.inputs.vwind);
//     out.addChannel("Wind1VelX", "m/s", &system.inputs.vwind);
//     out.addChannel("RtTSR", "-", &system.lam);
//     out.addChannel("RtAeroCq", "-", &system.cm);
//     out.addChannel("RtAeroCt", "-", &system.ct);
//     out.addChannel("RotCf", "-", &system.cflp);
//     out.addChannel("RotCe", "-", &system.cedg);
//     out.addChannel("BlPitchC", "deg", &system.inputs.theta,  -180.0/M_PI);
//     out.addChannel("GenTq", "kNm", &system.inputs.Tgen, 1.0/1000.0);
//     out.addChannel("RootMxb", "-", &system.modalFlapForce);
//     out.addChannel("RootMyb", "-", &system.modalEdgeForce);
// }

bool DISCON_Step(double t, DISCON_Interface &DISCON, turbine_T2B2cG_aeroSystem &system) {
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
    
//     system.inputs.theta= -(1.0/3.0)*(DISCON.blade1_dem + DISCON.blade2_dem + DISCON.blade3_dem);
    system.inputs.theta= -DISCON.pitch_coll_dem;
    system.inputs.Tgen= DISCON.gen_torque_dem;
    
    if(((int)DISCON.safety_code_dem) != 0)
        printf("safety_code_dem: %f\n", DISCON.safety_code_dem);
    
    return DISCON.sim_status!=-1;
}
