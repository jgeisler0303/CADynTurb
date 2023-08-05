#include <cmath>

#define LUT(tab) (thetaFact*(lambdaFact*tab(lambdaIdx, thetaIdx) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx)) + (1.0-thetaFact)*(lambdaFact*tab(lambdaIdx, thetaIdx+1) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx+1)))
#define DLAM_LUT(tab) ((thetaFact*(tab(lambdaIdx+1, thetaIdx)-tab(lambdaIdx, thetaIdx))/param.lambdaStep) + (1.0-thetaFact)*((tab(lambdaIdx+1, thetaIdx)-tab(lambdaIdx, thetaIdx))/param.lambdaStep))
#define DTH_LUT(tab) (( (lambdaFact*tab(lambdaIdx, thetaIdx+1) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx+1))-(lambdaFact*tab(lambdaIdx, thetaIdx) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx)) )/param.thetaStep * -180.0/M_PI)

void SYSTEM::calculateExternal() {
    theta_deg= -inputs.theta/M_PI*180.0;
    double vwind_eff= VWIND-VTOW;
    lam= states.phi_rot_d*param.Rrot/vwind_eff;
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
    
#ifdef FLAP
    double dcm_dvf_v= LUT(param.dcm_dvf_v_lut);
    #define F_V_FLP (states.bld_flp_d*dcm_dvf_v)
#else
    #define F_V_FLP 0.0
#endif
#ifdef EDGE    
    double dcm_dve_v= LUT(param.dcm_dve_v_lut);
    #define F_V_EDG (states.bld_edg_d*dcm_dve_v)
#else
    #define F_V_EDG 0.0    
#endif
    Trot= param.Rrot*Fwind_v*(vwind_eff*cm + F_V_FLP + F_V_EDG);

#ifdef THRUST
    ct= LUT(param.ct_lut);
    #ifdef FLAP
        double dct_dvf_v= LUT(param.dct_dvf_v_lut);
        #define F_V_FLP_T (states.bld_flp_d*dct_dvf_v)
    #else
        #define F_V_FLP_T 0.0
    #endif
    #ifdef EDGE    
        double dct_dve_v= LUT(param.dct_dve_v_lut);
        #define F_V_EDG_T (states.bld_edg_d*dct_dve_v)
    #else
        #define F_V_EDG_T 0.0    
    #endif
    Fthrust= Fwind_v*(vwind_eff*ct + F_V_FLP_T + F_V_EDG_T);
#endif
    
#ifdef FLAP
    cflp= LUT(param.cf_lut);
    double dcf_dvf_v= LUT(param.dcf_dvf_v_lut);
    #ifdef EDGE    
        double dcf_dve_v= LUT(param.dcf_dve_v_lut);
        #define F_V_EDG_F (states.bld_edg_d*dcf_dve_v)
    #else
        #define F_V_EDG_F 0.0    
    #endif
    modalFlapForce= Fwind_v*(vwind_eff*cflp + states.bld_flp_d*dcf_dvf_v + F_V_EDG_F);
#endif

#ifdef EDGE    
    cedg= LUT(param.ce_lut);
    #ifdef FLAP
        double dce_dvf_v= LUT(param.dce_dvf_v_lut);
        #define F_V_FLP_E (states.bld_flp_d*dce_dvf_v)
    #else
        #define F_V_FLP_E 0.0
    #endif
    double dce_dve_v= LUT(param.dce_dve_v_lut);
    modalEdgeForce= Fwind_v*(vwind_eff*cedg + F_V_FLP_E + states.bld_edg_d*dce_dve_v);
#endif

#ifdef ROOT_MOM
    cmy_D23= LUT(param.cmy_D23_lut);
    MyD23= param.Rrot*Fwind_v*vwind_eff*cmy_D23;
#endif   

#ifdef TOW_SIDE
    double dcs_dvy_v= LUT(param.dcs_dvy_v_lut);
    Ftow_y= 1.5*Fwind_v*states.tow_ss_d*dcs_dvy_v;
#endif
}

static void aeroForceDerivs(const double torque_R, const double cx_stat, const double dcx_dlam, const double dcx_dtheta, 
                            const double dcx_dvf_v, const double dcx_dve_v, 
                            const double dlam_dvw, const double dlam_dvtow, const double dlam_dphi_rot_d,
                            const double Fwind, const double Fwind_v, const double dFwind_dvtow, const double dFwind_dvw, 
                            double &dX_dtow_fa_d, double &dX_dphi_rot_d, double &dX_dbld_flp_d, double &dX_dbld_edg_d, double &dX_dvwind, double &dX_dtheta) {
    double dcx_dvw= dcx_dlam * dlam_dvw;
    double dcx_dvtow= dcx_dlam * dlam_dvtow;
    double dcx_dphi_rot_d= dcx_dlam * dlam_dphi_rot_d;
    
    dX_dtow_fa_d= torque_R * (dFwind_dvtow*cx_stat + Fwind*dcx_dvtow);    // TODO to be exact, the derivative of the edge and flap terms is missing here 
    dX_dphi_rot_d= torque_R * Fwind*dcx_dphi_rot_d;                          // TODO to be exact, the derivative of the edge and flap terms is missing here 
    dX_dbld_flp_d= torque_R * Fwind_v * dcx_dvf_v;
    dX_dbld_edg_d= torque_R * Fwind_v * dcx_dve_v;
    dX_dvwind= torque_R * (dFwind_dvw*cx_stat + Fwind*dcx_dvw);      // TODO to be exact, the derivative of the edge and flap terms is missing here 
    dX_dtheta= torque_R * Fwind*dcx_dtheta;                        // TODO to be exact, the derivative of the edge and flap terms is missing here 
}

void SYSTEM::calculateExternalWithDeriv() {
    theta_deg= -inputs.theta/M_PI*180.0;
    double vwind_eff= VWIND-VTOW;
    lam= states.phi_rot_d*param.Rrot/vwind_eff;
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
    
    double dFwind_dvw   =  2*Fwind_v; // 2*Fwind/vwind;
    double dFwind_dvtow = -2*Fwind_v; // -2*Fwind/vwind;
    
    double dlam_dvw   = -lam/VWIND;
    double dlam_dvtow =  lam/VWIND;
    double dlam_dphi_rot_d= lam/states.phi_rot_d;
    
    cm= LUT(param.cm_lut);
#ifdef FLAP
    double dcm_dvf_v= LUT(param.dcm_dvf_v_lut);
    #define F_V_FLP (states.bld_flp_d*dcm_dvf_v)
#else
    #define dcm_dvf_v 0.0
    #define F_V_FLP 0.0
    double dTrot_dbld_flp_d;
#endif
#ifdef EDGE    
    double dcm_dve_v= LUT(param.dcm_dve_v_lut);
    #define F_V_EDG (states.bld_edg_d*dcm_dve_v)
#else
    #define dcm_dve_v 0.0
    #define F_V_EDG 0.0
    double dTrot_dbld_edg_d;
#endif
#ifndef THRUST
    double dTrot_dtow_fa_d;
#endif
    Trot= param.Rrot*Fwind_v*(vwind_eff*cm + F_V_FLP + F_V_EDG);
    
    aeroForceDerivs(param.Rrot, cm, DLAM_LUT(param.cm_lut), DTH_LUT(param.cm_lut), 
                    dcm_dvf_v, dcm_dve_v, 
                    dlam_dvw, dlam_dvtow, dlam_dphi_rot_d,
                    Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw, 
                    dTrot_dtow_fa_d, dTrot_dphi_rot_d, dTrot_dbld_flp_d, dTrot_dbld_edg_d, dTrot_dvwind, dTrot_dtheta);

#ifdef THRUST
    ct= LUT(param.ct_lut);
    #ifdef FLAP
        double dct_dvf_v= LUT(param.dct_dvf_v_lut);
        #define F_V_FLP_T (states.bld_flp_d*dct_dvf_v)
    #else
        #define dct_dvf_v 0.0
        #define F_V_FLP_T 0.0
        double dFthrust_dbld_flp_d;
    #endif
    #ifdef EDGE    
        double dct_dve_v= LUT(param.dct_dve_v_lut);
        #define F_V_EDG_T (states.bld_edg_d*dct_dve_v)
    #else
        #define dct_dve_v 0.0
        #define F_V_EDG_T 0.0  
        double dFthrust_dbld_edg_d;
    #endif
    Fthrust= Fwind_v*(vwind_eff*ct + F_V_FLP_T + F_V_EDG_T);

    aeroForceDerivs(1.0, ct, DLAM_LUT(param.ct_lut), DTH_LUT(param.ct_lut), 
                    dct_dvf_v, dct_dve_v, 
                    dlam_dvw, dlam_dvtow, dlam_dphi_rot_d,
                    Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw, 
                    dFthrust_dtow_fa_d, dFthrust_dphi_rot_d, dFthrust_dbld_flp_d, dFthrust_dbld_edg_d, dFthrust_dvwind, dFthrust_dtheta);
#endif
    
#ifdef FLAP
    cflp= LUT(param.cf_lut);
    double dcf_dvf_v= LUT(param.dcf_dvf_v_lut);
    #ifdef EDGE    
        double dcf_dve_v= LUT(param.dcf_dve_v_lut);
        #define F_V_EDG_F (states.bld_edg_d*dcf_dve_v)
    #else
        #define dcf_dve_v 0.0
        #define F_V_EDG_F 0.0
        double dmodalFlapForce_dbld_edg_d;
    #endif
    #ifndef THRUST
        double dmodalFlapForce_dtow_fa_d;
    #endif
        
    modalFlapForce= Fwind_v*(vwind_eff*cflp + states.bld_flp_d*dcf_dvf_v + F_V_EDG_F);

    aeroForceDerivs(1.0, cflp, DLAM_LUT(param.cf_lut), DTH_LUT(param.cf_lut), 
                    dcf_dvf_v, dcf_dve_v, 
                    dlam_dvw, dlam_dvtow, dlam_dphi_rot_d,
                    Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw, 
                    dmodalFlapForce_dtow_fa_d, dmodalFlapForce_dphi_rot_d, dmodalFlapForce_dbld_flp_d, dmodalFlapForce_dbld_edg_d, dmodalFlapForce_dvwind, dmodalFlapForce_dtheta);    
#endif

#ifdef EDGE    
    cedg= LUT(param.ce_lut);
    #ifdef FLAP
        double dce_dvf_v= LUT(param.dce_dvf_v_lut);
        #define F_V_FLP_E (states.bld_flp_d*dce_dvf_v)
    #else
        #define dce_dvf_v 0.0
        #define F_V_FLP_E 0.0
        double dmodalEdgeForce_dbld_flp_d;
    #endif
    #ifndef THRUST
        double dmodalEdgeForce_dtow_fa_d;
    #endif
        
    double dce_dve_v= LUT(param.dce_dve_v_lut);
    modalEdgeForce= Fwind_v*(vwind_eff*cedg + F_V_FLP_E + states.bld_edg_d*dce_dve_v);
    
    aeroForceDerivs(1.0, cedg, -1.0*DLAM_LUT(param.ce_lut), -1.0*DTH_LUT(param.ce_lut), 
                    dce_dvf_v, dce_dve_v, 
                    dlam_dvw, dlam_dvtow, dlam_dphi_rot_d,
                    Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw, 
                    dmodalEdgeForce_dtow_fa_d, dmodalEdgeForce_dphi_rot_d, dmodalEdgeForce_dbld_flp_d, dmodalEdgeForce_dbld_edg_d, dmodalEdgeForce_dvwind, dmodalEdgeForce_dtheta);    
#endif

#ifdef ROOT_MOM
    cmy_D23= LUT(param.cmy_D23_lut);
    MyD23= param.Rrot*Fwind_v*vwind_eff*cmy_D23;

    double dMyD23_dlam=  DLAM_LUT(param.cmy_D23_lut);
    dMyD23_dphi_rot_d= param.Rrot*dMyD23_dlam * dlam_dphi_rot_d;
    dMyD23_dvwind= param.Rrot*dMyD23_dlam * dlam_dvw;
    dMyD23_dtheta= param.Rrot*DTH_LUT(param.cmy_D23_lut);    
#endif   

#ifdef TOW_SIDE
    double dcs_dvy_v= LUT(param.dcs_dvy_v_lut);
    Ftow_y= 1.5*Fwind_v*states.tow_ss_d*dcs_dvy_v;
    
    dFtow_y_dtow_ss_d= 1.5*Fwind_v*dcs_dvy_v;
    // TODO to be exact, the derivative with respect to phi_rot_d, wind and theta are missing here 
#endif
}
