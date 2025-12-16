#include "T1_est_ekf.hpp"
#include "acados_solver_T1_opt_acados.h"
#include "acados_c/ocp_nlp_interface.h" // for further_ocp_setup

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
const int ocp_in_dtheta_idx= 0;

int further_ocp_setup(T1_opt_acados_solver_capsule *acados_ocp_capsule) {
    ocp_nlp_config *nlp_config = T1_opt_acados_acados_get_nlp_config(acados_ocp_capsule);
    ocp_nlp_dims *nlp_dims = T1_opt_acados_acados_get_nlp_dims(acados_ocp_capsule);
    ocp_nlp_in *nlp_in = T1_opt_acados_acados_get_nlp_in(acados_ocp_capsule);
    ocp_nlp_out *nlp_out = T1_opt_acados_acados_get_nlp_out(acados_ocp_capsule);
    ocp_nlp_solver *nlp_solver = T1_opt_acados_acados_get_nlp_solver(acados_ocp_capsule);
    void *nlp_opts = T1_opt_acados_acados_get_nlp_opts(acados_ocp_capsule);
    
    // move blocking
    double u0[NU];
    u0[0]= 0.0;
    u0[1]= 0.0;
    for (int i = 100; i < N; i++)
    {
        ocp_nlp_constraints_model_set(nlp_config, nlp_dims, nlp_in, i, "lbu", u0);
        ocp_nlp_constraints_model_set(nlp_config, nlp_dims, nlp_in, i, "ubu", u0);
    }
    return 0;
}
