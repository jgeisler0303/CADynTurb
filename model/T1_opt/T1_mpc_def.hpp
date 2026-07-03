#pragma once

#include "T1_est_ekf.hpp"
#include "acados_solver_T1_opt_acados.h"
#include "acados_c/ocp_nlp_interface.h" // for further_ocp_setup

#include "T1_mpc_params.hpp"

#define T1_mpc_max_msg_char 512

#define OPC_PREFIX_UPPER T1_OPT
#define OPC_PREFIX T1_opt

const double ts= 0.01;
const int mpc_rate_f= 10;

const int ocp_state_tow_fa_idx= 0;
const int ocp_state_Tgen_idx= 1;
const int ocp_state_theta_idx= 2;
const int ocp_state_tow_fa_d_idx= 3;
const int ocp_state_phi_rot_d_idx= 4;

const int ocp_in_dTgen_idx= 0;
const int ocp_in_dtheta_idx= 1;

char T1_mpc_msg[T1_mpc_max_msg_char];

const char *further_ocp_setup(T1_opt_acados_solver_capsule *acados_ocp_capsule, char *accInfile = nullptr) {
    (void)accInfile; // suppress warnings if not using this argument
    if (!acados_ocp_capsule) {
        return "acados_ocp_capsule is null.";
    }

    ocp_nlp_config *nlp_config = T1_opt_acados_acados_get_nlp_config(acados_ocp_capsule);
    ocp_nlp_dims *nlp_dims = T1_opt_acados_acados_get_nlp_dims(acados_ocp_capsule);
    ocp_nlp_in *nlp_in = T1_opt_acados_acados_get_nlp_in(acados_ocp_capsule);
    ocp_nlp_out *nlp_out = T1_opt_acados_acados_get_nlp_out(acados_ocp_capsule);
    ocp_nlp_solver *nlp_solver = T1_opt_acados_acados_get_nlp_solver(acados_ocp_capsule);
    void *nlp_opts = T1_opt_acados_acados_get_nlp_opts(acados_ocp_capsule);

    if (!nlp_config || !nlp_dims || !nlp_in || !nlp_out || !nlp_solver || !nlp_opts) {
        return "Failed to get one or more acados NLP pointers.";
    }

    T1_mpcParameters mpc_params;
    mpc_params.setFromFile(std::string(accInfile), true);
    if(mpc_params.unsetParamsWithMsg()) {
        snprintf(T1_mpc_msg, T1_mpc_max_msg_char, "Not all MPC parameters could be read from the file. Terminating.");
        for(auto const &i : mpc_params.info_map) {
            if(!i.second.isSet) {
                const size_t len = strnlen(T1_mpc_msg, T1_mpc_max_msg_char);
                if(len < static_cast<size_t>(T1_mpc_max_msg_char) - 1) {
                    snprintf(T1_mpc_msg + len, T1_mpc_max_msg_char - len, "\n%s", i.first.c_str());
                }
            }
        }

        return T1_mpc_msg;
    }

    int max_iter = mpc_params.getParam("max_iter");
    ocp_nlp_solver_opts_set(nlp_config, nlp_opts, "max_iter", &max_iter);
    
    // move blocking
    // double u0[NU];
    // u0[0]= 0.0;
    // u0[1]= 0.0;
    // for (int i = 100; i < N; i++)
    // {
    //     ocp_nlp_constraints_model_set(nlp_config, nlp_dims, nlp_in, i, "lbu", u0);
    //     ocp_nlp_constraints_model_set(nlp_config, nlp_dims, nlp_in, i, "ubu", u0);
    // }
    return nullptr;
}
