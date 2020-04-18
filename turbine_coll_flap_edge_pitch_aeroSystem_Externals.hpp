#include <cmath>

#define vTLng qd(0)
#define omrot qd(2)
#define vBFlap qd(3)
#define vBEdge qd(4)
#define vwind u(0)
#define theta u(2)

#define LUT(tab) (thetaFact*(lambdaFact*tab(lambdaIdx, thetaIdx) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx)) + (1.0-thetaFact)*(lambdaFact*tab(lambdaIdx, thetaIdx+1) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx+1)))
#define DLAM_LUT(tab) ((thetaFact*(tab(lambdaIdx+1, thetaIdx)-tab(lambdaIdx, thetaIdx))/param.lambdaStep) + (1.0-thetaFact)*((tab(lambdaIdx+1, thetaIdx)-tab(lambdaIdx, thetaIdx))/param.lambdaStep))
#define DTH_LUT(tab) (( (lambdaFact*tab(lambdaIdx, thetaIdx+1) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx+1))-(lambdaFact*tab(lambdaIdx, thetaIdx) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx)) )/param.thetaStep)

void turbine_coll_flap_edge_pitch_aeroSystem::calculateExternal() {
    double theta_deg= -theta/M_PI*180;
    double vwind_eff= vwind-vTLng;
    // lambda= om_rot*Rrot/vwind;
    double lambda= omrot*param.Rrot/vwind_eff;
    // Fwind= rho/2*Arot*vwind_eff^2;
    double Fwind_v= param.rho/2*param.Arot*vwind_eff;
    
    if(lambda>param.lambdaMax-param.lambdaStep) lambda= param.lambdaMax-param.lambdaStep;
    if(lambda<param.lambdaMin) lambda= param.lambdaMin;
    if(theta_deg>param.thetaMax-param.thetaStep) theta_deg= param.thetaMax-param.thetaStep;
    if(theta_deg<param.thetaMin) theta_deg= param.thetaMin;
    
    int lambdaIdx= std::floor((lambda-param.lambdaMin)/param.lambdaStep);
    int thetaIdx= std::floor((theta-param.thetaMin)/param.thetaStep);
    double lambdaFact= 1.0 - lambda + lambdaIdx*param.lambdaStep;
    double thetaFact= 1.0 - theta_deg + thetaIdx*param.thetaStep;
    
    double cm= LUT(param.cm_lut);
    double ct= LUT(param.ct_lut);
    double cf= LUT(param.cf_lut);
    double ce= LUT(param.ce_lut);
    
    double dcm_dvf_v= LUT(param.dcm_dvf_v_lut);
    double dcm_dve_v= LUT(param.dcm_dve_v_lut);
    double dct_dvf_v= LUT(param.dct_dvf_v_lut);
    double dct_dve_v= LUT(param.dct_dve_v_lut);
    double dcf_dvf_v= LUT(param.dcf_dvf_v_lut);
    double dcf_dve_v= LUT(param.dcf_dve_v_lut);
    double dce_dvf_v= LUT(param.dce_dvf_v_lut);
    double dce_dve_v= LUT(param.dce_dve_v_lut);
    
    Trot= param.Rrot*Fwind_v*(vwind_eff*cm + vBFlap*dcm_dvf_v + vBEdge*dcm_dve_v);
    Fthrust= Fwind_v*(vwind_eff*ct + vBFlap*dct_dvf_v + vBEdge*dct_dve_v);
    modalFlapForce= Fwind_v*(vwind_eff*cf + vBFlap*dcf_dvf_v + vBEdge*dcf_dve_v);
    modalEdgeForce= -Fwind_v*(vwind_eff*ce + vBFlap*dce_dvf_v + vBEdge*dce_dve_v);

}

static void aeroForceDerivs(const double cx_stat, const double dcx_dlam, const double dcx_dtheta, 
                            const double dcx_dvf_v, const double dcx_dve_v, 
                            const double dlam_dvw, const double dlam_dvtow, const double dlam_domrot,
                            const double Fwind, const double Fwind_v, const double dFwind_dvtow, const double dFwind_dvw, 
                            double &dX_dqd1, double &dX_dqd3, double &dX_dqd4, double &dX_dqd5, double &dX_dvwind, double &dX_dtheta) {
    double dcx_dvw= dcx_dlam * dlam_dvw;
    double dcx_dvtow= dcx_dlam * dlam_dvtow;
    double dcx_domrot= dcx_dlam * dlam_domrot;
    
    dX_dqd1= dFwind_dvtow*cx_stat + Fwind*dcx_dvtow;
    dX_dqd3= Fwind*dcx_domrot;
    dX_dqd4= Fwind_v * dcx_dvf_v;
    dX_dqd5= Fwind_v * dcx_dve_v;
    dX_dvwind= dFwind_dvw*cx_stat + Fwind*dcx_dvw;
    dX_dtheta= Fwind*dcx_dtheta;
}

void turbine_coll_flap_edge_pitch_aeroSystem::calculateExternalWithDeriv() {
    double theta_deg= -theta/M_PI*180;
    double vwind_eff= vwind-vTLng;
    // lambda= om_rot*Rrot/vwind;
    double lambda= omrot*param.Rrot/vwind_eff;
    double Fwind= param.rho/2*param.Arot*vwind_eff*vwind_eff;
    double Fwind_v= param.rho/2*param.Arot*vwind_eff;
    
    if(lambda>param.lambdaMax-param.lambdaStep) lambda= param.lambdaMax-param.lambdaStep;
    if(lambda<param.lambdaMin) lambda= param.lambdaMin;
    if(theta_deg>param.thetaMax-param.thetaStep) theta_deg= param.thetaMax-param.thetaStep;
    if(theta_deg<param.thetaMin) theta_deg= param.thetaMin;
    
    int lambdaIdx= std::floor((lambda-param.lambdaMin)/param.lambdaStep);
    int thetaIdx= std::floor((theta-param.thetaMin)/param.thetaStep);
    double lambdaFact= 1.0 - lambda + lambdaIdx*param.lambdaStep;
    double thetaFact= 1.0 - theta_deg + thetaIdx*param.thetaStep;
    
    double cm= LUT(param.cm_lut);
    double ct= LUT(param.ct_lut);
    double cf= LUT(param.cf_lut);
    double ce= LUT(param.ce_lut);
    
    double dcm_dvf_v= LUT(param.dcm_dvf_v_lut);
    double dcm_dve_v= LUT(param.dcm_dve_v_lut);
    double dct_dvf_v= LUT(param.dct_dvf_v_lut);
    double dct_dve_v= LUT(param.dct_dve_v_lut);
    double dcf_dvf_v= LUT(param.dcf_dvf_v_lut);
    double dcf_dve_v= LUT(param.dcf_dve_v_lut);
    double dce_dvf_v= LUT(param.dce_dvf_v_lut);
    double dce_dve_v= LUT(param.dce_dve_v_lut);
    
    Trot= param.Rrot*Fwind_v*(vwind_eff*cm + vBFlap*dcm_dvf_v + vBEdge*dcm_dve_v);
    Fthrust= Fwind_v*(vwind_eff*ct + vBFlap*dct_dvf_v + vBEdge*dct_dve_v);
    modalFlapForce= Fwind_v*(vwind_eff*cf + vBFlap*dcf_dvf_v + vBEdge*dcf_dve_v);
    modalEdgeForce= -Fwind_v*(vwind_eff*ce + vBFlap*dce_dvf_v + vBEdge*dce_dve_v);
    
    double dFwind_dvw   =  2*Fwind_v; // 2*Fwind/vwind;
    double dFwind_dvtow = -2*Fwind_v; // -2*Fwind/vwind;
    
    double dlam_dvw   = -lambda/vwind;
    double dlam_dvtow =  lambda/vwind;
    double dlam_domrot= lambda/omrot;
    
    aeroForceDerivs(cm, DLAM_LUT(param.cm_lut), DTH_LUT(param.cm_lut), 
                    dcm_dvf_v, dcm_dve_v, 
                    dlam_dvw, dlam_dvtow, dlam_domrot,
                    Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw, 
                    dTrot_dqd1, dTrot_dqd3, dTrot_dqd4, dTrot_dqd5, dTrot_dvwind, dTrot_dtheta);
    
    aeroForceDerivs(ct, DLAM_LUT(param.ct_lut), DTH_LUT(param.ct_lut), 
                    dct_dvf_v, dct_dve_v, 
                    dlam_dvw, dlam_dvtow, dlam_domrot,
                    Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw, 
                    dFthrust_dqd1, dFthrust_dqd3, dFthrust_dqd4, dFthrust_dqd5, dFthrust_dvwind, dFthrust_dtheta);
    
    aeroForceDerivs(cf, DLAM_LUT(param.cf_lut), DTH_LUT(param.cf_lut), 
                    dcf_dvf_v, dcf_dve_v, 
                    dlam_dvw, dlam_dvtow, dlam_domrot,
                    Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw, 
                    dmodalFlapForce_dqd1, dmodalFlapForce_dqd3, dmodalFlapForce_dqd4, dmodalFlapForce_dqd5, dmodalFlapForce_dvwind, dmodalFlapForce_dtheta);
    
    aeroForceDerivs(ce, DLAM_LUT(param.ce_lut), DTH_LUT(param.ce_lut), 
                    dce_dvf_v, dce_dve_v, 
                    dlam_dvw, dlam_dvtow, dlam_domrot,
                    Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw, 
                    dmodalEdgeForce_dqd1, dmodalEdgeForce_dqd3, dmodalEdgeForce_dqd4, dmodalEdgeForce_dqd5, dmodalEdgeForce_dvwind, dmodalEdgeForce_dtheta);

}
