#include <cmath>

#define vTLng qd(0)
#define vTLat qd(1)
#define omrot qd(2)
#define vBFlap qd(3)
#define vBEdge qd(4)
#define vwind q(6)
#define theta u(1)

#define LUT(tab) (thetaFact*(lambdaFact*tab(lambdaIdx, thetaIdx) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx)) + (1.0-thetaFact)*(lambdaFact*tab(lambdaIdx, thetaIdx+1) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx+1)))
#define DLAM_LUT(tab) ((thetaFact*(tab(lambdaIdx+1, thetaIdx)-tab(lambdaIdx, thetaIdx))/param.lambdaStep) + (1.0-thetaFact)*((tab(lambdaIdx+1, thetaIdx)-tab(lambdaIdx, thetaIdx))/param.lambdaStep))
#define DTH_LUT(tab) (( (lambdaFact*tab(lambdaIdx, thetaIdx+1) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx+1))-(lambdaFact*tab(lambdaIdx, thetaIdx) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx)) )/param.thetaStep)

void turbine_coll_flap_edge_pitch_aero_est2System::calculateExternal() {
    theta_deg= -theta/M_PI*180.0;
    double vwind_eff= vwind-vTLng;
    lam= omrot*param.Rrot/vwind_eff;
    double Fwind_v= param.rho/2.0*param.Arot*vwind_eff;
    
    if(lam>param.lambdaMax-param.lambdaStep) lam= param.lambdaMax-param.lambdaStep;
    if(lam<param.lambdaMin) lam= param.lambdaMin;
    if(theta_deg>param.thetaMax-param.thetaStep) theta_deg= param.thetaMax-param.thetaStep;
    if(theta_deg<param.thetaMin) theta_deg= param.thetaMin;
    
    double lambdaScaled= (lam-param.lambdaMin)/param.lambdaStep;
    int lambdaIdx= std::floor(lambdaScaled);
    double thetaScaled= (theta_deg-param.thetaMin)/param.thetaStep;
    int thetaIdx= std::floor(thetaScaled);
    double lambdaFact= 1.0 - lambdaScaled + lambdaIdx;
    double thetaFact= 1.0 - thetaScaled + thetaIdx;
    
    cm= LUT(param.cm_lut);
    ct= LUT(param.ct_lut);
    cflp= LUT(param.cf_lut);
    cedg= LUT(param.ce_lut);
    
    double dcm_dvf_v= LUT(param.dcm_dvf_v_lut);
    double dcm_dve_v= LUT(param.dcm_dve_v_lut);
    double dct_dvf_v= LUT(param.dct_dvf_v_lut);
    double dct_dve_v= LUT(param.dct_dve_v_lut);
    double dcs_dvy_v= LUT(param.dcs_dvy_v_lut);
    double dcf_dvf_v= LUT(param.dcf_dvf_v_lut);
    double dcf_dve_v= LUT(param.dcf_dve_v_lut);
    double dce_dvf_v= LUT(param.dce_dvf_v_lut);
    double dce_dve_v= LUT(param.dce_dve_v_lut);
    
    Trot= param.Rrot*Fwind_v*(vwind_eff*cm + vBFlap*dcm_dvf_v + vBEdge*dcm_dve_v);
    Fthrust= Fwind_v*(vwind_eff*ct + vBFlap*dct_dvf_v + vBEdge*dct_dve_v);
    Ftow_y= 1.5*Fwind_v*vTLat*dcs_dvy_v;
    modalFlapForce= Fwind_v*(vwind_eff*cflp + vBFlap*dcf_dvf_v + vBEdge*dcf_dve_v);
    modalEdgeForce= Fwind_v*(vwind_eff*cedg + vBFlap*dce_dvf_v + vBEdge*dce_dve_v);

}

static void aeroForceDerivs(const double torque_R, const double cx_stat, const double dcx_dlam, const double dcx_dtheta, 
                            const double dcx_dvf_v, const double dcx_dve_v, 
                            const double dlam_dvw, const double dlam_dvtow, const double dlam_domrot,
                            const double Fwind, const double Fwind_v, const double dFwind_dvtow, const double dFwind_dvw, 
                            double &dX_dqd1, double &dX_dqd3, double &dX_dqd4, double &dX_dqd5, double &dX_dvwind, double &dX_dtheta) {
    double dcx_dvw= dcx_dlam * dlam_dvw;
    double dcx_dvtow= dcx_dlam * dlam_dvtow;
    double dcx_domrot= dcx_dlam * dlam_domrot;
    
    dX_dqd1= torque_R * (dFwind_dvtow*cx_stat + Fwind*dcx_dvtow);    // TODO to be exact, the derivative of the edge and flap terms is missing here 
    dX_dqd3= torque_R * Fwind*dcx_domrot;                          // TODO to be exact, the derivative of the edge and flap terms is missing here 
    dX_dqd4= torque_R * Fwind_v * dcx_dvf_v;
    dX_dqd5= torque_R * Fwind_v * dcx_dve_v;
    dX_dvwind= torque_R * (dFwind_dvw*cx_stat + Fwind*dcx_dvw);      // TODO to be exact, the derivative of the edge and flap terms is missing here 
    dX_dtheta= torque_R * Fwind*dcx_dtheta;                        // TODO to be exact, the derivative of the edge and flap terms is missing here 
}

void turbine_coll_flap_edge_pitch_aero_est2System::calculateExternalWithDeriv() {
    theta_deg= -theta/M_PI*180.0;
    double vwind_eff= vwind-vTLng;
    lam= omrot*param.Rrot/vwind_eff;
    double Fwind= param.rho/2.0*param.Arot*vwind_eff*vwind_eff;
    double Fwind_v= param.rho/2.0*param.Arot*vwind_eff;
    
    if(lam>param.lambdaMax-param.lambdaStep) lam= param.lambdaMax-param.lambdaStep;
    if(lam<param.lambdaMin) lam= param.lambdaMin;
    if(theta_deg>param.thetaMax-param.thetaStep) theta_deg= param.thetaMax-param.thetaStep;
    if(theta_deg<param.thetaMin) theta_deg= param.thetaMin;
    
    double lambdaScaled= (lam-param.lambdaMin)/param.lambdaStep;
    int lambdaIdx= std::floor(lambdaScaled);
    double thetaScaled= (theta_deg-param.thetaMin)/param.thetaStep;
    int thetaIdx= std::floor(thetaScaled);
    double lambdaFact= 1.0 - lambdaScaled + lambdaIdx;
    double thetaFact= 1.0 - thetaScaled + thetaIdx;
    
    cm= LUT(param.cm_lut);
    ct= LUT(param.ct_lut);
    cflp= LUT(param.cf_lut);
    cedg= LUT(param.ce_lut);
    
    double dcm_dvf_v= LUT(param.dcm_dvf_v_lut);
    double dcm_dve_v= LUT(param.dcm_dve_v_lut);
    double dct_dvf_v= LUT(param.dct_dvf_v_lut);
    double dct_dve_v= LUT(param.dct_dve_v_lut);
    double dcs_dvy_v= LUT(param.dcs_dvy_v_lut);
    double dcf_dvf_v= LUT(param.dcf_dvf_v_lut);
    double dcf_dve_v= LUT(param.dcf_dve_v_lut);
    double dce_dvf_v= LUT(param.dce_dvf_v_lut);
    double dce_dve_v= LUT(param.dce_dve_v_lut);
    
    Trot= param.Rrot*Fwind_v*(vwind_eff*cm + vBFlap*dcm_dvf_v + vBEdge*dcm_dve_v);
    Fthrust= Fwind_v*(vwind_eff*ct + vBFlap*dct_dvf_v + vBEdge*dct_dve_v);
    Ftow_y= 1.5*Fwind_v*vTLat*dcs_dvy_v;
    modalFlapForce= Fwind_v*(vwind_eff*cflp + vBFlap*dcf_dvf_v + vBEdge*dcf_dve_v);
    modalEdgeForce= Fwind_v*(vwind_eff*cedg + vBFlap*dce_dvf_v + vBEdge*dce_dve_v);
    
    double dFwind_dvw   =  2*Fwind_v; // 2*Fwind/vwind;
    double dFwind_dvtow = -2*Fwind_v; // -2*Fwind/vwind;
    
    double dlam_dvw   = -lam/vwind;
    double dlam_dvtow =  lam/vwind;
    double dlam_domrot= lam/omrot;
    
    aeroForceDerivs(param.Rrot, cm, DLAM_LUT(param.cm_lut), DTH_LUT(param.cm_lut), 
                    dcm_dvf_v, dcm_dve_v, 
                    dlam_dvw, dlam_dvtow, dlam_domrot,
                    Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw, 
                    dTrot_dqd1, dTrot_dqd3, dTrot_dqd4, dTrot_dqd5, dTrot_dq7, dTrot_dtheta);
    
    aeroForceDerivs(1.0, ct, DLAM_LUT(param.ct_lut), DTH_LUT(param.ct_lut), 
                    dct_dvf_v, dct_dve_v, 
                    dlam_dvw, dlam_dvtow, dlam_domrot,
                    Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw, 
                    dFthrust_dqd1, dFthrust_dqd3, dFthrust_dqd4, dFthrust_dqd5, dFthrust_dq7, dFthrust_dtheta);
    
    aeroForceDerivs(1.0, cflp, DLAM_LUT(param.cf_lut), DTH_LUT(param.cf_lut), 
                    dcf_dvf_v, dcf_dve_v, 
                    dlam_dvw, dlam_dvtow, dlam_domrot,
                    Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw, 
                    dmodalFlapForce_dqd1, dmodalFlapForce_dqd3, dmodalFlapForce_dqd4, dmodalFlapForce_dqd5, dmodalFlapForce_dq7, dmodalFlapForce_dtheta);
    
    aeroForceDerivs(1.0, cedg, -1.0*DLAM_LUT(param.ce_lut), -1.0*DTH_LUT(param.ce_lut), 
                    dce_dvf_v, dce_dve_v, 
                    dlam_dvw, dlam_dvtow, dlam_domrot,
                    Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw, 
                    dmodalEdgeForce_dqd1, dmodalEdgeForce_dqd3, dmodalEdgeForce_dqd4, dmodalEdgeForce_dqd5, dmodalEdgeForce_dq7, dmodalEdgeForce_dtheta);
    
    dFtow_y_dqd2= 1.5*Fwind_v*dcs_dvy_v;
    
    dTrot_dw_theta_m= dTrot_dtheta;
    dFthrust_dw_theta_t= dFthrust_dtheta;
    dmodalFlapForce_dw_theta_b1= dmodalFlapForce_dtheta;
    dmodalEdgeForce_dw_theta_b2= dmodalEdgeForce_dtheta;
    dFtow_y_dw_tow_lat= 1;

    // TODO to be exact, the derivative with respect to qd3, wind and theta are missing here 
}
