#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <Eigen/Dense>
#include <Eigen/Geometry>
#include "mex.h"

typedef Eigen::Matrix<double, Eigen::Dynamic, Eigen::Dynamic> MatCx;
typedef double real_type;

#include "interp_bicubic.c"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    if(nrhs!=9) { mexErrMsgIdAndTxt("test:InvalidArgument", "Wrong number of arguments. Expecting lambdaMin, lambdaMax, lambdaStep, thetaMin, thetaMax, thetaStep, lam, theta_deg, cp_tab"); return; }
    if(nlhs!=1) { mexErrMsgIdAndTxt("CADyn:InvalidArgument", "Wrong number of return values. Expecting cp"); return; }
    
    double lambdaMin= mxGetScalar(prhs[0]);
    double lambdaMax= mxGetScalar(prhs[1]);
    double lambdaStep= mxGetScalar(prhs[2]);
    double thetaMin= mxGetScalar(prhs[3]);
    double thetaMax= mxGetScalar(prhs[4]);
    double thetaStep= mxGetScalar(prhs[5]);
    double lam= mxGetScalar(prhs[6]);
    double theta_deg= mxGetScalar(prhs[7]);
    double  *cp_tab= mxGetPr(prhs[8]);
    
    
    MatCx cp_mat= Eigen::Map<MatCx>(cp_tab, mxGetM(prhs[8]), mxGetN(prhs[8]));
    
    plhs[0]= mxCreateDoubleMatrix(1, 1, mxREAL);
    double conv_poly[16];
    int lambdaIdx;
    int thetaIdx;
    
    calc_conv_poly(lambdaMin, lambdaMax, lambdaStep, thetaMin, thetaMax, thetaStep, lam, theta_deg, lambdaIdx, thetaIdx, conv_poly);

    mxGetPr(plhs[0])[0]= interp_bicubic(conv_poly, cp_mat, lambdaIdx, thetaIdx);
}
