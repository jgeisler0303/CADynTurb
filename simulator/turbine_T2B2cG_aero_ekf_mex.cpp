#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mex.h"
#ifndef  HAVE_OCTAVE
#include "matrix.h"
#endif

#include "turbine_T2B2cG_aero_est_direct.hpp"
#include "EKF.hpp"

#define rhs_idx_x0 0
#define rhs_idx_u 1
#define rhs_idx_y 2
#define rhs_idx_p 3
#define rhs_idx_ts 4
#define rhs_idx_x_ul 5
#define rhs_idx_x_ll 6
#define rhs_idx_Q 7
#define rhs_idx_R 8
#define rhs_idx_N 9
#define rhs_idx_opt 10

#define lhs_idx_q 0
#define lhs_idx_qd 1
#define lhs_idx_qdd 2
#define lhs_idx_y 3
#define lhs_idx_time 4

typedef EKF<7, 3, 3, 12, real_type, turbine_T2B2cG_aero_estSystem> turbine_T2B2cG_aero_ekf;
const int estimated_q[]= {
    turbine_T2B2cG_aero_estSystem::states_idx.tow_fa,
    turbine_T2B2cG_aero_estSystem::states_idx.tow_ss,
    turbine_T2B2cG_aero_estSystem::states_idx.bld_flp,
    turbine_T2B2cG_aero_estSystem::states_idx.bld_edg,
    turbine_T2B2cG_aero_estSystem::states_idx.Dphi_gen,
    turbine_T2B2cG_aero_estSystem::states_idx.vwind 
};
const int estimated_dq[]= {
    turbine_T2B2cG_aero_estSystem::states_idx.tow_fa,
    turbine_T2B2cG_aero_estSystem::states_idx.tow_ss,
    turbine_T2B2cG_aero_estSystem::states_idx.bld_flp,
    turbine_T2B2cG_aero_estSystem::states_idx.bld_edg,
    turbine_T2B2cG_aero_estSystem::states_idx.phi_rot,
    turbine_T2B2cG_aero_estSystem::states_idx.Dphi_gen 
};

bool tryGetOption(double *value, const char *name, const mxArray *mxOptions, int m__=1, int n__=1);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    if(nrhs==0 && nlhs==1) {
        plhs[0]= mxCreateDoubleMatrix(1, turbine_T2B2cG_aero_ekf::nbrstates, mxREAL);
        {
            int x_idx= 0;
            for(int j= 0; j<(int)(sizeof(estimated_q)/sizeof(estimated_q[0])); ++j) {
                if(x_idx<turbine_T2B2cG_aero_ekf::nbrstates) {
                    mxGetPr(plhs[0])[x_idx]= estimated_q[j]+1;
                    x_idx++;
                }
            }
            for(int j= 0; j<(int)(sizeof(estimated_dq)/sizeof(estimated_dq[0])); ++j) {
                if(x_idx<turbine_T2B2cG_aero_ekf::nbrstates) {
                    mxGetPr(plhs[0])[x_idx]= estimated_dq[j] + 1 + turbine_T2B2cG_aero_estSystem::nbrdof;
                    x_idx++;
                }
            }
        }        
        return;
    }
    
    if(nrhs<10 || nrhs>11) { mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Wrong number of arguments. Expecting (x0, u, y, param, ts, x_ul, x_ll, Q, R, N, {options})"); return; }
    if(nlhs<4 || nlhs>5) { mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Wrong number of return values. Expecting [q, qd, qdd, y, {cpu_time}]"); return; }
    
    if(!mxIsDouble(prhs[rhs_idx_x0]) || mxGetNumberOfElements(prhs[rhs_idx_x0])!=turbine_T2B2cG_aero_ekf::nbrstates) { mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Wrong number of elements in 'x0' (%d expected)", turbine_T2B2cG_aero_ekf::nbrstates); return; }
    
    if(!mxIsDouble(prhs[rhs_idx_u]) || mxGetM(prhs[rhs_idx_u])!=turbine_T2B2cG_aero_ekf::nbrin) { mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Wrong number of rows in 'u' (%d expected)", turbine_T2B2cG_aero_ekf::nbrin); return; }
    if(!mxIsDouble(prhs[rhs_idx_u]) || mxGetN(prhs[rhs_idx_u])<2) { mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Wrong number of columns in 'u' (at least %d expected)", 2); return; }
    
    if(!mxIsDouble(prhs[rhs_idx_y]) || mxGetM(prhs[rhs_idx_y])!=turbine_T2B2cG_aero_ekf::nbrout) { mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Wrong number of rows in 'y' (%d expected)", turbine_T2B2cG_aero_ekf::nbrout); return; }
    if(!mxIsDouble(prhs[rhs_idx_y]) || mxGetN(prhs[rhs_idx_y])!=mxGetN(prhs[rhs_idx_u])) { mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Wrong number of columns in 'y' (expected same as in u)"); return; }
    
    if(!mxIsDouble(prhs[rhs_idx_ts]) || mxGetNumberOfElements(prhs[rhs_idx_ts])!=1) { mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Wrong number of elements in 'ts' (1 expected)"); return; }
    
    if(!mxIsDouble(prhs[rhs_idx_x_ul]) || mxGetNumberOfElements(prhs[rhs_idx_x_ul])!=turbine_T2B2cG_aero_ekf::nbrstates) { mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Wrong number of elements in 'x_ul' (%d expected)", turbine_T2B2cG_aero_ekf::nbrstates); return; }

    if(!mxIsDouble(prhs[rhs_idx_x_ll]) || mxGetNumberOfElements(prhs[rhs_idx_x_ll])!=turbine_T2B2cG_aero_ekf::nbrstates) { mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Wrong number of elements in 'x_ll' (%d expected)", turbine_T2B2cG_aero_ekf::nbrstates); return; }

    if(!mxIsDouble(prhs[rhs_idx_Q]) || mxGetM(prhs[rhs_idx_Q])!=turbine_T2B2cG_aero_ekf::nbrstates || mxGetN(prhs[rhs_idx_Q])!=turbine_T2B2cG_aero_ekf::nbrstates) { mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Wrong number of rows/columns in 'Q' (%d/%d expected)", turbine_T2B2cG_aero_ekf::nbrstates, turbine_T2B2cG_aero_ekf::nbrstates); return; }
    
    if(!mxIsDouble(prhs[rhs_idx_R]) || mxGetM(prhs[rhs_idx_R])!=turbine_T2B2cG_aero_ekf::nbrout || mxGetN(prhs[rhs_idx_R])!=turbine_T2B2cG_aero_ekf::nbrout) { mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Wrong number of rows/columns in 'R' (%d/%d expected)", turbine_T2B2cG_aero_ekf::nbrout, turbine_T2B2cG_aero_ekf::nbrout); return; }
    
    if(!mxIsDouble(prhs[rhs_idx_N]) || mxGetM(prhs[rhs_idx_N])!=turbine_T2B2cG_aero_ekf::nbrstates || mxGetN(prhs[rhs_idx_N])!=turbine_T2B2cG_aero_ekf::nbrout) { mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Wrong number of rows/columns in 'N' (%d/%d expected, is: %d/%d)", turbine_T2B2cG_aero_ekf::nbrstates, turbine_T2B2cG_aero_ekf::nbrout, mxGetM(prhs[rhs_idx_N]), mxGetN(prhs[rhs_idx_N])); return; }

    const mxArray *mxParams= prhs[rhs_idx_p];
    if(!mxIsStruct(mxParams) || mxGetNumberOfElements(mxParams)!=1) {
        mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Input param must be a scalar struct.\n");
        return;
    }
    
    if(nrhs>rhs_idx_opt) {
        const mxArray *mxOptions= prhs[rhs_idx_opt];
        if(!mxIsStruct(mxOptions) || mxGetNumberOfElements(mxOptions)!=1) {
            mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Input options must be a scalar struct.\n");
            return;
        }
    }
    
    turbine_T2B2cG_aero_ekf ekf;
    {
        int x_idx= 0;
        for(int i= 0; i<turbine_T2B2cG_aero_estSystem::nbrdof; ++i) {
            ekf.qx_idx(i)= -1;
            for(int j= 0; j<(int)(sizeof(estimated_q)/sizeof(estimated_q[0])); ++j) {
                if(i==estimated_q[j]) {
                    ekf.qx_idx(i)= x_idx;
                    x_idx++;
                    break;
                }
            }
        }
        for(int i= 0; i<turbine_T2B2cG_aero_estSystem::nbrdof; ++i) {
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
    
    for(const auto &iter : ekf.system.param.info_map) {
        const mxArray *mxParam;
        if((mxParam= mxGetField(mxParams, 0, iter.first.c_str()))==NULL) {
            mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Required parameter '%s' is not member of parameters struct.\n", iter.first.c_str());
            return;
        }
        int m_= mxGetM(mxParam);
        int n_= mxGetN(mxParam);
        if(mxIsSparse(mxParam) || !mxIsDouble(mxParam) || m_!=iter.second.nrows || n_!=iter.second.ncols) {
            mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Parameter name '%s' must be a %dx%d matrix.\n", iter.first.c_str(), iter.second.nrows, iter.second.ncols);
            return;
        }
        ekf.system.param.setParam(iter.first.c_str(), mxGetPr(mxParam));
    }
    
    if(nrhs>=rhs_idx_opt) {
        const mxArray *mxOptions= prhs[rhs_idx_opt];
        double value;
        
        if(tryGetOption(&value, "AbsTol", mxOptions))
            ekf.system.AbsTol= value;
        
        if(tryGetOption(&value, "RelTol", mxOptions))
            ekf.system.RelTol= value;

        if(tryGetOption(&value, "StepTol", mxOptions))
            ekf.system.StepTol= value;

        if(tryGetOption(&value, "hminmin", mxOptions))
            ekf.system.hminmin= value;

        if(tryGetOption(&value, "jac_recalc_step", mxOptions))
            ekf.system.jac_recalc_step= value;

        if(tryGetOption(&value, "max_steps", mxOptions))
            ekf.system.max_steps= value;
        
        
        double *doflocked= (double*)mxMalloc(turbine_T2B2cG_aero_ekf::nbrdof*sizeof(double));
        if(tryGetOption(doflocked, "doflocked", mxOptions, turbine_T2B2cG_aero_ekf::nbrdof, 1)) {
            for(int i= 0; i<turbine_T2B2cG_aero_ekf::nbrdof; i++)
                ekf.system.doflocked[i]= doflocked[i]!=0.0;
        }
        mxFree(doflocked);
    }
    
    double *x0= mxGetPr(prhs[rhs_idx_x0]);
    {
        int x_idx= 0;
        for(int j= 0; j<(int)(sizeof(estimated_q)/sizeof(estimated_q[0])); ++j) {
            if(x_idx<turbine_T2B2cG_aero_ekf::nbrstates) {
                ekf.system.q(estimated_q[j])= x0[x_idx];
                x_idx++;
            }
        }
        for(int j= 0; j<(int)(sizeof(estimated_dq)/sizeof(estimated_dq[0])); ++j) {
            if(x_idx<turbine_T2B2cG_aero_ekf::nbrstates) {
                ekf.system.qd(estimated_dq[j])= x0[x_idx];
                x_idx++;
            }
        }
    }
    
    double *x_ul= mxGetPr(prhs[rhs_idx_x_ul]);
    for(int i=0; i<turbine_T2B2cG_aero_ekf::nbrstates; ++i)
        ekf.x_ul(i)= x_ul[i];
    double *x_ll= mxGetPr(prhs[rhs_idx_x_ll]);
    for(int i=0; i<turbine_T2B2cG_aero_ekf::nbrstates; ++i)
        ekf.x_ll(i)= x_ll[i];

    double *Q= mxGetPr(prhs[rhs_idx_Q]);
    for(int i=0; i<turbine_T2B2cG_aero_ekf::nbrstates; ++i)
        for(int j=0; j<turbine_T2B2cG_aero_ekf::nbrstates; ++j)
            ekf.ekfQ(i, j)= Q[i + j*turbine_T2B2cG_aero_ekf::nbrstates];

    double *R= mxGetPr(prhs[rhs_idx_R]);
    for(int i=0; i<turbine_T2B2cG_aero_ekf::nbrout; ++i)
        for(int j=0; j<turbine_T2B2cG_aero_ekf::nbrout; ++j)
            ekf.ekfR(i, j)= R[i + j*turbine_T2B2cG_aero_ekf::nbrout];

    double *N= mxGetPr(prhs[rhs_idx_N]);
    for(int i=0; i<turbine_T2B2cG_aero_ekf::nbrstates; ++i)
        for(int j=0; j<turbine_T2B2cG_aero_ekf::nbrout; ++j)
            ekf.ekfN(i, j)= N[i + j*turbine_T2B2cG_aero_ekf::nbrstates];
        
    double *u= mxGetPr(prhs[rhs_idx_u]);
    double *y_meas= mxGetPr(prhs[rhs_idx_y]);
    
    double ts= mxGetScalar(prhs[rhs_idx_ts]);
    
    ekf.system.precalcConsts();

    plhs[lhs_idx_q]= mxCreateDoubleMatrix(turbine_T2B2cG_aero_estSystem::nbrdof, mxGetN(prhs[rhs_idx_u]), mxREAL);
    plhs[lhs_idx_qd]= mxCreateDoubleMatrix(turbine_T2B2cG_aero_estSystem::nbrdof, mxGetN(prhs[rhs_idx_u]), mxREAL);
    plhs[lhs_idx_qdd]= mxCreateDoubleMatrix(turbine_T2B2cG_aero_estSystem::nbrdof, mxGetN(prhs[rhs_idx_u]), mxREAL);
    plhs[lhs_idx_y]= mxCreateDoubleMatrix(turbine_T2B2cG_aero_estSystem::nbrout, mxGetN(prhs[rhs_idx_u]), mxREAL);
    
    turbine_T2B2cG_aero_ekf::VecO y_meas_vec;
    
    std::clock_t startcputime = std::clock();
    try {
        for(int i= 0; i<(int)mxGetN(prhs[rhs_idx_u]); ++i) {
            if(i>0) {
                for(int j= 0; j<ekf.nbrin; ++j)
                    ekf.system.u(j)= u[j + (i-1)*ekf.nbrin];
                
                for(int j= 0; j<ekf.nbrout; ++j)
                    y_meas_vec(j)= y_meas[j + i*ekf.nbrout];
                    
                if(!ekf.next(ts, y_meas_vec)) {
                    mexErrMsgIdAndTxt("CADyn:Integrator", "Error in integrator");
                    break;
                }
            }
            for(int j=0; j<ekf.nbrdof; ++j)
                mxGetPr(plhs[lhs_idx_q])[j + i*ekf.nbrdof]= ekf.system.q(j);
            for(int j=0; j<ekf.nbrdof; ++j)
                mxGetPr(plhs[lhs_idx_qd])[j +i*ekf.nbrdof]= ekf.system.qd(j);
            for(int j=0; j<ekf.nbrdof; ++j)
                mxGetPr(plhs[lhs_idx_qdd])[j + i*ekf.nbrdof]= ekf.system.qdd(j);
            for(int j=0; j<ekf.nbrout; ++j)
                mxGetPr(plhs[lhs_idx_y])[j + i*ekf.nbrout]= ekf.system.y(j);
        }
    } catch(std::exception &e) {
        mexErrMsgIdAndTxt("CADyn:EKF", "Error EKF: %s", e.what());
    }
    double cpu_duration = (std::clock() - startcputime) / (double)CLOCKS_PER_SEC;
    
        
    if(nlhs>lhs_idx_time) {
        plhs[lhs_idx_time]= mxCreateDoubleMatrix(1, 1, mxREAL);
        mxGetPr(plhs[lhs_idx_time])[0]= cpu_duration;
    }    
}

bool tryGetOption(double *value, const char *name, const mxArray *mxOptions, int m__, int n__) {
    const mxArray *mxOption;
    if((mxOption= mxGetField(mxOptions, 0, name))!=NULL) {
        int m_= mxGetM(mxOption);
        int n_= mxGetN(mxOption);
        if(mxIsSparse(mxOption) || !mxIsDouble(mxOption) || (m_!=m__ && n_!=n__)) {
            mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Option name '%s' must be a scalar.\n", name);
            return false;
        }
        
        for(int i= 0; i<m__; i++)
            for(int j= 0; j<n__; j++)
                value[i + j*m__]= mxGetPr(mxOption)[i + j*m__];
        
        return true;
    }
    return false;
}
