#include <cmath>

#define LUT(tab) (thetaFact*(lambdaFact*tab(lambdaIdx, thetaIdx) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx)) + (1.0-thetaFact)*(lambdaFact*tab(lambdaIdx, thetaIdx+1) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx+1)))
#define DLAM_LUT(tab) ((thetaFact*(tab(lambdaIdx+1, thetaIdx)-tab(lambdaIdx, thetaIdx))/lambdaStep) + (1.0-thetaFact)*((tab(lambdaIdx+1, thetaIdx)-tab(lambdaIdx, thetaIdx))/lambdaStep))
#define DTH_LUT(tab) (( (lambdaFact*tab(lambdaIdx, thetaIdx+1) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx+1))-(lambdaFact*tab(lambdaIdx, thetaIdx) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx)) )/thetaStep * -180.0/M_PI)

typedef decltype(std::declval<T1B1i_est>().param.cm_lut) MatCx;

static double aeroForce(const int lambdaIdx, 
                        const double lambdaFact,
                        const int thetaIdx,
                        const double thetaFact,
                        const Eigen::Ref<const MatCx> &cx_lut,
                        const Eigen::Ref<const MatCx> &dcx_dvf_v_lut,
                        const Eigen::Ref<const MatCx> &dcx_dkappa_v_lut,
                        const double Fwind_v,
                        const double vwind_eff,
                        const double bld_flp_d,
                        const double kappa) {
    
    double cx_stat= LUT(cx_lut);
    double dcx_dvf_v= LUT(dcx_dvf_v_lut);
    double dcx_dkappa_v= LUT(dcx_dkappa_v_lut);

    return Fwind_v*(vwind_eff*cx_stat + bld_flp_d*dcx_dvf_v + kappa*dcx_dkappa_v);
}

void T1B1i_est::calculateExternal() {
    theta_deg1= -inputs.theta1/M_PI*180.0;
    theta_deg2= -inputs.theta2/M_PI*180.0;
    theta_deg3= -inputs.theta3/M_PI*180.0;
    
    double vwind_eff= states.vwind-states.tow_fa_d;
        
    double cone1_= param.cone+states.bld1_flp/param.Rrot*1.3;
    double cone2_= param.cone+states.bld2_flp/param.Rrot*1.3;
    double cone3_= param.cone+states.bld3_flp/param.Rrot*1.3;
    double tilt_= param.tilt + states.tow_fa*param.tower_frame_11_psi0_2_1;
    double u_1= (sin(states.phi_rot)*sin(inputs.theta1)-sin(cone1_)*cos(states.phi_rot)*cos(inputs.theta1))*sin(param.tilt)+cos(cone1_)*cos(inputs.theta1)*cos(tilt_);
    double u_2= (sin(states.phi_rot+2.0/3.0*M_PI)*sin(inputs.theta2)-sin(cone2_)*cos(states.phi_rot+2.0/3.0*M_PI)*cos(inputs.theta2))*sin(tilt_)+cos(cone2_)*cos(inputs.theta2)*cos(tilt_);
    double u_3= (sin(states.phi_rot+4.0/3.0*M_PI)*sin(inputs.theta3)-sin(cone3_)*cos(states.phi_rot+4.0/3.0*M_PI)*cos(inputs.theta3))*sin(tilt_)+cos(cone3_)*cos(inputs.theta3)*cos(tilt_);

    double vwind_eff1= vwind_eff*u_1;
    double vwind_eff2= vwind_eff*u_2;
    double vwind_eff3= vwind_eff*u_3;

    lam= states.phi_rot_d*param.Rrot/vwind_eff;
    double Fwind_v1= param.rho/2.0*param.Arot*u_1*u_1*vwind_eff1;
    double Fwind_v2= param.rho/2.0*param.Arot*u_2*u_2*vwind_eff2;
    double Fwind_v3= param.rho/2.0*param.Arot*u_3*u_3*vwind_eff3;
     
    if(lam>param.lambdaMax-param.lambdaStep) lam= param.lambdaMax-param.lambdaStep;
    if(lam<param.lambdaMin) lam= param.lambdaMin;
    if(theta_deg1>param.thetaMax-param.thetaStep) theta_deg1= param.thetaMax-param.thetaStep;
    if(theta_deg1<param.thetaMin) theta_deg1= param.thetaMin;
    if(theta_deg2>param.thetaMax-param.thetaStep) theta_deg2= param.thetaMax-param.thetaStep;
    if(theta_deg2<param.thetaMin) theta_deg2= param.thetaMin;
    if(theta_deg3>param.thetaMax-param.thetaStep) theta_deg3= param.thetaMax-param.thetaStep;
    if(theta_deg3<param.thetaMin) theta_deg3= param.thetaMin;
    
    double lambdaScaled= (lam-param.lambdaMin)/param.lambdaStep;
    int lambdaIdx= std::floor(lambdaScaled);
    double lambdaFact= 1.0 - lambdaScaled + lambdaIdx;
    
    double thetaScaled1= (theta_deg1-param.thetaMin)/param.thetaStep;
    int thetaIdx1= std::floor(thetaScaled1);
    double thetaFact1= 1.0 - thetaScaled1 + thetaIdx1;
    
    double thetaScaled2= (theta_deg2-param.thetaMin)/param.thetaStep;
    int thetaIdx2= std::floor(thetaScaled2);
    double thetaFact2= 1.0 - thetaScaled2 + thetaIdx2;

    double thetaScaled3= (theta_deg3-param.thetaMin)/param.thetaStep;
    int thetaIdx3= std::floor(thetaScaled3);
    double thetaFact3= 1.0 - thetaScaled3 + thetaIdx3;
    
    double kappa1= -states.h_shear*sin(states.phi_rot) + states.v_shear*cos(states.phi_rot);
    double kappa2= -states.h_shear*sin(states.phi_rot+2.0/3.0*M_PI) + states.v_shear*cos(states.phi_rot+2.0/3.0*M_PI);
    double kappa3= -states.h_shear*sin(states.phi_rot+4.0/3.0*M_PI) + states.v_shear*cos(states.phi_rot+4.0/3.0*M_PI);

    Trot1= param.Rrot*aeroForce(lambdaIdx, lambdaFact, thetaIdx1, thetaFact1, param.cm_lut, param.dcm_dvf_v_lut, param.dcm_dkappa_v_lut, Fwind_v1, vwind_eff1, states.bld1_flp_d, kappa1)/3.0;
    Trot2= param.Rrot*aeroForce(lambdaIdx, lambdaFact, thetaIdx2, thetaFact2, param.cm_lut, param.dcm_dvf_v_lut, param.dcm_dkappa_v_lut, Fwind_v2, vwind_eff2, states.bld2_flp_d, kappa2)/3.0;
    Trot3= param.Rrot*aeroForce(lambdaIdx, lambdaFact, thetaIdx3, thetaFact3, param.cm_lut, param.dcm_dvf_v_lut, param.dcm_dkappa_v_lut, Fwind_v3, vwind_eff3, states.bld3_flp_d, kappa3)/3.0;
    
    Fthrust1= aeroForce(lambdaIdx, lambdaFact, thetaIdx1, thetaFact1, param.ct_lut, param.dct_dvf_v_lut, param.dct_dkappa_v_lut, Fwind_v1, vwind_eff1, states.bld1_flp_d, kappa1)/3.0;
    Fthrust2= aeroForce(lambdaIdx, lambdaFact, thetaIdx2, thetaFact2, param.ct_lut, param.dct_dvf_v_lut, param.dct_dkappa_v_lut, Fwind_v2, vwind_eff2, states.bld2_flp_d, kappa2)/3.0;
    Fthrust3= aeroForce(lambdaIdx, lambdaFact, thetaIdx3, thetaFact3, param.ct_lut, param.dct_dvf_v_lut, param.dct_dkappa_v_lut, Fwind_v3, vwind_eff3, states.bld3_flp_d, kappa3)/3.0;

    MyD23_1= param.Rrot*aeroForce(lambdaIdx, lambdaFact, thetaIdx1, thetaFact1, param.cmy_D23_lut, param.dcmy_D23_dvf_v_lut, param.dcmy_D23_dkappa_v_lut, Fwind_v1, vwind_eff1, states.bld1_flp_d, kappa1);
    MyD23_2= param.Rrot*aeroForce(lambdaIdx, lambdaFact, thetaIdx2, thetaFact2, param.cmy_D23_lut, param.dcmy_D23_dvf_v_lut, param.dcmy_D23_dkappa_v_lut, Fwind_v2, vwind_eff2, states.bld2_flp_d, kappa2);
    MyD23_3= param.Rrot*aeroForce(lambdaIdx, lambdaFact, thetaIdx3, thetaFact3, param.cmy_D23_lut, param.dcmy_D23_dvf_v_lut, param.dcmy_D23_dkappa_v_lut, Fwind_v3, vwind_eff3, states.bld3_flp_d, kappa3);
    
    modalFlapForce1= aeroForce(lambdaIdx, lambdaFact, thetaIdx1, thetaFact1, param.cf_lut, param.dcf_dvf_v_lut, param.dcf_dkappa_v_lut, Fwind_v1, vwind_eff1, states.bld1_flp_d, kappa1);
    modalFlapForce2= aeroForce(lambdaIdx, lambdaFact, thetaIdx2, thetaFact2, param.cf_lut, param.dcf_dvf_v_lut, param.dcf_dkappa_v_lut, Fwind_v2, vwind_eff2, states.bld2_flp_d, kappa2);
    modalFlapForce3= aeroForce(lambdaIdx, lambdaFact, thetaIdx3, thetaFact3, param.cf_lut, param.dcf_dvf_v_lut, param.dcf_dkappa_v_lut, Fwind_v3, vwind_eff3, states.bld3_flp_d, kappa3);
}

static void aeroForceAndDerivs(const int lambdaIdx, 
                               const double lambdaFact,
                               const int thetaIdx,
                               const double thetaFact,
                               const double lambdaStep,
                               const double thetaStep,
                               const double u_, 
                               const Eigen::Ref<const MatCx> &cx_lut,
                               const Eigen::Ref<const MatCx> &dcx_dvf_v_lut,
                               const Eigen::Ref<const MatCx> &dcx_dkappa_v_lut,
                               double Fwind,
                               double Fwind_v,
                               double vwind_eff,
                               const double bld_flp_d,
                               const double phi_rot,
                               const double bld_offset,
                               const double h_shear,
                               const double v_shear,
                               const double torque_R,
                               const double dlam_dvw,
                               const double dlam_dvtow,
                               const double dlam_dphi_rot_d,
                               const double dFwind_dvtow,
                               const double dFwind_dvw,
                               double &X,
                               double &dX_dtow_fa_d,
                               double &dX_dphi_rot_d,
                               double &dX_dbld_flp_d,
                               double &dX_dh_shear,
                               double &dX_dv_shear,
                               double &dX_dvwind,
                               double &dX_dtheta,
                               double &dX_dphi_rot) {
    
    Fwind= Fwind*u_*u_*u_*u_;
    Fwind_v= Fwind_v*u_*u_*u_;
    vwind_eff= vwind_eff*u_;

    double kappa= -h_shear*sin(phi_rot+bld_offset) + v_shear*cos(phi_rot+bld_offset);

    double cx_stat= LUT(cx_lut);
    double dcx_dvf_v= LUT(dcx_dvf_v_lut);
    double dcx_dkappa_v= LUT(dcx_dkappa_v_lut);

    X= torque_R*Fwind_v*(vwind_eff*cx_stat + bld_flp_d*dcx_dvf_v + kappa*dcx_dkappa_v);
    
    double dcx_dlam= DLAM_LUT(cx_lut);
    
    double dcx_dvw= dcx_dlam * dlam_dvw;
    double dcx_dvtow= dcx_dlam * dlam_dvtow;
    double dcx_dphi_rot_d= dcx_dlam * dlam_dphi_rot_d;
    
    double dcx_dtheta= DTH_LUT(cx_lut);
    
    dX_dtow_fa_d= torque_R*(dFwind_dvtow*cx_stat + Fwind*dcx_dvtow);    // TODO to be exact, the derivative of the edge and flap terms is missing here?
    dX_dphi_rot_d= torque_R*Fwind*dcx_dphi_rot_d;                          // TODO to be exact, the derivative of the edge and flap terms is missing here 
    dX_dbld_flp_d= torque_R*Fwind_v * dcx_dvf_v;
    dX_dh_shear= -torque_R*Fwind_v * dcx_dkappa_v * sin(phi_rot+bld_offset);
    dX_dv_shear= torque_R*Fwind_v * dcx_dkappa_v * cos(phi_rot+bld_offset);
    dX_dvwind= torque_R*(dFwind_dvw*cx_stat + Fwind*dcx_dvw);      // TODO to be exact, the derivative of the edge and flap terms is missing here 
    dX_dtheta= torque_R*Fwind*dcx_dtheta;                        // TODO to be exact, the derivative of the edge and flap terms is missing here 
    dX_dphi_rot= torque_R*Fwind_v * dcx_dkappa_v * (-h_shear*cos(phi_rot+bld_offset) - v_shear*sin(phi_rot+bld_offset));
}

void T1B1i_est::calculateExternalWithDeriv() {
    theta_deg1= -inputs.theta1/M_PI*180.0;
    theta_deg2= -inputs.theta2/M_PI*180.0;
    theta_deg3= -inputs.theta3/M_PI*180.0;
    
    double vwind_eff= states.vwind-states.tow_fa_d;
    lam= states.phi_rot_d*param.Rrot/vwind_eff;
    double Fwind= param.rho/2.0*param.Arot*vwind_eff*vwind_eff;
    double Fwind_v= param.rho/2.0*param.Arot*vwind_eff;
    
    if(lam>param.lambdaMax-param.lambdaStep) lam= param.lambdaMax-param.lambdaStep;
    if(lam<param.lambdaMin) lam= param.lambdaMin;
    if(theta_deg1>param.thetaMax-param.thetaStep) theta_deg1= param.thetaMax-param.thetaStep;
    if(theta_deg1<param.thetaMin) theta_deg1= param.thetaMin;
    if(theta_deg2>param.thetaMax-param.thetaStep) theta_deg2= param.thetaMax-param.thetaStep;
    if(theta_deg2<param.thetaMin) theta_deg2= param.thetaMin;
    if(theta_deg3>param.thetaMax-param.thetaStep) theta_deg3= param.thetaMax-param.thetaStep;
    if(theta_deg3<param.thetaMin) theta_deg3= param.thetaMin;
    
    double lambdaScaled= (lam-param.lambdaMin)/param.lambdaStep;
    int lambdaIdx= std::floor(lambdaScaled);
    double lambdaFact= 1.0 - lambdaScaled + lambdaIdx;
    
    double thetaScaled1= (theta_deg1-param.thetaMin)/param.thetaStep;
    int thetaIdx1= std::floor(thetaScaled1);
    double thetaFact1= 1.0 - thetaScaled1 + thetaIdx1;
    
    double thetaScaled2= (theta_deg2-param.thetaMin)/param.thetaStep;
    int thetaIdx2= std::floor(thetaScaled2);
    double thetaFact2= 1.0 - thetaScaled2 + thetaIdx2;

    double thetaScaled3= (theta_deg3-param.thetaMin)/param.thetaStep;
    int thetaIdx3= std::floor(thetaScaled3);
    double thetaFact3= 1.0 - thetaScaled3 + thetaIdx3;
    
    double dFwind_dvw   =  2*Fwind_v; // 2*Fwind/vwind;
    double dFwind_dvtow = -2*Fwind_v; // -2*Fwind/vwind;
    
    double dlam_dvw   = -lam/states.vwind;
    double dlam_dvtow =  lam/states.vwind;
    double dlam_dphi_rot_d= lam/states.phi_rot_d;

    double cone1_= param.cone+states.bld1_flp/param.Rrot*1.3;
    double cone2_= param.cone+states.bld2_flp/param.Rrot*1.3;
    double cone3_= param.cone+states.bld3_flp/param.Rrot*1.3;
    double tilt_= param.tilt + states.tow_fa*param.tower_frame_11_psi0_2_1;
    double u_1= (sin(states.phi_rot)*sin(inputs.theta1)-sin(cone1_)*cos(states.phi_rot)*cos(inputs.theta1))*sin(param.tilt)+cos(cone1_)*cos(inputs.theta1)*cos(tilt_);
    double u_2= (sin(states.phi_rot+2.0/3.0*M_PI)*sin(inputs.theta2)-sin(cone2_)*cos(states.phi_rot+2.0/3.0*M_PI)*cos(inputs.theta2))*sin(tilt_)+cos(cone2_)*cos(inputs.theta2)*cos(tilt_);
    double u_3= (sin(states.phi_rot+4.0/3.0*M_PI)*sin(inputs.theta3)-sin(cone3_)*cos(states.phi_rot+4.0/3.0*M_PI)*cos(inputs.theta3))*sin(tilt_)+cos(cone3_)*cos(inputs.theta3)*cos(tilt_);

    aeroForceAndDerivs(lambdaIdx, lambdaFact, thetaIdx1, thetaFact1, param.lambdaStep, param.thetaStep,  u_1,
                       param.cm_lut, param.dcm_dvf_v_lut, param.dcm_dkappa_v_lut, 
                       Fwind, Fwind_v, vwind_eff, states.bld1_flp_d, states.phi_rot, 0.0, states.h_shear, states.v_shear, param.Rrot/3.0,
                       dlam_dvw, dlam_dvtow, dlam_dphi_rot_d,
                       dFwind_dvtow, dFwind_dvw, 
                       Trot1, dTrot1_dtow_fa_d, dTrot1_dphi_rot_d, dTrot1_dbld1_flp_d, dTrot1_dh_shear, dTrot1_dv_shear, dTrot1_dvwind, dTrot1_dtheta1, dTrot1_dphi_rot);
    aeroForceAndDerivs(lambdaIdx, lambdaFact, thetaIdx2, thetaFact2, param.lambdaStep, param.thetaStep,  u_2,
                       param.cm_lut, param.dcm_dvf_v_lut, param.dcm_dkappa_v_lut, 
                       Fwind, Fwind_v, vwind_eff, states.bld2_flp_d, states.phi_rot, 2.0/3.0*M_PI, states.h_shear, states.v_shear, param.Rrot/3.0,
                       dlam_dvw, dlam_dvtow, dlam_dphi_rot_d,
                       dFwind_dvtow, dFwind_dvw, 
                       Trot2, dTrot2_dtow_fa_d, dTrot2_dphi_rot_d, dTrot2_dbld2_flp_d, dTrot2_dh_shear, dTrot2_dv_shear, dTrot2_dvwind, dTrot2_dtheta2, dTrot2_dphi_rot);
    aeroForceAndDerivs(lambdaIdx, lambdaFact, thetaIdx3, thetaFact3, param.lambdaStep, param.thetaStep, u_3,
                       param.cm_lut, param.dcm_dvf_v_lut, param.dcm_dkappa_v_lut, 
                       Fwind, Fwind_v, vwind_eff, states.bld3_flp_d, states.phi_rot, 4.0/3.0*M_PI, states.h_shear, states.v_shear, param.Rrot/3.0,
                       dlam_dvw, dlam_dvtow, dlam_dphi_rot_d,
                       dFwind_dvtow, dFwind_dvw, 
                       Trot3, dTrot3_dtow_fa_d, dTrot3_dphi_rot_d, dTrot3_dbld3_flp_d, dTrot3_dh_shear, dTrot3_dv_shear, dTrot3_dvwind, dTrot3_dtheta3, dTrot3_dphi_rot);

    aeroForceAndDerivs(lambdaIdx, lambdaFact, thetaIdx1, thetaFact1, param.lambdaStep, param.thetaStep, u_1,
                       param.ct_lut, param.dct_dvf_v_lut, param.dct_dkappa_v_lut, 
                       Fwind, Fwind_v, vwind_eff, states.bld1_flp_d, states.phi_rot, 0.0, states.h_shear, states.v_shear, 1.0/3.0,
                       dlam_dvw, dlam_dvtow, dlam_dphi_rot_d,
                       dFwind_dvtow, dFwind_dvw, 
                       Fthrust1, dFthrust1_dtow_fa_d, dFthrust1_dphi_rot_d, dFthrust1_dbld1_flp_d, dFthrust1_dh_shear, dFthrust1_dv_shear, dFthrust1_dvwind, dFthrust1_dtheta1, dFthrust1_dphi_rot);
    aeroForceAndDerivs(lambdaIdx, lambdaFact, thetaIdx2, thetaFact2, param.lambdaStep, param.thetaStep, u_2,
                       param.ct_lut, param.dct_dvf_v_lut, param.dct_dkappa_v_lut, 
                       Fwind, Fwind_v, vwind_eff, states.bld2_flp_d, states.phi_rot, 2.0/3.0*M_PI, states.h_shear, states.v_shear, 1.0/3.0,
                       dlam_dvw, dlam_dvtow, dlam_dphi_rot_d,
                       dFwind_dvtow, dFwind_dvw, 
                       Fthrust2, dFthrust2_dtow_fa_d, dFthrust2_dphi_rot_d, dFthrust2_dbld2_flp_d, dFthrust2_dh_shear, dFthrust2_dv_shear, dFthrust2_dvwind, dFthrust2_dtheta2, dFthrust2_dphi_rot);
    aeroForceAndDerivs(lambdaIdx, lambdaFact, thetaIdx3, thetaFact3, param.lambdaStep, param.thetaStep, u_3,
                       param.ct_lut, param.dct_dvf_v_lut, param.dct_dkappa_v_lut, 
                       Fwind, Fwind_v, vwind_eff, states.bld3_flp_d, states.phi_rot, 4.0/3.0*M_PI, states.h_shear, states.v_shear, 1.0/3.0,
                       dlam_dvw, dlam_dvtow, dlam_dphi_rot_d,
                       dFwind_dvtow, dFwind_dvw, 
                       Fthrust3, dFthrust3_dtow_fa_d, dFthrust3_dphi_rot_d, dFthrust3_dbld3_flp_d, dFthrust3_dh_shear, dFthrust3_dv_shear, dFthrust3_dvwind, dFthrust3_dtheta3, dFthrust3_dphi_rot);

    aeroForceAndDerivs(lambdaIdx, lambdaFact, thetaIdx1, thetaFact1, param.lambdaStep, param.thetaStep, u_1,
                       param.cf_lut, param.dcf_dvf_v_lut, param.dcf_dkappa_v_lut, 
                       Fwind, Fwind_v, vwind_eff, states.bld1_flp_d, states.phi_rot, 0.0, states.h_shear, states.v_shear, 1.0,
                       dlam_dvw, dlam_dvtow, dlam_dphi_rot_d,
                       dFwind_dvtow, dFwind_dvw, 
                       modalFlapForce1, dmodalFlapForce1_dtow_fa_d, dmodalFlapForce1_dphi_rot_d, dmodalFlapForce1_dbld1_flp_d, dmodalFlapForce1_dh_shear, dmodalFlapForce1_dv_shear, dmodalFlapForce1_dvwind, dmodalFlapForce1_dtheta1, dmodalFlapForce1_dphi_rot);
    aeroForceAndDerivs(lambdaIdx, lambdaFact, thetaIdx2, thetaFact2, param.lambdaStep, param.thetaStep, u_2,
                       param.cf_lut, param.dcf_dvf_v_lut, param.dcf_dkappa_v_lut, 
                       Fwind, Fwind_v, vwind_eff, states.bld2_flp_d, states.phi_rot, 2.0/3.0*M_PI, states.h_shear, states.v_shear, 1.0,
                       dlam_dvw, dlam_dvtow, dlam_dphi_rot_d,
                       dFwind_dvtow, dFwind_dvw, 
                       modalFlapForce2, dmodalFlapForce2_dtow_fa_d, dmodalFlapForce2_dphi_rot_d, dmodalFlapForce2_dbld2_flp_d, dmodalFlapForce2_dh_shear, dmodalFlapForce2_dv_shear, dmodalFlapForce2_dvwind, dmodalFlapForce2_dtheta2, dmodalFlapForce2_dphi_rot);
    aeroForceAndDerivs(lambdaIdx, lambdaFact, thetaIdx3, thetaFact3, param.lambdaStep, param.thetaStep, u_3,
                       param.cf_lut, param.dcf_dvf_v_lut, param.dcf_dkappa_v_lut, 
                       Fwind, Fwind_v, vwind_eff, states.bld3_flp_d, states.phi_rot, 4.0/3.0*M_PI, states.h_shear, states.v_shear, 1.0,
                       dlam_dvw, dlam_dvtow, dlam_dphi_rot_d,
                       dFwind_dvtow, dFwind_dvw, 
                       modalFlapForce3, dmodalFlapForce3_dtow_fa_d, dmodalFlapForce3_dphi_rot_d, dmodalFlapForce3_dbld3_flp_d, dmodalFlapForce3_dh_shear, dmodalFlapForce3_dv_shear, dmodalFlapForce3_dvwind, dmodalFlapForce3_dtheta3, dmodalFlapForce3_dphi_rot);
    
    aeroForceAndDerivs(lambdaIdx, lambdaFact, thetaIdx1, thetaFact1, param.lambdaStep, param.thetaStep, u_1,
                       param.cmy_D23_lut, param.dcmy_D23_dvf_v_lut, param.dcmy_D23_dkappa_v_lut, 
                       Fwind, Fwind_v, vwind_eff, states.bld1_flp_d, states.phi_rot, 0.0, states.h_shear, states.v_shear, param.Rrot,
                       dlam_dvw, dlam_dvtow, dlam_dphi_rot_d,
                       dFwind_dvtow, dFwind_dvw, 
                       MyD23_1, dMyD23_1_dtow_fa_d, dMyD23_1_dphi_rot_d, dMyD23_1_dbld1_flp_d, dMyD23_1_dh_shear, dMyD23_1_dv_shear, dMyD23_1_dvwind, dMyD23_1_dtheta1, dMyD23_1_dphi_rot);
    aeroForceAndDerivs(lambdaIdx, lambdaFact, thetaIdx2, thetaFact2, param.lambdaStep, param.thetaStep, u_2,
                       param.cmy_D23_lut, param.dcmy_D23_dvf_v_lut, param.dcmy_D23_dkappa_v_lut, 
                       Fwind, Fwind_v, vwind_eff, states.bld2_flp_d, states.phi_rot, 2.0/3.0*M_PI, states.h_shear, states.v_shear, param.Rrot,
                       dlam_dvw, dlam_dvtow, dlam_dphi_rot_d,
                       dFwind_dvtow, dFwind_dvw, 
                       MyD23_2, dMyD23_2_dtow_fa_d, dMyD23_2_dphi_rot_d, dMyD23_2_dbld2_flp_d, dMyD23_2_dh_shear, dMyD23_2_dv_shear, dMyD23_2_dvwind, dMyD23_2_dtheta2, dMyD23_2_dphi_rot);
    aeroForceAndDerivs(lambdaIdx, lambdaFact, thetaIdx3, thetaFact3, param.lambdaStep, param.thetaStep, u_3,
                       param.cmy_D23_lut, param.dcmy_D23_dvf_v_lut, param.dcmy_D23_dkappa_v_lut, 
                       Fwind, Fwind_v, vwind_eff, states.bld3_flp_d, states.phi_rot, 4.0/3.0*M_PI, states.h_shear, states.v_shear, param.Rrot,
                       dlam_dvw, dlam_dvtow, dlam_dphi_rot_d,
                       dFwind_dvtow, dFwind_dvw, 
                       MyD23_3, dMyD23_3_dtow_fa_d, dMyD23_3_dphi_rot_d, dMyD23_3_dbld3_flp_d, dMyD23_3_dh_shear, dMyD23_3_dv_shear, dMyD23_3_dvwind, dMyD23_3_dtheta3, dMyD23_3_dphi_rot);
    
}
