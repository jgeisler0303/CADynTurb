#include <cmath>

#define LUT(tab) (thetaFact*(lambdaFact*tab(lambdaIdx, thetaIdx) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx)) + (1.0-thetaFact)*(lambdaFact*tab(lambdaIdx, thetaIdx+1) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx+1)))
#define DLAM_LUT(tab) ((thetaFact*(tab(lambdaIdx+1, thetaIdx)-tab(lambdaIdx, thetaIdx))/lambdaStep) + (1.0-thetaFact)*((tab(lambdaIdx+1, thetaIdx)-tab(lambdaIdx, thetaIdx))/lambdaStep))
#define DTH_LUT(tab) (( (lambdaFact*tab(lambdaIdx, thetaIdx+1) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx+1))-(lambdaFact*tab(lambdaIdx, thetaIdx) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx)) )/thetaStep * -180.0/M_PI)

typedef decltype(std::declval<turbine_T2B1i1cG_aero_estSystem>().param.cm_lut) MatCx;

static double aeroForce(const int lambdaIdx,
                        const double lambdaFact,
                        const int thetaIdx,
                        const double thetaFact,
                        const Eigen::Ref<const MatCx> &cx_lut,
                        const Eigen::Ref<const MatCx> &dcx_dvf_v_lut, 
                        const double dcx_dve_v,
                        const Eigen::Ref<const MatCx> &dcx_dkappa_v_lut,
                        const double Fwind_v,
                        const double vwind_eff,
                        const double bld_flp_d,
                        const double bld_edg_d,
                        const double kappa,
                        const double torque_R
                       ) {
    
    double cx_stat= LUT(cx_lut);
    double dcx_dvf_v= LUT(dcx_dvf_v_lut);
    double dcx_dkappa_v= LUT(dcx_dkappa_v_lut);

    return torque_R*Fwind_v*(vwind_eff*cx_stat + bld_flp_d*dcx_dvf_v + bld_edg_d*dcx_dve_v + kappa*dcx_dkappa_v);
}

#define call_aeroForce(var_name, blade_num, field_name, torque_R) var_name ## blade_num = aeroForce(\
    lambdaIdx,\
    lambdaFact,\
    thetaIdx ## blade_num,\
    thetaFact ## blade_num,\
    param.field_name ##_lut,\
    param.d ## field_name ##_dvf_v_lut,\
    d ## field_name ##_dve_v,\
    param.d ## field_name ##_dkappa_v_lut,\
    Fwind_v,\
    vwind_eff,\
    states.bld ## blade_num ##_flp_d,\
    states.bld_edg_d,\
    kappa ## blade_num,\
    torque_R)

static double aeroForce_MyD23(const int lambdaIdx,
                        const double lambdaFact,
                        const int thetaIdx,
                        const double thetaFact,
                        const Eigen::Ref<const MatCx> &cx_lut,
                        const Eigen::Ref<const MatCx> &dcx_dvf_v_lut, 
                        const Eigen::Ref<const MatCx> &dcx_dkappa_v_lut,
                        const double Fwind_v,
                        const double vwind_eff,
                        const double bld_flp_d,
                        const double kappa,
                        const double torque_R
                       ) {
    
    double cx_stat= LUT(cx_lut);
    double dcx_dvf_v= LUT(dcx_dvf_v_lut);
    double dcx_dkappa_v= LUT(dcx_dkappa_v_lut);

    return torque_R*Fwind_v*(vwind_eff*cx_stat + bld_flp_d*dcx_dvf_v + kappa*dcx_dkappa_v);
}

#define call_aeroForce_MyD23(var_name, blade_num, field_name, torque_R) var_name ## blade_num = aeroForce_MyD23(\
    lambdaIdx,\
    lambdaFact,\
    thetaIdx ## blade_num,\
    thetaFact ## blade_num,\
    param.field_name ##_lut,\
    param.d ## field_name ##_dvf_v_lut,\
    param.d ## field_name ##_dkappa_v_lut,\
    Fwind_v,\
    vwind_eff,\
    states.bld ## blade_num ##_flp_d,\
    kappa ## blade_num,\
    torque_R)


void turbine_T2B1i1cG_aero_estSystem::calculateExternal() {
    theta_deg1= -inputs.theta1/M_PI*180.0;
    theta_deg2= -inputs.theta2/M_PI*180.0;
    theta_deg3= -inputs.theta3/M_PI*180.0;
    
    double vwind_eff= states.vwind-states.tow_fa_d;
        
    lam= states.phi_rot_d*param.Rrot/vwind_eff;
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

    double theta_deg= 1.0/3.0*(theta_deg1+theta_deg2+theta_deg3);
    double thetaScaled= (theta_deg-param.thetaMin)/param.thetaStep;
    int thetaIdx= std::floor(thetaScaled);
    double thetaFact= 1.0 - thetaScaled + thetaIdx;

    
    double kappa1= -states.h_shear*sin(states.phi_rot) + states.v_shear*cos(states.phi_rot);
    double kappa2= -states.h_shear*sin(states.phi_rot+2.0/3.0*M_PI) + states.v_shear*cos(states.phi_rot+2.0/3.0*M_PI);
    double kappa3= -states.h_shear*sin(states.phi_rot+4.0/3.0*M_PI) + states.v_shear*cos(states.phi_rot+4.0/3.0*M_PI);

    
    double dcm_dve_v= LUT(param.dcm_dve_v_lut);
    call_aeroForce(Trot, 1, cm, param.Rrot/3.0);
    call_aeroForce(Trot, 2, cm, param.Rrot/3.0);
    call_aeroForce(Trot, 3, cm, param.Rrot/3.0);
    
    double dct_dve_v= LUT(param.dct_dve_v_lut);
    call_aeroForce(Fthrust, 1, ct, 1.0/3.0);
    call_aeroForce(Fthrust, 2, ct, 1.0/3.0);
    call_aeroForce(Fthrust, 3, ct, 1.0/3.0);

    call_aeroForce_MyD23(MyD23_, 1, cmy_D23, param.Rrot);
    call_aeroForce_MyD23(MyD23_, 2, cmy_D23, param.Rrot);
    call_aeroForce_MyD23(MyD23_, 3, cmy_D23, param.Rrot);

    double dcf_dve_v= LUT(param.dce_dve_v_lut);
    call_aeroForce(modalFlapForce, 1, cf, 1.0);
    call_aeroForce(modalFlapForce, 2, cf, 1.0);
    call_aeroForce(modalFlapForce, 3, cf, 1.0);
    
    cedg= LUT(param.ce_lut);
    double dce_dvf_v= LUT(param.dce_dvf_v_lut);
    double dce_dve_v= LUT(param.dce_dve_v_lut);
    double m_bld_flp_d= 1.0/3.0*(states.bld1_flp_d+states.bld2_flp_d+states.bld3_flp_d);
    modalEdgeForce= Fwind_v*(vwind_eff*cedg + m_bld_flp_d*dce_dvf_v + states.bld_edg_d*dce_dve_v);

    double dcs_dvy_v= LUT(param.dcs_dvy_v_lut);
    Ftow_y= 1.5*Fwind_v*states.tow_ss_d*dcs_dvy_v;
}

static void aeroForceAndDerivs(const int lambdaIdx,
                               const double lambdaFact,
                               const int thetaIdx,
                               const double thetaFact,
                               const double lambdaStep,
                               const double thetaStep,
                               const Eigen::Ref<const MatCx> &cx_lut,
                               const Eigen::Ref<const MatCx> &dcx_dvf_v_lut,
                               const double dcx_dve_v,
                               const Eigen::Ref<const MatCx> &dcx_dkappa_v_lut,
                               const double Fwind,
                               const double Fwind_v,
                               const double vwind_eff,
                               const double bld_flp_d,
                               const double bld_edg_d,
                               const double phi_rot,
                               const double bld_offset,
                               const double kappa,
                               const double torque_R,
                               const double dlam_dvw,
                               const double dlam_dvtow,
                               const double dlam_dphi_rot_d,
                               const double dkappa_dphi_rot,
                               const double dFwind_dvtow,
                               const double dFwind_dvw,
                               double &X,
                               double &dX_dtow_fa_d,
                               double &dX_dphi_rot_d,
                               double &dX_dbld_flp_d,
                               double &dX_dbld_edg_d,
                               double &dX_dh_shear,
                               double &dX_dv_shear,
                               double &dX_dvwind,
                               double &dX_dtheta,
                               double &dX_dphi_rot) {    

    double cx_stat= LUT(cx_lut);
    double dcx_dvf_v= LUT(dcx_dvf_v_lut);
    double dcx_dkappa_v= LUT(dcx_dkappa_v_lut);

    X= torque_R*Fwind_v*(vwind_eff*cx_stat + bld_flp_d*dcx_dvf_v + bld_edg_d*dcx_dve_v + kappa*dcx_dkappa_v);
    
    double dcx_dlam= DLAM_LUT(cx_lut);
    
    double dcx_dvw= dcx_dlam * dlam_dvw;
    double dcx_dvtow= dcx_dlam * dlam_dvtow;
    double dcx_dphi_rot_d= dcx_dlam * dlam_dphi_rot_d;
    
    double dcx_dtheta= DTH_LUT(cx_lut);
    
    dX_dtow_fa_d= torque_R*(dFwind_dvtow*cx_stat + Fwind*dcx_dvtow);    // TODO to be exact, the derivative of the edge and flap terms is missing here?
    dX_dphi_rot_d= torque_R*Fwind*dcx_dphi_rot_d;                          // TODO to be exact, the derivative of the edge and flap terms is missing here 
    dX_dbld_flp_d= torque_R*Fwind_v * dcx_dvf_v;
    dX_dbld_edg_d= torque_R*Fwind_v * dcx_dve_v;
    dX_dh_shear= -torque_R*Fwind_v * dcx_dkappa_v * sin(phi_rot+bld_offset);
    dX_dv_shear= torque_R*Fwind_v * dcx_dkappa_v * cos(phi_rot+bld_offset);
    dX_dvwind= torque_R*(dFwind_dvw*cx_stat + Fwind*dcx_dvw);      // TODO to be exact, the derivative of the edge and flap terms is missing here 
    dX_dtheta= torque_R*Fwind*dcx_dtheta;                        // TODO to be exact, the derivative of the edge and flap terms is missing here 
    dX_dphi_rot= torque_R*Fwind_v * dcx_dkappa_v * dkappa_dphi_rot;
}

#define call_aeroForceAndDerivs(var_name, blade_num, field_name, torque_R) aeroForceAndDerivs(\
    lambdaIdx,\
    lambdaFact,\
    thetaIdx ## blade_num,\
    thetaFact ## blade_num,\
    param.lambdaStep,\
    param.thetaStep,\
    param.field_name ##_lut,\
    param.d ## field_name ##_dvf_v_lut,\
    d ## field_name ##_dve_v,\
    param.d ## field_name ##_dkappa_v_lut,\
    Fwind,\
    Fwind_v,\
    vwind_eff,\
    states.bld ## blade_num ##_flp_d,\
    states.bld_edg_d,\
    states.phi_rot,\
    (blade_num-1.0)*2.0/3.0*M_PI,\
    kappa ## blade_num,\
    torque_R,\
    dlam_dvw,\
    dlam_dvtow,\
    dlam_dphi_rot_d,\
    dkappa ## blade_num ## _dphi_rot,\
    dFwind_dvtow,\
    dFwind_dvw,\
    var_name ## blade_num,\
    d ## var_name ## blade_num ## _dtow_fa_d,\
    d ## var_name ## blade_num ## _dphi_rot_d,\
    d ## var_name ## blade_num ## _dbld ## blade_num ## _flp_d,\
    d ## var_name ## blade_num ## _dbld_edg_d,\
    d ## var_name ## blade_num ## _dh_shear,\
    d ## var_name ## blade_num ## _dv_shear,\
    d ## var_name ## blade_num ## _dvwind,\
    d ## var_name ## blade_num ## _dtheta ## blade_num,\
    d ## var_name ## blade_num ## _dphi_rot)

static void aeroForceAndDerivs_MyD23(const int lambdaIdx,
                                      const double lambdaFact,
                                      const int thetaIdx,
                                      const double thetaFact,
                                      const double lambdaStep,
                                      const double thetaStep,
                                      const Eigen::Ref<const MatCx> &cx_lut,
                                      const Eigen::Ref<const MatCx> &dcx_dvf_v_lut,
                                      const Eigen::Ref<const MatCx> &dcx_dkappa_v_lut,
                                      const double Fwind,
                                      const double Fwind_v,
                                      const double vwind_eff,
                                      const double bld_flp_d,
                                      const double phi_rot,
                                      const double bld_offset,
                                      const double kappa,
                                      const double torque_R,
                                      const double dlam_dvw,
                                      const double dlam_dvtow,
                                      const double dlam_dphi_rot_d,
                                      const double dkappa_dphi_rot,
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
    dX_dphi_rot= torque_R*Fwind_v * dcx_dkappa_v * dkappa_dphi_rot;
}

#define call_aeroForceAndDerivs_MyD23(var_name, blade_num, field_name, torque_R) aeroForceAndDerivs_MyD23(\
    lambdaIdx,\
    lambdaFact,\
    thetaIdx ## blade_num,\
    thetaFact ## blade_num,\
    param.lambdaStep,\
    param.thetaStep,\
    param.field_name ##_lut,\
    param.d ## field_name ##_dvf_v_lut,\
    param.d ## field_name ##_dkappa_v_lut,\
    Fwind,\
    Fwind_v,\
    vwind_eff,\
    states.bld ## blade_num ##_flp_d,\
    states.phi_rot,\
    (blade_num-1.0)*2.0/3.0*M_PI,\
    kappa ## blade_num,\
    torque_R,\
    dlam_dvw,\
    dlam_dvtow,\
    dlam_dphi_rot_d,\
    dkappa ## blade_num ## _dphi_rot,\
    dFwind_dvtow,\
    dFwind_dvw,\
    var_name ## blade_num,\
    d ## var_name ## blade_num ## _dtow_fa_d,\
    d ## var_name ## blade_num ## _dphi_rot_d,\
    d ## var_name ## blade_num ## _dbld ## blade_num ## _flp_d,\
    d ## var_name ## blade_num ## _dh_shear,\
    d ## var_name ## blade_num ## _dv_shear,\
    d ## var_name ## blade_num ## _dvwind,\
    d ## var_name ## blade_num ## _dtheta ## blade_num,\
    d ## var_name ## blade_num ## _dphi_rot)

void turbine_T2B1i1cG_aero_estSystem::calculateExternalWithDeriv() {
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
    
    double theta_deg= 1.0/3.0*(theta_deg1+theta_deg2+theta_deg3);
    double thetaScaled= (theta_deg-param.thetaMin)/param.thetaStep;
    int thetaIdx= std::floor(thetaScaled);
    double thetaFact= 1.0 - thetaScaled + thetaIdx;

    
    double dFwind_dvw   =  2*Fwind_v; // 2*Fwind/vwind;
    double dFwind_dvtow = -2*Fwind_v; // -2*Fwind/vwind;

    double kappa1= -states.h_shear*sin(states.phi_rot) + states.v_shear*cos(states.phi_rot);
    double kappa2= -states.h_shear*sin(states.phi_rot+2.0/3.0*M_PI) + states.v_shear*cos(states.phi_rot+2.0/3.0*M_PI);
    double kappa3= -states.h_shear*sin(states.phi_rot+4.0/3.0*M_PI) + states.v_shear*cos(states.phi_rot+4.0/3.0*M_PI);
    
    double dkappa1_dphi_rot= -states.h_shear*cos(states.phi_rot) - states.v_shear*sin(states.phi_rot);
    double dkappa2_dphi_rot= -states.h_shear*cos(states.phi_rot+2.0/3.0*M_PI) - states.v_shear*sin(states.phi_rot+2.0/3.0*M_PI);
    double dkappa3_dphi_rot= -states.h_shear*cos(states.phi_rot+4.0/3.0*M_PI) - states.v_shear*sin(states.phi_rot+4.0/3.0*M_PI);
    
    
    double dlam_dvw   = -lam/states.vwind;
    double dlam_dvtow =  lam/states.vwind;
    double dlam_dphi_rot_d= lam/states.phi_rot_d;

    double dcm_dve_v= LUT(param.dcm_dve_v_lut);
    call_aeroForceAndDerivs(Trot, 1, cm, param.Rrot/3.0);
    call_aeroForceAndDerivs(Trot, 2, cm, param.Rrot/3.0);
    call_aeroForceAndDerivs(Trot, 3, cm, param.Rrot/3.0);

    double dct_dve_v= LUT(param.dct_dve_v_lut);
    call_aeroForceAndDerivs(Fthrust, 1, ct, 1.0/3.0);
    call_aeroForceAndDerivs(Fthrust, 2, ct, 1.0/3.0);
    call_aeroForceAndDerivs(Fthrust, 3, ct, 1.0/3.0);

    double dcf_dve_v= LUT(param.dce_dve_v_lut);
    call_aeroForceAndDerivs(modalFlapForce, 1, cf, 1.0);
    call_aeroForceAndDerivs(modalFlapForce, 2, cf, 1.0);
    call_aeroForceAndDerivs(modalFlapForce, 3, cf, 1.0);
    
    call_aeroForceAndDerivs_MyD23(MyD23_, 1, cmy_D23, 1.0);
    call_aeroForceAndDerivs_MyD23(MyD23_, 2, cmy_D23, 1.0);
    call_aeroForceAndDerivs_MyD23(MyD23_, 3, cmy_D23, 1.0);
    

    cedg= LUT(param.ce_lut);
    double dce_dvf_v= LUT(param.dce_dvf_v_lut);
    double dce_dve_v= LUT(param.dce_dve_v_lut);
    double m_bld_flp_d= 1.0/3.0*(states.bld1_flp_d + states.bld2_flp_d + states.bld3_flp_d);
    modalEdgeForce= Fwind_v*(vwind_eff*cedg + m_bld_flp_d*dce_dvf_v + states.bld_edg_d*dce_dve_v);

    const double lambdaStep= param.lambdaStep;
    const double thetaStep= param.thetaStep;
    double dce_dlam= DLAM_LUT(param.ce_lut);
    
    double dce_dvw= dce_dlam * dlam_dvw;
    double dce_dvtow= dce_dlam * dlam_dvtow;
    double dce_dphi_rot_d= dce_dlam * dlam_dphi_rot_d;
    
    double dce_dtheta= DTH_LUT(param.ce_lut);
    
    dmodalEdgeForce_dtow_fa_d= dFwind_dvtow*cedg + Fwind*dce_dvtow;    // TODO to be exact, the derivative of the edge and flap terms is missing here?
    dmodalEdgeForce_dphi_rot_d= Fwind*dce_dphi_rot_d;                          // TODO to be exact, the derivative of the edge and flap terms is missing here 
    dmodalEdgeForce_dbld1_flp_d= 1.0/3.0 * Fwind_v * dce_dvf_v;
    dmodalEdgeForce_dbld2_flp_d= dmodalEdgeForce_dbld1_flp_d;
    dmodalEdgeForce_dbld3_flp_d= dmodalEdgeForce_dbld1_flp_d;
    dmodalEdgeForce_dbld_edg_d= Fwind_v * dce_dve_v;
    dmodalEdgeForce_dvwind= dFwind_dvw*cedg + Fwind*dce_dvw;      // TODO to be exact, the derivative of the edge and flap terms is missing here 
    dmodalEdgeForce_dtheta1= 1.0/3.0*Fwind*dce_dtheta;                        // TODO to be exact, the derivative of the edge and flap terms is missing here 
    dmodalEdgeForce_dtheta2= dmodalEdgeForce_dtheta1;
    dmodalEdgeForce_dtheta3= dmodalEdgeForce_dtheta1;


    double dcs_dvy_v= LUT(param.dcs_dvy_v_lut);
    Ftow_y= 1.5*Fwind_v*states.tow_ss_d*dcs_dvy_v;
    dFtow_y_dtow_ss_d= 1.5*Fwind_v*dcs_dvy_v;
}
