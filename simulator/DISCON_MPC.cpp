// g++ -shared -o DISCON_MPC.dll DISCON_MPC.cpp -fPIC

#include <stdio.h>
#include <stdlib.h>
#include <string>

#include "acados/utils/print.h"
#include "acados/utils/math.h"
#include "acados_c/ocp_nlp_interface.h"
#include "acados_c/external_function_interface.h"
#include "blasfeo_d_aux_ext_dep.h"

#include "discon_swap.h"

#define STRINGIFY(X)  #X
#define EXPAND_AND_STRINGIFY(X) STRINGIFY(X)
#define CONCAT(A, B) A##B
#define EXPAND_AND_CONCAT(A, B) CONCAT(A, B)
#define CONCAT_AND_STRINGIFY(A, B) STRINGIFY(A##B)
#define EXPAND_CONCAT_STRINGIFY(A,B) CONCAT_AND_STRINGIFY(A,B)

#include EXPAND_AND_STRINGIFY(MPC_DEF)
#include "EKF_autotune.hpp"
#include EXPAND_CONCAT_STRINGIFY(OPC_PREFIX, _param.hpp)

#ifdef _WIN32
    #define DLL_EXPORT __declspec(dllexport)
#else
    #define DLL_EXPORT __attribute__((visibility("default")))
#endif

#define N      EXPAND_AND_CONCAT(OPC_PREFIX_UPPER,_ACADOS_N)
#define NX     EXPAND_AND_CONCAT(OPC_PREFIX_UPPER,_ACADOS_NX)
#define NP     EXPAND_AND_CONCAT(OPC_PREFIX_UPPER,_ACADOS_NP)
#define NU     EXPAND_AND_CONCAT(OPC_PREFIX_UPPER,_ACADOS_NU)
#define NBX0   EXPAND_AND_CONCAT(OPC_PREFIX_UPPER,_ACADOS_NBX0)
#define NP_GLOBAL   EXPAND_AND_CONCAT(OPC_PREFIX_UPPER,_ACADOS_NP_GLOBAL)


bool initialized= false;
bool first_run= true;
double last_time= 0.0;
uint32_t k_step= 0;

double Tgen= 0.0;
double theta= 0.0;
double solU[NU];


EKF_autotune<EKF_STATES, EKF_SYSTEM> ekf;
EXPAND_AND_CONCAT(OPC_PREFIX,_acados_solver_capsule) *acados_ocp_capsule= nullptr;
EXPAND_AND_CONCAT(OPC_PREFIX,Parameters) ocp_params;

void init_MPC(avrSwap_t *avrSwap, int32_t *aviFail, char *accInfile, char *avcOutname, char *avcMsg);
void step_MPC(avrSwap_t *avrSwap, int32_t *aviFail, char *accInfile, char *avcOutname, char *avcMsg, bool first_run);
void finish_MPC(avrSwap_t *avrSwap, int32_t *aviFail, char *accInfile, char *avcOutname, char *avcMsg);


extern "C" DLL_EXPORT void DISCON(avrSwap_t *avrSwap, int32_t *aviFail, char *accInfile, char *avcOutname, char *avcMsg) {
    aviFail[0]= 0;
    
    if(avrSwap->sim_status==0) {
        if(initialized) {
            aviFail[0]= 1;
            strncpy(avcMsg, "Trying to initialize DISCON twice", avrSwap->max_msg_char);
            return;
        }
        try {
            init_MPC(avrSwap, aviFail, accInfile, avcOutname, avcMsg);
            if(aviFail[0]==0) {
                initialized= true;
                first_run= true;
            }
        } catch(std::exception &e) {
            avrSwap->sim_status=-1;
            DISCON(avrSwap, aviFail, accInfile, avcOutname, avcMsg);
            aviFail[0]= 1;
            strncpy(avcMsg, e.what(), avrSwap->max_msg_char);
            return;
        }
        
    } else if(avrSwap->sim_status==1) {
        if(!initialized) {
            avrSwap->sim_status=-1;
            aviFail[0]= 1;
            strncpy(avcMsg, "Trying to use DISCON before initialization. Terminating.", avrSwap->max_msg_char);
            return;            
        }
        if(first_run) {
            if(avrSwap->current_time!=0.0)  {
                aviFail[0]= 1;
                snprintf(avcMsg, avrSwap->max_msg_char, "Please start simulation at 0 seconds (is %f s)", avrSwap->current_time);
            }
        } else {
            double current_ts= avrSwap->current_time-last_time;
            if(current_ts < (0.98*ts) || current_ts > (1.02*ts)) {
                avrSwap->sim_status=-1;
                DISCON(avrSwap, aviFail, accInfile, avcOutname, avcMsg);
                aviFail[0]= 1;
                snprintf(avcMsg, avrSwap->max_msg_char, "Sampling time must be 0.01 seconds (is: %f). Terminating.", current_ts);
                return;
            }
        }
        
        try {
            step_MPC(avrSwap, aviFail, accInfile, avcOutname, avcMsg, first_run);
            first_run= false;
            last_time= avrSwap->current_time;
        } catch(std::exception &e) {
            avrSwap->sim_status=-1;
            DISCON(avrSwap, aviFail, accInfile, avcOutname, avcMsg);
            aviFail[0]= 1;
            strncpy(avcMsg, e.what(), avrSwap->max_msg_char);
            return;
        }
        
    } else if(avrSwap->sim_status==-1) {
        if(!initialized) {
            aviFail[0]= 1;
            strncpy(avcMsg, "Trying to finish DISCON before initialization", avrSwap->max_msg_char);
            return;                        
        }
        finish_MPC(avrSwap, aviFail, accInfile, avcOutname, avcMsg);
        initialized= false;
        last_time= 0.0;
        k_step= 0;
    }
}

void init_MPC(avrSwap_t *avrSwap, int32_t *aviFail, char *accInfile, char *avcOutname, char *avcMsg) {
    // Create Solver
    if(acados_ocp_capsule!=nullptr) {
        EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_free)(acados_ocp_capsule);
        EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_free_capsule)(acados_ocp_capsule);
        snprintf(avcMsg, avrSwap->max_msg_char, "OCP was already initialized. This is bad. Terminating.");
        aviFail[0]= 1;
        avrSwap->sim_status=-1;
        return;
    }
        
    acados_ocp_capsule = EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_create_capsule)();
    // there is an opportunity to change the number of shooting intervals in C without new code generation
    // allocate the array and fill it accordingly
    double* new_time_steps = NULL;
    int status = EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_create_with_discretization)(acados_ocp_capsule, N, new_time_steps);

    if (status) {
        EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_free)(acados_ocp_capsule);
        EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_free_capsule)(acados_ocp_capsule);
        acados_ocp_capsule= nullptr;
        snprintf(avcMsg, avrSwap->max_msg_char, EXPAND_AND_STRINGIFY(OPC_PREFIX)"_acados_acados_create() returned status %d. Terminating.", status);
        aviFail[0]= 1;
        avrSwap->sim_status=-1;
        return;
    }
    
    // Set Parameters
    ocp_params.setFromFile(std::string(accInfile), true);
    if(ocp_params.unsetParamsWithMsg()) {
        snprintf(avcMsg, avrSwap->max_msg_char, "Not all OCP parameters could be read from the file. Terminating.");
        aviFail[0]= 1;
        EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_free)(acados_ocp_capsule);
        EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_free_capsule)(acados_ocp_capsule);
        acados_ocp_capsule= nullptr;
        avrSwap->sim_status=-1;
        return;
    }
    std::vector<double> vec(ocp_params.getNumParameters());
    ocp_params.getParamArray(vec.data());
    
    for (int i = 0; i <= N; i++) {
        int status= EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_update_params)(acados_ocp_capsule, i, vec.data(), NP);
        if (status) {
            snprintf(avcMsg, avrSwap->max_msg_char, EXPAND_AND_STRINGIFY(OPC_PREFIX)"_acados_acados_update_params() returned status %d. Terminating.", status);
            aviFail[0]= 1;
            EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_free)(acados_ocp_capsule);
            EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_free_capsule)(acados_ocp_capsule);
            acados_ocp_capsule= nullptr;
            avrSwap->sim_status=-1;
            return;
        }
    }

    // Further Setup
    // TODO: make constraints parameters
    if(further_ocp_setup(acados_ocp_capsule)) {
        snprintf(avcMsg, avrSwap->max_msg_char, "Something went wrong during further OCP setup. Terminating.");
        aviFail[0]= 1;
        EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_free)(acados_ocp_capsule);
        EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_free_capsule)(acados_ocp_capsule);
        acados_ocp_capsule= nullptr;
        avrSwap->sim_status=-1;
        return;
    }

    // Setup EKF estimated states
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

    // Set EKF Parameters
    ekf.system.param.setFromFile(std::string(accInfile), true);
    if(ekf.system.param.unsetParamsWithMsg()) {
        snprintf(avcMsg, avrSwap->max_msg_char, "Not all EKF parameters could be read from the file. Terminating.");
        aviFail[0]= 1;
        EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_free)(acados_ocp_capsule);
        EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_free_capsule)(acados_ocp_capsule);
        acados_ocp_capsule= nullptr;
        avrSwap->sim_status=-1;
        return;
    }
    
    ekf.system.AbsTol= 1e6;
    ekf.system.RelTol= 1e6;
    ekf.system.StepTol= 1e6;
    ekf.system.hminmin= 1E-8;
    ekf.system.jac_recalc_step= 10;
    ekf.system.max_steps= 1;
    
    ekf.system.q.setZero();
    ekf.system.qd.setZero();
    ekf.system.qdd.setZero();
    
    for(int i=0; i<ekf.nbrstates; ++i)
        ekf.x_ul(i)= x_ul[i]; // TODO: make Parameter
    for(int i=0; i<ekf.nbrstates; ++i)
        ekf.x_ll(i)= x_ll[i];

    ekf.ekfSigma.setIdentity();
    ekf.ekfQ.setIdentity();
    ekf.ekfQ*= 1.0e-6;
    ekf.ekfR.setIdentity();

    ekf.T_adapt= 30.0;
        
    ekf.system.precalcConsts();
}

void step_MPC(avrSwap_t *avrSwap, int32_t *aviFail, char *accInfile, char *avcOutname, char *avcMsg, bool first_run) {
    if(first_run) {
        // control states
        Tgen= avrSwap->gen_torque_meas; // TODO: calculate from wind gen_speed
        theta= avrSwap->blade1_pitch;
        
        ekf.system.states.phi_rot_d= avrSwap->rot_speed_meas;
        // TODO: add all possible EKF states
        ekf.system.states.vwind= avrSwap->wind_speed_hub;
        double fixedQxx[]= {0.0, avrSwap->wind_speed_hub*0.1, 0.0, 0.0}; // assume 10% TI TODO: implement moving turbulence estimator
        for(int i=0; i<ekf.nbrstates; ++i)
            ekf.fixedQxx(i)= fixedQxx[i];
    }
    ekf.system.inputs.dvwind= 0.0;
    ekf.system.inputs.Tgen= Tgen;
    ekf.system.inputs.theta= theta;
    
    EKF_autotune<EKF_STATES, EKF_SYSTEM>::VecO y_meas_vec;
    y_meas_vec(ekf.system.outputs_idx.tow_fa_acc)= avrSwap->f_a_acc;
    y_meas_vec(ekf.system.outputs_idx.gen_speed)= avrSwap->gen_speed_meas;
    // TODO: add all possible EKF outputs
                    
    ekf.next(ts, y_meas_vec);

    if((k_step%mpc_rate_f)==0) {
        ocp_nlp_config *nlp_config = EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_get_nlp_config)(acados_ocp_capsule);
        ocp_nlp_dims *nlp_dims = EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_get_nlp_dims)(acados_ocp_capsule);
        ocp_nlp_in *nlp_in = EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_get_nlp_in)(acados_ocp_capsule);
        ocp_nlp_out *nlp_out = EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_get_nlp_out)(acados_ocp_capsule);
        // ocp_nlp_solver *nlp_solver = EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_get_nlp_solver)(acados_ocp_capsule);
        // void *nlp_opts = EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_get_nlp_opts)(acados_ocp_capsule);
        
        // initial condition
        double x0[NBX0];
        // TODO: add all possible other ocp states
        x0[ocp_state_tow_fa_idx] = ekf.system.states.tow_fa;
        x0[ocp_state_Tgen_idx] = Tgen;
        x0[ocp_state_theta_idx] = theta;
        x0[ocp_state_tow_fa_d_idx] = ekf.system.states.tow_fa_d;
        x0[ocp_state_phi_rot_d_idx] = ekf.system.states.phi_rot_d;

        ocp_nlp_constraints_model_set(nlp_config, nlp_dims, nlp_in, 0, "lbx", x0);
        ocp_nlp_constraints_model_set(nlp_config, nlp_dims, nlp_in, 0, "ubx", x0);

        double u0[NU];
        if(k_step==0) {
            u0[0] = 0.0;
            u0[1] = 0.0;
            // initialize solution
            for (int i = 0; i < N; i++)
            {
                ocp_nlp_out_set(nlp_config, nlp_dims, nlp_out, i, "x", x0);
                ocp_nlp_out_set(nlp_config, nlp_dims, nlp_out, i, "u", u0);
            }
            ocp_nlp_out_set(nlp_config, nlp_dims, nlp_out, N, "x", x0);
        } /* else { // shift solution
            for (int i = 0; i < N-1; i++)
            {
                ocp_nlp_out_get(nlp_config, nlp_dims, nlp_out, i+1, "x", x0);
                ocp_nlp_out_get(nlp_config, nlp_dims, nlp_out, i+1, "u", u0);

                ocp_nlp_out_set(nlp_config, nlp_dims, nlp_out, i, "x", x0);
                ocp_nlp_out_set(nlp_config, nlp_dims, nlp_out, i, "u", u0);
            }
            ocp_nlp_out_get(nlp_config, nlp_dims, nlp_out, N, "x", x0);
            ocp_nlp_out_set(nlp_config, nlp_dims, nlp_out, N-1, "x", x0);
            ocp_nlp_out_set(nlp_config, nlp_dims, nlp_out, 0, "x", x0);
        }*/
        
        int status;
        int wind_idx= ocp_params.info_map["vwind"].offset;
        for (int i = 0; i <= N; i++) {
            status = EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_update_params_sparse)(acados_ocp_capsule, i, &wind_idx, &ekf.system.states.vwind, 1);        
            if (status) {
                snprintf(avcMsg, avrSwap->max_msg_char, "Setting wind parameter returned status %d.", status);
                aviFail[0]= 1;
            }
        }
        
        status = EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_solve)(acados_ocp_capsule);

        if(status!=0 && status!=2) {
            snprintf(avcMsg, avrSwap->max_msg_char, EXPAND_AND_STRINGIFY(OPC_PREFIX)"_acados_acados_solve() returned status %d.", status);
            aviFail[0]= 1;
        }
        
        ocp_nlp_out_get(nlp_config, nlp_dims, nlp_out, 0, "u", solU);
    }

    Tgen= Tgen + ts*solU[ocp_in_dTgen_idx];
    theta= theta + ts*solU[ocp_in_dtheta_idx];
    
    avrSwap->gen_torque_dem= Tgen;
    avrSwap->pitch_coll_dem= -theta;
    
    k_step++;
}

void finish_MPC(avrSwap_t *avrSwap, int32_t *aviFail, char *accInfile, char *avcOutname, char *avcMsg) {
    // free solver
    int status= 0;
    if(acados_ocp_capsule!=nullptr)
        status= EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_free)(acados_ocp_capsule);
    
    if (status) {
        aviFail[0]= 1;
        snprintf(avcMsg, avrSwap->max_msg_char, EXPAND_AND_STRINGIFY(OPC_PREFIX)"_acados_acados_free() returned status %d.", status);
        return;
    }
    // free solver capsule
    if(acados_ocp_capsule!=nullptr)
        status = EXPAND_AND_CONCAT(OPC_PREFIX,_acados_acados_free_capsule)(acados_ocp_capsule);
    
    if (status) {
        aviFail[0]= 1;
        snprintf(avcMsg, avrSwap->max_msg_char, EXPAND_AND_STRINGIFY(OPC_PREFIX)"_acados_acados_free_capsule() returned status %d.", status);
    }
    acados_ocp_capsule= nullptr;
}
