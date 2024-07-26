#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "discon_interface.h"

#include "mex.h"
#ifndef  HAVE_OCTAVE
#include "matrix.h"
#endif

enum input_idx1 {
    in_idx_dll_path= 0,
    in_idx_discon_parameter,
    in_idx_config_path,
    in_idx1_last
};

enum input_idx2 {
    in_idx_t= 0,
    in_idx_vwind,
    in_idx_Tgen_in,
    in_idx_om_rot,
    in_idx_om_gen,
    in_idx_theta_in,
    in_idx_tow_fa_acc,
    in_idx_tow_ss_acc,
    in_idx_phi_rot,
    in_idx2_last
};

enum output_idx {
    out_idx_theta_out= 0,
    out_idx_Tgen_out,
    out_idx_sim_status,
    out_idx_last
};

DISCON_Interface* DISCON= nullptr;

bool tryGetOption(double *value, const char *name, const mxArray *mxOptions, int m__=1, int n__=1);
void DISCON_Step(DISCON_Interface& DISCON, double &theta_out, double &Tgen_out, int &sim_status, double t, double vwind, double Tgen_in, double om_rot, double om_gen, double theta_in, double tow_fa_acc, double tow_ss_acc, double phi_rot);
void setDISCONParams(DISCON_Interface& DISCON, const mxArray *mxParams);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    if((nrhs<(in_idx_discon_parameter+1) || nrhs>in_idx1_last) && nrhs!=0 && nrhs!=in_idx2_last) { mexErrMsgIdAndTxt("DISCON:InvalidArgument", "Wrong number of arguments. Expecting 0 or (dll_path {, config_path}) or (t, vwind, Tgen, om_rot, om_gen, theta, tow_fa_acc, tow_ss_acc, phi_rot)"); return; }
    
    // Terminate DLL
    if(nrhs==0) {
        if(nlhs!=0) { mexErrMsgIdAndTxt("DISCON:InvalidArgument", "Wrong number of return values. Expecting 0."); return; }
        
        if(DISCON==nullptr) {
            mexWarnMsgIdAndTxt("DISCON:InvalidOperation", "DISCON currently not loaded.");
            return;
        }
        mexPrintf("Terminating DISCON\n");
        if(DISCON->finish())
            mexPrintf("DISCON message: %s\n", DISCON->getMessage().c_str());
        delete DISCON;
        DISCON= nullptr;
    }
    // Initialize DLL
    else if(nrhs<=in_idx1_last) {
        if(nlhs!=0) { mexErrMsgIdAndTxt("DISCON:InvalidArgument", "Wrong number of return values. Expecting 0."); return; }

        const mxArray *mxParams= prhs[in_idx_discon_parameter];
        if(!mxIsStruct(mxParams) || mxGetNumberOfElements(mxParams)!=1) {
            mexErrMsgIdAndTxt("DISCON:InvalidArgument", "Input p must be a scalar struct.\n");
            return;
        }
        
        if(DISCON!=nullptr) {
            mexWarnMsgIdAndTxt("DISCON:InvalidOperation", "DISCON already loaded.");
            return;
        }
        
        if(!mxIsChar(prhs[in_idx_dll_path]) || (mxGetM(prhs[in_idx_dll_path]) != 1 )) { mexErrMsgIdAndTxt("DISCON:InvalidArgument", "Argument 'dll_path' must be a character array"); return; }
        const int buflen= 1024;
        char discon_path[buflen];
        int status = mxGetString(prhs[in_idx_dll_path], discon_path, (mwSize) buflen);
        if (status != 0) {
            mexErrMsgIdAndTxt( "DISCON:InvalidArgument", "Failed to copy dll_path into %d byte buffer.", buflen);
            return;
        }
        
        try {
            DISCON= new DISCON_Interface(std::string(discon_path));
            if(nlhs==(in_idx_config_path+1)) {
                if(!mxIsChar(prhs[in_idx_config_path]) || (mxGetM(prhs[in_idx_config_path]) != 1 )) { mexErrMsgIdAndTxt("DISCON:InvalidArgument", "Argument 'config_path' must be a character array"); return; }
                char config_path[buflen];
                int status = mxGetString(prhs[in_idx_config_path], config_path, (mwSize) buflen);
                if (status != 0) {
                    mexErrMsgIdAndTxt( "DISCON:InvalidArgument", "Failed to copy config_path into %d byte buffer.", buflen);
                    return;
                }
                
                DISCON= new DISCON_Interface(std::string(discon_path), std::string(config_path));
            }
            
            setDISCONParams(*DISCON, mxParams);
            
            if(DISCON->init())
                printf("%s\n", DISCON->getMessage().c_str());
        } catch (const std::exception& e) {
            mexErrMsgIdAndTxt("DISCON:Init", "DISCON Error: %s", e.what());
            return;
        }
    } else {
        if(nlhs!=out_idx_last) { mexErrMsgIdAndTxt("DISCON:InvalidArgument", "Wrong number of return values. Expecting [theta_set, Tgen_set, status]"); return; }
        
        if(!mxIsDouble(prhs[in_idx_t]) || mxGetNumberOfElements(prhs[in_idx_t])!=1) { mexErrMsgIdAndTxt("DISCON:InvalidArgument", "Input 't' must be scalar."); return; }
        if(!mxIsDouble(prhs[in_idx_vwind]) || mxGetNumberOfElements(prhs[in_idx_vwind])!=1) { mexErrMsgIdAndTxt("DISCON:InvalidArgument", "Input 'vwind' must be scalar."); return; }
        if(!mxIsDouble(prhs[in_idx_Tgen_in]) || mxGetNumberOfElements(prhs[in_idx_Tgen_in])!=1) { mexErrMsgIdAndTxt("DISCON:InvalidArgument", "Input 'Tgen_meas' must be scalar."); return; }
        if(!mxIsDouble(prhs[in_idx_om_rot]) || mxGetNumberOfElements(prhs[in_idx_om_rot])!=1) { mexErrMsgIdAndTxt("DISCON:InvalidArgument", "Input 'om_rot' must be scalar."); return; }
        if(!mxIsDouble(prhs[in_idx_om_gen]) || mxGetNumberOfElements(prhs[in_idx_om_gen])!=1) { mexErrMsgIdAndTxt("DISCON:InvalidArgument", "Input 'om_gen' must be scalar."); return; }
        if(!mxIsDouble(prhs[in_idx_theta_in]) || mxGetNumberOfElements(prhs[in_idx_theta_in])!=1) { mexErrMsgIdAndTxt("DISCON:InvalidArgument", "Input 'theta_meas' must be scalar."); return; }
        if(!mxIsDouble(prhs[in_idx_tow_fa_acc]) || mxGetNumberOfElements(prhs[in_idx_tow_fa_acc])!=1) { mexErrMsgIdAndTxt("DISCON:InvalidArgument", "Input 'tow_fa_acc' must be scalar."); return; }
        if(!mxIsDouble(prhs[in_idx_tow_ss_acc]) || mxGetNumberOfElements(prhs[in_idx_tow_ss_acc])!=1) { mexErrMsgIdAndTxt("DISCON:InvalidArgument", "Input 'tow_ss_acc' must be scalar."); return; }
        if(!mxIsDouble(prhs[in_idx_phi_rot]) || mxGetNumberOfElements(prhs[in_idx_phi_rot])!=1) { mexErrMsgIdAndTxt("DISCON:InvalidArgument", "Input 'phi_rot' must be scalar."); return; }
        
        double t= mxGetScalar(prhs[in_idx_t]);
        double vwind= mxGetScalar(prhs[in_idx_vwind]);
        double Tgen_in= mxGetScalar(prhs[in_idx_Tgen_in]);
        double om_rot= mxGetScalar(prhs[in_idx_om_rot]);
        double om_gen= mxGetScalar(prhs[in_idx_om_gen]);
        double theta_in= mxGetScalar(prhs[in_idx_theta_in]);
        double tow_fa_acc= mxGetScalar(prhs[in_idx_tow_fa_acc]);
        double tow_ss_acc= mxGetScalar(prhs[in_idx_tow_ss_acc]);
        double phi_rot= mxGetScalar(prhs[in_idx_phi_rot]);
        
        double theta_out;
        double Tgen_out;
        int sim_status;
        
        try {
            DISCON_Step(*DISCON, theta_out, Tgen_out, sim_status, t, vwind, Tgen_in, om_rot, om_gen, theta_in, tow_fa_acc, tow_ss_acc, phi_rot);
        } catch (const std::exception& e) {
            mexErrMsgIdAndTxt("DISCON:Step", "DISCON Error: %s", e.what());
            return;
        }

        plhs[out_idx_theta_out]= mxCreateDoubleMatrix(1, 1, mxREAL);
        mxGetPr(plhs[out_idx_theta_out])[0]= theta_out;
            
        plhs[out_idx_Tgen_out]= mxCreateDoubleMatrix(1, 1, mxREAL);
        mxGetPr(plhs[out_idx_Tgen_out])[0]= Tgen_out;

        plhs[out_idx_sim_status]= mxCreateDoubleMatrix(1, 1, mxREAL);
        mxGetPr(plhs[out_idx_sim_status])[0]= sim_status;
    }
}

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
        mexPrintf("%s\n", DISCON.getMessage().c_str());
    
//     system.inputs.theta= -(1.0/3.0)*(DISCON.blade1_dem + DISCON.blade2_dem + DISCON.blade3_dem);
    theta_out= DISCON.pitch_coll_dem;
    Tgen_out= DISCON.gen_torque_dem;
    
    if(((int)DISCON.safety_code_dem) != 0)
        mexPrintf("safety_code_dem: %f\n", DISCON.safety_code_dem);
    
    sim_status=  DISCON.sim_status;
}

bool tryGetOption(double *value, const char *name, const mxArray *mxOptions, int m__, int n__) {
    const mxArray *mxOption;
    if((mxOption= mxGetField(mxOptions, 0, name))!=NULL) {
        int m_= mxGetM(mxOption);
        int n_= mxGetN(mxOption);
        if(mxIsSparse(mxOption) || !mxIsDouble(mxOption) || (m_!=m__ && n_!=n__)) {
            mexErrMsgIdAndTxt("DISCON:InvalidArgument", "Option name '%s' must be a scalar.\n", name);
            return false;
        }
        
        for(int i= 0; i<m__; i++)
            for(int j= 0; j<n__; j++)
                value[i + j*m__]= mxGetPr(mxOption)[i + j*m__];
        
        return true;
    }
    return false;
}

void setDISCONParams(DISCON_Interface& DISCON, const mxArray *mxParams) {
    double value;
    
    if(tryGetOption(&value, "comm_interval", mxParams))
        DISCON.comm_interval= value;
    
    if(tryGetOption(&value, "Ptch_Min", mxParams))
        DISCON.min_pitch= value/180.0*M_PI;
    
    if(tryGetOption(&value, "Ptch_Max", mxParams))
        DISCON.max_pitch= value/180.0*M_PI;
    
    if(tryGetOption(&value, "PtchRate_Min", mxParams))
        DISCON.min_pitch_rate= value/180.0*M_PI;
    
    if(tryGetOption(&value, "PtchRate_Max", mxParams))
        DISCON.max_pitch_rate= value/180.0*M_PI;
    
    if(tryGetOption(&value, "pitch_actuator", mxParams))
        DISCON.pitch_actuator= value;
    
    if(tryGetOption(&value, "Gain_OM", mxParams))
        DISCON.opt_mode_gain= value;
    
    if(tryGetOption(&value, "GenSpd_MinOM", mxParams))
        DISCON.min_gen_speed= value/30.0*M_PI;
    
    if(tryGetOption(&value, "GenSpd_MaxOM", mxParams))
        DISCON.max_gen_speed= value/30.0*M_PI;
    
    if(tryGetOption(&value, "GenSpd_Dem", mxParams))
        DISCON.gen_speed_dem= value/30.0*M_PI;
    
    if(tryGetOption(&value, "GenTrq_Dem", mxParams))
        DISCON.gen_torque_sp= value;
    
    if(tryGetOption(&value, "GenPwr_Dem", mxParams))
        DISCON.power_dem= value;
    
    if(tryGetOption(&value, "Ptch_SetPnt", mxParams))
        DISCON.sp_pitch_partial= value/180.0*M_PI;
    
    if(tryGetOption(&value, "yaw_ctrl_mode", mxParams))
        DISCON.yaw_ctrl_mode= value;
    
    if(tryGetOption(&value, "num_blades", mxParams))
        DISCON.num_blades= value;
    
    if(tryGetOption(&value, "Ptch_Cntrl", mxParams))
        DISCON.pitch_ctrl_mode= value;
    
    if(tryGetOption(&value, "gen_contractor", mxParams))
        DISCON.gen_contractor= value;
    
    if(tryGetOption(&value, "controller_state", mxParams))
        DISCON.controller_state= value;
    
    if(tryGetOption(&value, "time_to_output", mxParams))
        DISCON.time_to_output= value;
    
    if(tryGetOption(&value, "version", mxParams))
        DISCON.version= value;
    
    DISCON.ts_lut_idx= 0;
    DISCON.ts_lut_len= 0;
}
