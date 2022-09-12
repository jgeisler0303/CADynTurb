#include <cmath>

#define LUT(tab) (thetaFact*(lambdaFact*tab(lambdaIdx, thetaIdx) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx)) + (1.0-thetaFact)*(lambdaFact*tab(lambdaIdx, thetaIdx+1) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx+1)))
#define DLAM_LUT(tab) ((thetaFact*(tab(lambdaIdx+1, thetaIdx)-tab(lambdaIdx, thetaIdx))/param.lambdaStep) + (1.0-thetaFact)*((tab(lambdaIdx+1, thetaIdx)-tab(lambdaIdx, thetaIdx))/param.lambdaStep))
#define DTH_LUT(tab) (( (lambdaFact*tab(lambdaIdx, thetaIdx+1) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx+1))-(lambdaFact*tab(lambdaIdx, thetaIdx) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx)) )/param.thetaStep)

void turbine_T1_aeroSystem::calculateExternal() {
    theta_deg= -inputs.theta/M_PI*180.0;
    double vwind_eff= inputs.vwind-states.tow_fa_d;
    lam= states.phi_rot_d*param.Rrot/vwind_eff;
    double Fwind= param.rho/2.0*param.Arot*vwind_eff*vwind_eff;
    
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
    
    Trot= param.Rrot*Fwind*cm;
    Fthrust= Fwind*ct;
}

static void aeroForceDerivs(const doubel torque_R, const double cx_stat, const double dcx_dlam, const double dcx_dtheta, 
                            const double dlam_dvw, const double dlam_dvtow, const double dlam_dphi_rot_d,
                            const double Fwind, const double Fwind_v, const double dFwind_dvtow, const double dFwind_dvw, 
                            double &dX_dqd1, double &dX_dqd3, double &dX_dvwind, double &dX_dtheta) {
    double dcx_dvw= dcx_dlam * dlam_dvw;
    double dcx_dvtow= dcx_dlam * dlam_dvtow;
    double dcx_dphi_rot_d= dcx_dlam * dlam_dphi_rot_d;
    
    dX_dqd1= torque_R * (dFwind_dvtow*cx_stat + Fwind*dcx_dvtow);    // TODO to be exact, the derivative of the edge and flap terms is missing here 
    dX_dqd3= torque_R * Fwind*dcx_dphi_rot_d;                          // TODO to be exact, the derivative of the edge and flap terms is missing here 
    dX_dvwind= torque_R * (dFwind_dvw*cx_stat + Fwind*dcx_dvw);      // TODO to be exact, the derivative of the edge and flap terms is missing here 
    dX_dtheta= torque_R * Fwind*dcx_dtheta;                        // TODO to be exact, the derivative of the edge and flap terms is missing here 
}

void turbine_T1_aeroSystem::calculateExternalWithDeriv() {
    theta_deg= -inputs.theta/M_PI*180.0;
    double vwind_eff= inputs.vwind-states.tow_fa_d;
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
    
    cm= LUT(param.cm_lut);
    ct= LUT(param.ct_lut);

    Trot= param.Rrot*Fwind*cm;
    Fthrust= Fwind*ct;
    
    double dFwind_dvw   =  2*Fwind_v; // 2*Fwind/vwind;
    double dFwind_dvtow = -2*Fwind_v; // -2*Fwind/vwind;
    
    double dlam_dvw   = -lam/inputs.vwind;
    double dlam_dvtow =  lam/inputs.vwind;
    double dlam_dphi_rot_d= lam/states.phi_rot_d;
    
    aeroForceDerivs(param.Rrot, cm, DLAM_LUT(param.cm_lut), DTH_LUT(param.cm_lut), 
                    dlam_dvw, dlam_dvtow, dlam_dphi_rot_d,
                    Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw, 
                    dTrot_dtow_fa_d, dTrot_dphi_rot_d, dTrot_dvwind, dTrot_dtheta);
    
    aeroForceDerivs(1.0, ct, DLAM_LUT(param.ct_lut), DTH_LUT(param.ct_lut), 
                    dlam_dvw, dlam_dvtow, dlam_dphi_rot_d,
                    Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw, 
                    dFthrust_dtow_fa_d, dFthrust_dphi_rot_d, dFthrust_dvwind, dFthrust_dtheta);    
}
