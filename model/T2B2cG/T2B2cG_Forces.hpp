#define SYSTEM T2B2cG
#define THRUST
#define FLAP
#define EDGE
#define ROOT_MOM
#define TOW_SIDE

#include <cmath>

#define LUT(tab) (thetaFact*(lambdaFact*tab(lambdaIdx, thetaIdx) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx)) + (1.0-thetaFact)*(lambdaFact*tab(lambdaIdx, thetaIdx+1) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx+1)))
#define DLAM_LUT(tab) ((thetaFact*(tab(lambdaIdx+1, thetaIdx)-tab(lambdaIdx, thetaIdx))/param.lambdaStep) + (1.0-thetaFact)*((tab(lambdaIdx+1, thetaIdx)-tab(lambdaIdx, thetaIdx))/param.lambdaStep))
#define DTH_LUT(tab) (( (lambdaFact*tab(lambdaIdx, thetaIdx+1) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx+1))-(lambdaFact*tab(lambdaIdx, thetaIdx) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx)) )/param.thetaStep * -180.0/M_PI)

template <typename scalar_type, typename real_type>
void MultiBodySystemODE<scalar_type, real_type>::calculateForces(const VecQn<scalar_type> &q, const VecQn<scalar_type> &qd, const VecQn<scalar_type> &qdd, const VecUn<scalar_type> &u) {
    scalar_type theta_deg= -theta/M_PI*180.0;
    scalar_type vwind_eff= vwind-tow_fa_d;
    lam= phi_rot_d*param.Rrot/vwind_eff;
    scalar_type Fwind_v= param.rho/2.0*param.Arot*vwind_eff;
    
    if(lam>param.lambdaMax-param.lambdaStep) lam= param.lambdaMax-param.lambdaStep;
    if(lam<param.lambdaMin) lam= param.lambdaMin;
    if(theta_deg>param.thetaMax-param.thetaStep) theta_deg= param.thetaMax-param.thetaStep;
    if(theta_deg<param.thetaMin) theta_deg= param.thetaMin;
    
    scalar_type lambdaScaled= (lam-param.lambdaMin)/param.lambdaStep;
    int lambdaIdx= std::floor(lambdaScaled);
    scalar_type thetaScaled= (theta_deg-param.thetaMin)/param.thetaStep;
    int thetaIdx= std::floor(thetaScaled);
    scalar_type lambdaFact= 1.0 - lambdaScaled + lambdaIdx;
    scalar_type thetaFact= 1.0 - thetaScaled + thetaIdx;
    
    cm= LUT(param.cm_lut);
    
#ifdef FLAP
    scalar_type dcm_dvf_v= LUT(param.dcm_dvf_v_lut);
    #define F_V_FLP (bld_flp_d*dcm_dvf_v)
#else
    #define F_V_FLP 0.0
#endif
#ifdef EDGE    
    scalar_type dcm_dve_v= LUT(param.dcm_dve_v_lut);
    #define F_V_EDG (bld_edg_d*dcm_dve_v)
#else
    #define F_V_EDG 0.0    
#endif
    Trot= param.Rrot*Fwind_v*(vwind_eff*cm + F_V_FLP + F_V_EDG);

#ifdef THRUST
    ct= LUT(param.ct_lut);
    #ifdef FLAP
        scalar_type dct_dvf_v= LUT(param.dct_dvf_v_lut);
        #define F_V_FLP_T (bld_flp_d*dct_dvf_v)
    #else
        #define F_V_FLP_T 0.0
    #endif
    #ifdef EDGE    
        scalar_type dct_dve_v= LUT(param.dct_dve_v_lut);
        #define F_V_EDG_T (bld_edg_d*dct_dve_v)
    #else
        #define F_V_EDG_T 0.0    
    #endif
    Fthrust= Fwind_v*(vwind_eff*ct + F_V_FLP_T + F_V_EDG_T);
#endif
    
#ifdef FLAP
    cflp= LUT(param.cf_lut);
    scalar_type dcf_dvf_v= LUT(param.dcf_dvf_v_lut);
    #ifdef EDGE    
        scalar_type dcf_dve_v= LUT(param.dcf_dve_v_lut);
        #define F_V_EDG_F (bld_edg_d*dcf_dve_v)
    #else
        #define F_V_EDG_F 0.0    
    #endif
    modalFlapForce= Fwind_v*(vwind_eff*cflp + bld_flp_d*dcf_dvf_v + F_V_EDG_F);
#endif

#ifdef EDGE    
    cedg= LUT(param.ce_lut);
    #ifdef FLAP
        scalar_type dce_dvf_v= LUT(param.dce_dvf_v_lut);
        #define F_V_FLP_E (bld_flp_d*dce_dvf_v)
    #else
        #define F_V_FLP_E 0.0
    #endif
    scalar_type dce_dve_v= LUT(param.dce_dve_v_lut);
    modalEdgeForce= Fwind_v*(vwind_eff*cedg + F_V_FLP_E + bld_edg_d*dce_dve_v);
#endif

#ifdef ROOT_MOM
    cmy_D23= LUT(param.cmy_D23_lut);
    MyD23= param.Rrot*Fwind_v*vwind_eff*cmy_D23;
#endif   

#ifdef TOW_SIDE
    scalar_type dcs_dvy_v= LUT(param.dcs_dvy_v_lut);
    Ftow_y= 1.5*Fwind_v*tow_ss_d*dcs_dvy_v;
#endif
    
    Vec3<scalar_type> r_thurst= Vec3<scalar_type>::Unit(3)*2.0/3.0*param.Rrot;
    Vec3<scalar_type> F_thrust_f= Vec3<scalar_type>::Unit(1)*cos(theta)*Fthrust/3.0;

    Vec3<scalar_type> F_in_local= ebody4.TG.linear() * F_thrust_f;
    ebody4.Fext= F_in_local;
    ebody4.Mext= (ebody4.TG.linear()*r_thurst).cross(F_in_local);
    F_in_local= ebody5.TG.linear() * F_thrust_f;
    ebody5.Fext= F_in_local;
    ebody5.Mext= (ebody5.TG.linear()*r_thurst).cross(F_in_local);
    F_in_local= ebody6.TG.linear() * F_thrust_f;
    ebody6.Fext= F_in_local;
    ebody6.Mext= (ebody6.TG.linear()*r_thurst).cross(F_in_local);

    Vec3<scalar_type> F_thrust_e= Vec3<scalar_type>::Unit(1)*(-sin(theta))*Fthrust/3.0;
    F_in_local= ebody4.TG.linear() * F_thrust_e;
    ebody4.Fext+= F_in_local;
    ebody4.Mext+= (ebody4.TG.linear()*r_thurst).cross(F_in_local);
    F_in_local= ebody5.TG.linear() * F_thrust_e;
    ebody5.Fext+= F_in_local;
    ebody5.Mext+= (ebody5.TG.linear()*r_thurst).cross(F_in_local);
    F_in_local= ebody6.TG.linear() * F_thrust_e;
    ebody6.Fext+= F_in_local;
    ebody6.Mext+= (ebody6.TG.linear()*r_thurst).cross(F_in_local);
    
    Vec3<scalar_type> MyD23_vec= Vec3<scalar_type>::Unit(2)*MyD23;
    ebody4.Mext+= ebody4.TG.linear() * Eigen::AngleAxis<scalar_type>(-theta, Vec3<scalar_type>::Unit(3)) * MyD23_vec;
    ebody5.Mext+= ebody5.TG.linear() * Eigen::AngleAxis<scalar_type>(-theta, Vec3<scalar_type>::Unit(3)) * MyD23_vec;
    ebody6.Mext+= ebody6.TG.linear() * Eigen::AngleAxis<scalar_type>(-theta, Vec3<scalar_type>::Unit(3)) * MyD23_vec;
    
    Vec3<scalar_type> r_torque= Vec3<scalar_type>::Unit(3)*param.torqueForceRadius;
    Vec3<scalar_type> F_torque_f= Vec3<scalar_type>::Unit(1)*(-sin(theta))*Trot/3.0/param.torqueForceRadius;

    F_in_local= ebody4.TG.linear() * F_torque_f;
    ebody4.Fext+= F_in_local;
    ebody4.Mext+= (ebody4.TG.linear()*r_torque).cross(F_in_local);
    F_in_local= ebody5.TG.linear() * F_torque_f;
    ebody5.Fext+= F_in_local;
    ebody5.Mext+= (ebody5.TG.linear()*r_torque).cross(F_in_local);
    F_in_local= ebody6.TG.linear() * F_torque_f;
    ebody6.Fext+= F_in_local;
    ebody6.Mext+= (ebody6.TG.linear()*r_torque).cross(F_in_local);

    Vec3<scalar_type> F_torque_e= Vec3<scalar_type>::Unit(2)*(-cos(theta))*Trot/3.0/param.torqueForceRadius;
    F_in_local= ebody4.TG.linear() * F_torque_e;
    ebody4.Fext+= F_in_local;
    ebody4.Mext+= (ebody4.TG.linear()*r_torque).cross(F_in_local);
    F_in_local= ebody5.TG.linear() * F_torque_e;
    ebody5.Fext+= F_in_local;
    ebody5.Mext+= (ebody5.TG.linear()*r_torque).cross(F_in_local);
    F_in_local= ebody6.TG.linear() * F_torque_e;
    ebody6.Fext+= F_in_local;
    ebody6.Mext+= (ebody6.TG.linear()*r_torque).cross(F_in_local);

    ebody4.Fe_ext(0)= modalFlapForce;
    ebody4.Fe_ext(1)= modalEdgeForce;
    ebody5.Fe_ext(0)= modalFlapForce;
    ebody5.Fe_ext(1)= modalEdgeForce;
    ebody6.Fe_ext(0)= modalFlapForce;
    ebody6.Fe_ext(1)= modalEdgeForce;

    scalar_type M_DT= -param.DTTorSpr*(phi_gen/param.GBRatio-phi_rot) - param.DTTorDmp*(phi_gen_d/param.GBRatio-phi_rot_d);

    body7.Mext(0)= M_DT/param.GBRatio - Tgen;
    body3.Mext(0)= -M_DT;
    body2.Mext(0)= M_DT;
    
    body2.Fext(1)= Ftow_y;
}
