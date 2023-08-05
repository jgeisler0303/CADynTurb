/* File generated form template cadyn_direct.cpp.tem on 2023-08-04 11:03:26+02:00. Do not edit! */

/* Multibody system: Simulation of a simplified horizontal axis wind turbine */



#include <string>
#include <map>
#include <fstream>
#include <iostream>
#include <stdlib.h>
#include <chrono>
#include <cstdio>
#include <ctime>

#include "NewmarkBeta.hpp"

typedef double real_type;

#include "turbine_T2B2cG_aero_param.hpp"

#define mcond(c, a, x, b) ((c)? a:b)

class T2B2cG: public NewmarkBeta<6, 3, 7, real_type> {
public:
    typedef Eigen::Matrix<real_type, 0, 1> VecP;
    
    T2B2cG();
        
    void precalcConsts();
    virtual VecQ computeResiduals();
    virtual void calcJacobian(real_type alphaM, real_type alphaC, real_type alphaK);
    virtual void calcB();
    virtual void calcCDF();
    virtual void calcOut();
    void calculateExternal();
    void calculateExternalWithDeriv();

    
    turbine_T2B2cG_aeroParameters param;
    
// private:
    VecP p, pd, pdd;

    class inputs_t {
    public:
        inputs_t(real_type &vwind, real_type &Tgen, real_type &theta) : vwind(vwind), Tgen(Tgen), theta(theta) {};

        real_type &vwind;
        real_type &Tgen;
        real_type &theta;
    } inputs;

    struct states_t {
    public:
        states_t(real_type &tow_fa, real_type &tow_fa_d, real_type &tow_fa_dd, real_type &tow_ss, real_type &tow_ss_d, real_type &tow_ss_dd, real_type &bld_flp, real_type &bld_flp_d, real_type &bld_flp_dd, real_type &bld_edg, real_type &bld_edg_d, real_type &bld_edg_dd, real_type &phi_rot, real_type &phi_rot_d, real_type &phi_rot_dd, real_type &phi_gen, real_type &phi_gen_d, real_type &phi_gen_dd) : tow_fa(tow_fa), tow_fa_d(tow_fa_d), tow_fa_dd(tow_fa_dd), tow_ss(tow_ss), tow_ss_d(tow_ss_d), tow_ss_dd(tow_ss_dd), bld_flp(bld_flp), bld_flp_d(bld_flp_d), bld_flp_dd(bld_flp_dd), bld_edg(bld_edg), bld_edg_d(bld_edg_d), bld_edg_dd(bld_edg_dd), phi_rot(phi_rot), phi_rot_d(phi_rot_d), phi_rot_dd(phi_rot_dd), phi_gen(phi_gen), phi_gen_d(phi_gen_d), phi_gen_dd(phi_gen_dd) {};

        real_type &tow_fa;
        real_type &tow_fa_d;
        real_type &tow_fa_dd;
        real_type &tow_ss;
        real_type &tow_ss_d;
        real_type &tow_ss_dd;
        real_type &bld_flp;
        real_type &bld_flp_d;
        real_type &bld_flp_dd;
        real_type &bld_edg;
        real_type &bld_edg_d;
        real_type &bld_edg_dd;
        real_type &phi_rot;
        real_type &phi_rot_d;
        real_type &phi_rot_dd;
        real_type &phi_gen;
        real_type &phi_gen_d;
        real_type &phi_gen_dd;
    } states;


    typedef struct {
        int tow_fa;
        int tow_ss;
        int bld_flp;
        int bld_edg;
        int phi_rot;
        int phi_gen;
    } states_idx_type;

    static const states_idx_type states_idx;
    
    real_type cm;
    real_type ct;
    real_type cflp;
    real_type cedg;
    real_type cmy_D23;
    real_type theta_deg;
    real_type lam;
    real_type Trot;
    real_type MyD23;
    real_type Fthrust;
    real_type Ftow_y;
    real_type modalFlapForce;
    real_type modalEdgeForce;
    real_type dTrot_dtow_fa_d;
    real_type dTrot_dphi_rot_d;
    real_type dTrot_dbld_flp_d;
    real_type dTrot_dbld_edg_d;
    real_type dTrot_dvwind;
    real_type dTrot_dtheta;
    real_type dMyD23_dphi_rot_d;
    real_type dMyD23_dvwind;
    real_type dMyD23_dtheta;
    real_type dFthrust_dtow_fa_d;
    real_type dFthrust_dphi_rot_d;
    real_type dFthrust_dbld_flp_d;
    real_type dFthrust_dbld_edg_d;
    real_type dFthrust_dvwind;
    real_type dFthrust_dtheta;
    real_type dFtow_y_dtow_ss_d;
    real_type dmodalFlapForce_dtow_fa_d;
    real_type dmodalFlapForce_dphi_rot_d;
    real_type dmodalFlapForce_dbld_flp_d;
    real_type dmodalFlapForce_dbld_edg_d;
    real_type dmodalFlapForce_dvwind;
    real_type dmodalFlapForce_dtheta;
    real_type dmodalEdgeForce_dtow_fa_d;
    real_type dmodalEdgeForce_dphi_rot_d;
    real_type dmodalEdgeForce_dbld_flp_d;
    real_type dmodalEdgeForce_dbld_edg_d;
    real_type dmodalEdgeForce_dvwind;
    real_type dmodalEdgeForce_dtheta;



};

const T2B2cG::states_idx_type T2B2cG::states_idx= {0, 1, 2, 3, 4, 5};

T2B2cG::T2B2cG() : 
    NewmarkBeta("turbine_T2B2cG_aero", "Simulation of a simplified horizontal axis wind turbine"),
    param(),
    inputs(u.data()[0], u.data()[1], u.data()[2]),
    states(q.data()[0], qd.data()[0], qdd.data()[0], q.data()[1], qd.data()[1], qdd.data()[1], q.data()[2], qd.data()[2], qdd.data()[2], q.data()[3], qd.data()[3], qdd.data()[3], q.data()[4], qd.data()[4], qdd.data()[4], q.data()[5], qd.data()[5], qdd.data()[5])
{
    in_name[0]="vwind";
    in_name[1]="Tgen";
    in_name[2]="theta";

    state_name[0]="tow_fa";
    state_name[1]="tow_ss";
    state_name[2]="bld_flp";
    state_name[3]="bld_edg";
    state_name[4]="phi_rot";
    state_name[5]="phi_gen";
}

void T2B2cG::precalcConsts() {
    
}

T2B2cG::VecQ T2B2cG::computeResiduals() {
    VecQ f_;
    
    calculateExternal();


    {

    }
    {
        real_type temp1=cos(u[2]);
        real_type temp2=sin(u[2]);
        real_type temp3=6.0*param.blade_mass+2.0*param.NacMass+2.0*param.HubMass;
        real_type temp4=pow(param.NacCMzn,2.0);
        real_type temp5=pow(param.OverHang,2.0);
        real_type temp6=pow(param.Twr2Shft,2.0);
        real_type temp7=pow(temp1,2.0);
        real_type temp8=pow(param.tower_frame_11_psi0_2_1,2.0);
        real_type temp9=pow(param.GBRatio,2.0);
        real_type temp10=1.0/pow(temp9,1.0);
        real_type temp11=-3.0*param.blade_mass*temp9-param.NacMass*temp9-param.HubMass*temp9;
        real_type temp12=-param.HubIner*temp9;
        real_type temp13=-3.0*param.blade_I0_2_2*temp9;
        real_type temp14=3.0*param.blade_I0_2_2*temp9-3.0*param.blade_I0_1_1*temp9;
        real_type temp15=pow(qd[4],2.0);
        real_type temp16=pow(temp2,2.0);
        real_type temp17=Trot*param.GBRatio;
        real_type temp18=q[5]*param.DTTorSpr;
        real_type temp19=qd[5]*param.DTTorDmp;
        real_type temp20=-q[4]*param.DTTorSpr*param.GBRatio;
        real_type temp21=-qd[4]*param.DTTorDmp*param.GBRatio;
        real_type temp22=-param.GBRatio*param.HubIner;
        real_type temp23=-3.0*param.GBRatio*param.blade_I0_2_2;
        real_type temp24=temp23+temp22;
        real_type temp25=qdd[4]*temp24;
        real_type temp26=3.0*param.GBRatio*param.blade_I0_2_2-3.0*param.GBRatio*param.blade_I0_1_1;
        real_type temp27=qdd[4]*temp26*temp7;
        real_type temp28=-q[1]*param.DTTorSpr*param.GBRatio*param.TwTrans2Roll;
        real_type temp29=-qd[1]*param.DTTorDmp*param.GBRatio*param.TwTrans2Roll;
        real_type temp30=pow(q[0],2.0);

        f_[0]=0.5*((qdd[0]*((3.0*param.blade_I0_2_2-3.0*param.blade_I0_1_1)*temp7+param.blade_mass*(6.0*temp6+6.0*temp5)+2.0*param.HubMass*temp6+2.0*param.HubMass*temp5+param.NacMass*(2.0*temp4+2.0*pow(param.NacCMxn,2.0))+3.0*param.blade_I0_3_3+3.0*param.blade_I0_1_1+4.0*param.HubCM*param.HubMass*param.OverHang+2.0*param.NacYIner+2.0*pow(param.HubCM,2.0)*param.HubMass+2.0*param.HubIner)-2.0*q[0]*Fthrust*param.OverHang)*temp8+q[0]*param.g*param.tower_frame_11_phi1_1_3_1*temp3+qdd[0]*pow(param.tower_frame_11_origin1_1_1_1,2.0)*temp3+param.tower_frame_11_psi0_2_1*(((6.0*q[3]*param.blade_md1_2_2_1+6.0*q[2]*param.blade_md1_1_2_1)*param.g-6.0*qdd[3]*param.Twr2Shft*param.blade_Ct0_2_2-6.0*qdd[2]*param.Twr2Shft*param.blade_Ct0_1_2)*temp2+((-6.0*q[3]*param.blade_md1_2_1_1-6.0*q[2]*param.blade_md1_1_1_1)*param.g+6.0*qdd[3]*param.Twr2Shft*param.blade_Ct0_2_1+6.0*qdd[2]*param.Twr2Shft*param.blade_Ct0_1_1)*temp1-2.0*qdd[1]*param.NacCMxn*param.NacCMyn*param.NacMass*param.tower_frame_11_psi0_1_2+qdd[
         0]*(12.0*param.Twr2Shft*param.blade_mass+4.0*param.HubMass*param.Twr2Shft+4.0*param.NacCMzn*param.NacMass)*param.tower_frame_11_origin1_1_1_1+(-6.0*param.OverHang*param.blade_mass-2.0*param.HubMass*param.OverHang-2.0*param.NacCMxn*param.NacMass-2.0*param.HubCM*param.HubMass)*param.g-2.0*Fthrust*param.Twr2Shft)+param.tower_frame_11_origin1_1_1_1*((-6.0*qdd[3]*param.blade_Ct0_2_2-6.0*qdd[2]*param.blade_Ct0_1_2)*temp2+(6.0*qdd[3]*param.blade_Ct0_2_1+6.0*qdd[2]*param.blade_Ct0_1_1)*temp1-2.0*Fthrust)+2.0*qdd[0]*param.tower_Me0_1_1+2.0*q[0]*param.tower_K0_1_1+2.0*qd[0]*param.tower_D0_1_1+2.0*q[0]*param.g*param.tower_Ct1_1_1_3);
        f_[1]=-temp10*(qdd[1]*pow(param.tower_frame_11_psi0_1_2,2.0)*(param.NacMass*(-temp4*temp9-pow(param.NacCMyn,2.0)*temp9)-3.0*param.blade_mass*temp6*temp9-param.HubMass*temp6*temp9-param.NacXIner*temp9-param.GenIner*temp9+temp14*temp7+temp13+temp12)+param.tower_frame_11_psi0_1_2*(qdd[1]*param.tower_frame_11_origin1_2_2_1*(6.0*param.Twr2Shft*param.blade_mass*temp9+2.0*param.HubMass*param.Twr2Shft*temp9+2.0*param.NacCMzn*param.NacMass*temp9)+temp2*(3.0*qdd[3]*param.blade_Cr0_2_2*temp9+3.0*qdd[2]*param.blade_Cr0_1_2*temp9)+temp1*(-3.0*qdd[3]*param.blade_Cr0_2_1*temp9-3.0*qdd[2]*param.blade_Cr0_1_1*temp9)-param.NacCMyn*param.NacMass*param.g*temp9-Ftow_y*param.NacCMzn*temp9-qdd[5]*param.GenIner*temp9+Trot*temp9-u[1]*temp9+qdd[4]*temp14*temp7+qdd[4]*(temp13+temp12)+q[1]*param.DTTorSpr*param.GBRatio*param.TwTrans2Roll+qd[1]*param.DTTorDmp*param.GBRatio*param.TwTrans2Roll+q[4]*param.DTTorSpr*param.GBRatio+qd[4]*param.DTTorDmp*param.GBRatio-q[5]*param.DTTorSpr-qd[5]*param.DTTorDmp)+qdd[0]
         *param.NacCMxn*param.NacCMyn*param.NacMass*param.tower_frame_11_psi0_1_2*param.tower_frame_11_psi0_2_1*temp9+Ftow_y*param.tower_frame_11_origin1_2_2_1*temp9-qdd[1]*param.tower_Me0_2_2*temp9-q[1]*param.tower_K0_2_2*temp9-qd[1]*param.tower_D0_2_2*temp9-q[1]*param.g*param.tower_Ct1_2_2_3*temp9+q[1]*param.g*param.tower_frame_11_phi1_2_3_2*temp11+qdd[1]*pow(param.tower_frame_11_origin1_2_2_1,2.0)*temp11);
        f_[2]=(3.0*q[3]*param.blade_Oe1_2_1_1+3.0*q[2]*param.blade_Oe1_1_1_1)*temp15*temp7+param.tower_frame_11_psi0_2_1*(q[0]*(3.0*param.blade_Ct0_1_2*param.g*temp2-3.0*param.blade_Ct0_1_1*param.g*temp1)+qdd[0]*(-3.0*param.Twr2Shft*param.blade_Ct0_1_2*temp2+3.0*param.Twr2Shft*param.blade_Ct0_1_1*temp1))+qdd[0]*param.tower_frame_11_origin1_1_1_1*(-3.0*param.blade_Ct0_1_2*temp2+3.0*param.blade_Ct0_1_1*temp1)+qdd[1]*param.tower_frame_11_psi0_1_2*(-3.0*param.blade_Cr0_1_2*temp2+3.0*param.blade_Cr0_1_1*temp1)+((-3.0*q[3]*param.blade_Oe1_2_1_4-3.0*q[2]*param.blade_Oe1_1_1_4)*temp1*temp15-3.0*qdd[4]*param.blade_Cr0_1_2)*temp2+(3.0*q[3]*param.blade_Oe1_2_1_2+3.0*q[2]*param.blade_Oe1_1_1_2)*temp15*temp16+3.0*qdd[4]*param.blade_Cr0_1_1*temp1+3.0*qdd[3]*param.blade_Me0_1_2+3.0*qdd[2]*param.blade_Me0_1_1+3.0*q[3]*param.blade_K0_1_2+3.0*q[2]*param.blade_K0_1_1+3.0*qd[2]*param.blade_D0_1_1-3.0*modalFlapForce;
        f_[3]=(3.0*q[3]*param.blade_Oe1_2_2_1+3.0*q[2]*param.blade_Oe1_1_2_1)*temp15*temp7+param.tower_frame_11_psi0_2_1*(q[0]*(3.0*param.blade_Ct0_2_2*param.g*temp2-3.0*param.blade_Ct0_2_1*param.g*temp1)+qdd[0]*(-3.0*param.Twr2Shft*param.blade_Ct0_2_2*temp2+3.0*param.Twr2Shft*param.blade_Ct0_2_1*temp1))+qdd[0]*param.tower_frame_11_origin1_1_1_1*(-3.0*param.blade_Ct0_2_2*temp2+3.0*param.blade_Ct0_2_1*temp1)+qdd[1]*param.tower_frame_11_psi0_1_2*(-3.0*param.blade_Cr0_2_2*temp2+3.0*param.blade_Cr0_2_1*temp1)+((-3.0*q[3]*param.blade_Oe1_2_2_4-3.0*q[2]*param.blade_Oe1_1_2_4)*temp1*temp15-3.0*qdd[4]*param.blade_Cr0_2_2)*temp2+(3.0*q[3]*param.blade_Oe1_2_2_2+3.0*q[2]*param.blade_Oe1_1_2_2)*temp15*temp16+3.0*qdd[4]*param.blade_Cr0_2_1*temp1+3.0*qdd[3]*param.blade_Me0_2_2+3.0*qdd[2]*param.blade_Me0_2_1+3.0*q[3]*param.blade_K0_2_2+3.0*q[2]*param.blade_K0_2_1+3.0*qd[3]*param.blade_D0_2_2-3.0*modalEdgeForce;
        f_[4]=-((q[0]*qd[0]*(qd[4]*temp26*temp7+qd[4]*temp24)+(temp27+temp25+temp17)*temp30)*temp8+qdd[1]*param.tower_frame_11_psi0_1_2*(temp26*temp7+temp23+temp22)+temp29+temp28+temp27+temp25+temp21+temp20+(3.0*qdd[3]*param.GBRatio*param.blade_Cr0_2_2+3.0*qdd[2]*param.GBRatio*param.blade_Cr0_1_2)*temp2+temp19+temp18+temp17+(-3.0*qdd[3]*param.GBRatio*param.blade_Cr0_2_1-3.0*qdd[2]*param.GBRatio*param.blade_Cr0_1_1)*temp1)/pow(param.GBRatio,1.0);
        f_[5]=temp10*(temp8*(qdd[5]*param.GenIner*temp30*temp9+q[0]*qd[0]*qd[5]*param.GenIner*temp9)+qdd[1]*param.GenIner*param.tower_frame_11_psi0_1_2*temp9+qdd[5]*param.GenIner*temp9+u[1]*temp9+temp29+temp28+temp21+temp20+temp19+temp18);

    }

    return f_;
}

void T2B2cG::calcJacobian(real_type alphaM, real_type alphaC, real_type alphaK) {
    calculateExternalWithDeriv();

    {

    }
    {
        real_type temp1=cos(u[2]);
        real_type temp2=sin(u[2]);
        real_type temp3=6.0*param.blade_mass+2.0*param.NacMass+2.0*param.HubMass;
        real_type temp4=pow(param.tower_frame_11_origin1_1_1_1,2.0);
        real_type temp5=12.0*param.Twr2Shft*param.blade_mass+4.0*param.HubMass*param.Twr2Shft+4.0*param.NacCMzn*param.NacMass;
        real_type temp6=pow(param.NacCMzn,2.0);
        real_type temp7=pow(param.OverHang,2.0);
        real_type temp8=pow(param.Twr2Shft,2.0);
        real_type temp9=3.0*param.blade_I0_1_1;
        real_type temp10=3.0*param.blade_I0_2_2;
        real_type temp11=temp10-3.0*param.blade_I0_1_1;
        real_type temp12=pow(temp1,2.0);
        real_type temp13=temp11*temp12;
        real_type temp14=temp9+param.blade_mass*(6.0*temp8+6.0*temp7)+2.0*param.HubMass*temp8+2.0*param.HubMass*temp7+param.NacMass*(2.0*temp6+2.0*pow(param.NacCMxn,2.0))+temp13+3.0*param.blade_I0_3_3+4.0*param.HubCM*param.HubMass*param.OverHang+2.0*param.NacYIner+2.0*pow(param.HubCM,2.0)*param.HubMass+2.0*param.HubIner;
        real_type temp15=pow(param.tower_frame_11_psi0_2_1,2.0);
        real_type temp16=pow(param.GBRatio,2.0);
        real_type temp17=1.0/pow(temp16,1.0);
        real_type temp18=-3.0*param.blade_mass*temp16-param.NacMass*temp16-param.HubMass*temp16;
        real_type temp19=pow(param.tower_frame_11_origin1_2_2_1,2.0);
        real_type temp20=-param.HubIner*temp16;
        real_type temp21=-3.0*param.blade_I0_2_2*temp16;
        real_type temp22=3.0*param.blade_I0_2_2*temp16-3.0*param.blade_I0_1_1*temp16;
        real_type temp23=pow(param.NacCMyn,2.0);
        real_type temp24=pow(param.tower_frame_11_psi0_1_2,2.0);
        real_type temp25=pow(qd[4],2.0);
        real_type temp26=pow(temp2,2.0);
        real_type temp27=-3.0*param.blade_Ct0_1_2*temp2+3.0*param.blade_Ct0_1_1*temp1;
        real_type temp28=-3.0*param.blade_Cr0_1_2*temp2+3.0*param.blade_Cr0_1_1*temp1;
        real_type temp29=-3.0*param.Twr2Shft*param.blade_Ct0_1_2*temp2+3.0*param.Twr2Shft*param.blade_Ct0_1_1*temp1;
        real_type temp30=-3.0*param.blade_Ct0_2_2*temp2+3.0*param.blade_Ct0_2_1*temp1;
        real_type temp31=-3.0*param.blade_Cr0_2_2*temp2+3.0*param.blade_Cr0_2_1*temp1;
        real_type temp32=-3.0*param.Twr2Shft*param.blade_Ct0_2_2*temp2+3.0*param.Twr2Shft*param.blade_Ct0_2_1*temp1;
        real_type temp33=1.0/pow(param.GBRatio,1.0);
        real_type temp34=Trot*param.GBRatio;
        real_type temp35=q[5]*param.DTTorSpr;
        real_type temp36=qd[5]*param.DTTorDmp;
        real_type temp37=-q[4]*param.DTTorSpr*param.GBRatio;
        real_type temp38=-qd[4]*param.DTTorDmp*param.GBRatio;
        real_type temp39=-param.GBRatio*param.HubIner;
        real_type temp40=-3.0*param.GBRatio*param.blade_I0_2_2;
        real_type temp41=temp40+temp39;
        real_type temp42=qdd[4]*temp41;
        real_type temp43=3.0*param.GBRatio*param.blade_I0_2_2-3.0*param.GBRatio*param.blade_I0_1_1;
        real_type temp44=qdd[4]*temp12*temp43;
        real_type temp45=-q[1]*param.DTTorSpr*param.GBRatio*param.TwTrans2Roll;
        real_type temp46=-qd[1]*param.DTTorDmp*param.GBRatio*param.TwTrans2Roll;
        real_type temp47=pow(q[0],2.0);
        real_type temp48=-param.NacCMxn*param.NacCMyn*param.NacMass*param.tower_frame_11_psi0_1_2*param.tower_frame_11_psi0_2_1;
        real_type temp49=param.tower_frame_11_psi0_2_1*temp29+param.tower_frame_11_origin1_1_1_1*temp27;
        real_type temp50=param.tower_frame_11_psi0_2_1*temp32+param.tower_frame_11_origin1_1_1_1*temp30;
        real_type temp51=-3.0*param.blade_I0_2_2;
        real_type temp52=temp12*(temp9+temp51);
        real_type temp53=param.tower_frame_11_psi0_1_2*temp28;
        real_type temp54=param.tower_frame_11_psi0_1_2*temp31;
        real_type temp55=temp52+temp10+param.HubIner;
        real_type temp56=param.tower_frame_11_psi0_1_2*temp55;
        real_type temp57=param.GenIner*param.tower_frame_11_psi0_1_2;
        real_type temp58=-param.HubIner;
        real_type temp59=qd[4]*(temp58+temp51)+qd[4]*temp11*temp12;
        real_type temp60=-param.DTTorSpr*temp33;
        real_type temp61=-param.DTTorDmp*temp33;

        M(0, 0)=0.5*(param.tower_frame_11_origin1_1_1_1*param.tower_frame_11_psi0_2_1*temp5+temp3*temp4+temp14*temp15+2.0*param.tower_Me0_1_1);
        M(0, 1)=temp48;
        M(0, 2)=temp49;
        M(0, 3)=temp50;
        M(0, 4)=0.0;
        M(0, 5)=0.0;
        M(1, 0)=temp48;
        M(1, 1)=temp24*(3.0*param.blade_mass*temp8+param.HubMass*temp8+param.NacMass*(temp6+temp23)+temp52+temp10+param.NacXIner+param.HubIner+param.GenIner)+(3.0*param.blade_mass+param.NacMass+param.HubMass)*temp19+(-6.0*param.Twr2Shft*param.blade_mass-2.0*param.HubMass*param.Twr2Shft-2.0*param.NacCMzn*param.NacMass)*param.tower_frame_11_origin1_2_2_1*param.tower_frame_11_psi0_1_2+param.tower_Me0_2_2;
        M(1, 2)=temp53;
        M(1, 3)=temp54;
        M(1, 4)=temp56;
        M(1, 5)=temp57;
        M(2, 0)=temp49;
        M(2, 1)=temp53;
        M(2, 2)=3.0*param.blade_Me0_1_1;
        M(2, 3)=3.0*param.blade_Me0_1_2;
        M(2, 4)=temp28;
        M(2, 5)=0.0;
        M(3, 0)=temp50;
        M(3, 1)=temp54;
        M(3, 2)=3.0*param.blade_Me0_2_1;
        M(3, 3)=3.0*param.blade_Me0_2_2;
        M(3, 4)=temp31;
        M(3, 5)=0.0;
        M(4, 0)=0.0;
        M(4, 1)=temp56;
        M(4, 2)=temp28;
        M(4, 3)=temp31;
        M(4, 4)=temp15*temp47*temp55+temp52+temp10+param.HubIner;
        M(4, 5)=0.0;
        M(5, 0)=0.0;
        M(5, 1)=temp57;
        M(5, 2)=0.0;
        M(5, 3)=0.0;
        M(5, 4)=0.0;
        M(5, 5)=param.GenIner*temp15*temp47+param.GenIner;

        C(0, 0)=-q[0]*dFthrust_dtow_fa_d*param.OverHang*temp15-dFthrust_dtow_fa_d*param.Twr2Shft*param.tower_frame_11_psi0_2_1-dFthrust_dtow_fa_d*param.tower_frame_11_origin1_1_1_1+param.tower_D0_1_1;
        C(0, 1)=0.0;
        C(0, 2)=-q[0]*dFthrust_dbld_flp_d*param.OverHang*temp15-dFthrust_dbld_flp_d*param.Twr2Shft*param.tower_frame_11_psi0_2_1-dFthrust_dbld_flp_d*param.tower_frame_11_origin1_1_1_1;
        C(0, 3)=-q[0]*dFthrust_dbld_edg_d*param.OverHang*temp15-dFthrust_dbld_edg_d*param.Twr2Shft*param.tower_frame_11_psi0_2_1-dFthrust_dbld_edg_d*param.tower_frame_11_origin1_1_1_1;
        C(0, 4)=-q[0]*dFthrust_dphi_rot_d*param.OverHang*temp15-dFthrust_dphi_rot_d*param.Twr2Shft*param.tower_frame_11_psi0_2_1-dFthrust_dphi_rot_d*param.tower_frame_11_origin1_1_1_1;
        C(0, 5)=0.0;
        C(1, 0)=-dTrot_dtow_fa_d*param.tower_frame_11_psi0_1_2;
        C(1, 1)=((-param.DTTorDmp*param.TwTrans2Roll+dFtow_y_dtow_ss_d*param.GBRatio*param.NacCMzn)*param.tower_frame_11_psi0_1_2-dFtow_y_dtow_ss_d*param.GBRatio*param.tower_frame_11_origin1_2_2_1+param.GBRatio*param.tower_D0_2_2)*temp33;
        C(1, 2)=-dTrot_dbld_flp_d*param.tower_frame_11_psi0_1_2;
        C(1, 3)=-dTrot_dbld_edg_d*param.tower_frame_11_psi0_1_2;
        C(1, 4)=-(dTrot_dphi_rot_d*param.GBRatio+param.DTTorDmp)*param.tower_frame_11_psi0_1_2*temp33;
        C(1, 5)=param.DTTorDmp*param.tower_frame_11_psi0_1_2*temp17;
        C(2, 0)=-3.0*dmodalFlapForce_dtow_fa_d;
        C(2, 1)=0.0;
        C(2, 2)=3.0*param.blade_D0_1_1-3.0*dmodalFlapForce_dbld_flp_d;
        C(2, 3)=-3.0*dmodalFlapForce_dbld_edg_d;
        C(2, 4)=-qd[4]*(-6.0*q[3]*param.blade_Oe1_2_1_2-6.0*q[2]*param.blade_Oe1_1_1_2)*temp26-qd[4]*(6.0*q[3]*param.blade_Oe1_2_1_4+6.0*q[2]*param.blade_Oe1_1_1_4)*temp1*temp2-qd[4]*(-6.0*q[3]*param.blade_Oe1_2_1_1-6.0*q[2]*param.blade_Oe1_1_1_1)*temp12-3.0*dmodalFlapForce_dphi_rot_d;
        C(2, 5)=0.0;
        C(3, 0)=-3.0*dmodalEdgeForce_dtow_fa_d;
        C(3, 1)=0.0;
        C(3, 2)=-3.0*dmodalEdgeForce_dbld_flp_d;
        C(3, 3)=3.0*param.blade_D0_2_2-3.0*dmodalEdgeForce_dbld_edg_d;
        C(3, 4)=-qd[4]*(-6.0*q[3]*param.blade_Oe1_2_2_2-6.0*q[2]*param.blade_Oe1_1_2_2)*temp26-qd[4]*(6.0*q[3]*param.blade_Oe1_2_2_4+6.0*q[2]*param.blade_Oe1_1_2_4)*temp1*temp2-qd[4]*(-6.0*q[3]*param.blade_Oe1_2_2_1-6.0*q[2]*param.blade_Oe1_1_2_1)*temp12-3.0*dmodalEdgeForce_dphi_rot_d;
        C(3, 5)=0.0;
        C(4, 0)=-temp15*(q[0]*temp59+dTrot_dtow_fa_d*temp47)-dTrot_dtow_fa_d;
        C(4, 1)=param.DTTorDmp*param.TwTrans2Roll;
        C(4, 2)=-dTrot_dbld_flp_d*temp15*temp47-dTrot_dbld_flp_d;
        C(4, 3)=-dTrot_dbld_edg_d*temp15*temp47-dTrot_dbld_edg_d;
        C(4, 4)=-temp15*(q[0]*qd[0]*(temp58+temp51+temp13)+dTrot_dphi_rot_d*temp47)+param.DTTorDmp-dTrot_dphi_rot_d;
        C(4, 5)=temp61;
        C(5, 0)=q[0]*qd[5]*param.GenIner*temp15;
        C(5, 1)=-param.DTTorDmp*param.TwTrans2Roll*temp33;
        C(5, 2)=0.0;
        C(5, 3)=0.0;
        C(5, 4)=temp61;
        C(5, 5)=(q[0]*qd[0]*param.GenIner*temp15*temp16+param.DTTorDmp)*temp17;

        K(0, 0)=-Fthrust*param.OverHang*temp15-(-3.0*param.blade_mass-param.NacMass-param.HubMass)*param.g*param.tower_frame_11_phi1_1_3_1+param.tower_K0_1_1+param.g*param.tower_Ct1_1_1_3;
        K(0, 1)=0.0;
        K(0, 2)=-param.tower_frame_11_psi0_2_1*(-3.0*param.blade_md1_1_2_1*param.g*temp2+3.0*param.blade_md1_1_1_1*param.g*temp1);
        K(0, 3)=-param.tower_frame_11_psi0_2_1*(-3.0*param.blade_md1_2_2_1*param.g*temp2+3.0*param.blade_md1_2_1_1*param.g*temp1);
        K(0, 4)=0.0;
        K(0, 5)=0.0;
        K(1, 0)=0.0;
        K(1, 1)=-(param.DTTorSpr*param.TwTrans2Roll*param.tower_frame_11_psi0_1_2+(-3.0*param.GBRatio*param.blade_mass-param.GBRatio*param.NacMass-param.GBRatio*param.HubMass)*param.g*param.tower_frame_11_phi1_2_3_2-param.GBRatio*param.tower_K0_2_2-param.GBRatio*param.g*param.tower_Ct1_2_2_3)*temp33;
        K(1, 2)=0.0;
        K(1, 3)=0.0;
        K(1, 4)=-param.DTTorSpr*param.tower_frame_11_psi0_1_2*temp33;
        K(1, 5)=param.DTTorSpr*param.tower_frame_11_psi0_1_2*temp17;
        K(2, 0)=-param.tower_frame_11_psi0_2_1*(-3.0*param.blade_Ct0_1_2*param.g*temp2+3.0*param.blade_Ct0_1_1*param.g*temp1);
        K(2, 1)=0.0;
        K(2, 2)=3.0*param.blade_Oe1_1_1_2*temp25*temp26-3.0*param.blade_Oe1_1_1_4*temp1*temp2*temp25+3.0*param.blade_Oe1_1_1_1*temp12*temp25+3.0*param.blade_K0_1_1;
        K(2, 3)=3.0*param.blade_Oe1_2_1_2*temp25*temp26-3.0*param.blade_Oe1_2_1_4*temp1*temp2*temp25+3.0*param.blade_Oe1_2_1_1*temp12*temp25+3.0*param.blade_K0_1_2;
        K(2, 4)=0.0;
        K(2, 5)=0.0;
        K(3, 0)=-param.tower_frame_11_psi0_2_1*(-3.0*param.blade_Ct0_2_2*param.g*temp2+3.0*param.blade_Ct0_2_1*param.g*temp1);
        K(3, 1)=0.0;
        K(3, 2)=3.0*param.blade_Oe1_1_2_2*temp25*temp26-3.0*param.blade_Oe1_1_2_4*temp1*temp2*temp25+3.0*param.blade_Oe1_1_2_1*temp12*temp25+3.0*param.blade_K0_2_1;
        K(3, 3)=3.0*param.blade_Oe1_2_2_2*temp25*temp26-3.0*param.blade_Oe1_2_2_4*temp1*temp2*temp25+3.0*param.blade_Oe1_2_2_1*temp12*temp25+3.0*param.blade_K0_2_2;
        K(3, 4)=0.0;
        K(3, 5)=0.0;
        K(4, 0)=-temp15*(qd[0]*temp59+q[0]*(qdd[4]*(6.0*param.blade_I0_2_2-6.0*param.blade_I0_1_1)*temp12+qdd[4]*(-6.0*param.blade_I0_2_2-2.0*param.HubIner)+2.0*Trot));
        K(4, 1)=param.DTTorSpr*param.TwTrans2Roll;
        K(4, 2)=0.0;
        K(4, 3)=0.0;
        K(4, 4)=param.DTTorSpr;
        K(4, 5)=temp60;
        K(5, 0)=-(-2.0*q[0]*qdd[5]*param.GenIner-qd[0]*qd[5]*param.GenIner)*temp15;
        K(5, 1)=-param.DTTorSpr*param.TwTrans2Roll*temp33;
        K(5, 2)=0.0;
        K(5, 3)=0.0;
        K(5, 4)=temp60;
        K(5, 5)=param.DTTorSpr*temp17;

        f[0]=0.5*(param.tower_frame_11_psi0_2_1*(qdd[0]*param.tower_frame_11_origin1_1_1_1*temp5+((6.0*q[3]*param.blade_md1_2_2_1+6.0*q[2]*param.blade_md1_1_2_1)*param.g-6.0*qdd[3]*param.Twr2Shft*param.blade_Ct0_2_2-6.0*qdd[2]*param.Twr2Shft*param.blade_Ct0_1_2)*temp2+((-6.0*q[3]*param.blade_md1_2_1_1-6.0*q[2]*param.blade_md1_1_1_1)*param.g+6.0*qdd[3]*param.Twr2Shft*param.blade_Ct0_2_1+6.0*qdd[2]*param.Twr2Shft*param.blade_Ct0_1_1)*temp1-2.0*qdd[1]*param.NacCMxn*param.NacCMyn*param.NacMass*param.tower_frame_11_psi0_1_2+(-6.0*param.OverHang*param.blade_mass-2.0*param.HubMass*param.OverHang-2.0*param.NacCMxn*param.NacMass-2.0*param.HubCM*param.HubMass)*param.g-2.0*Fthrust*param.Twr2Shft)+qdd[0]*temp3*temp4+q[0]*param.g*param.tower_frame_11_phi1_1_3_1*temp3+param.tower_frame_11_origin1_1_1_1*((-6.0*qdd[3]*param.blade_Ct0_2_2-6.0*qdd[2]*param.blade_Ct0_1_2)*temp2+(6.0*qdd[3]*param.blade_Ct0_2_1+6.0*qdd[2]*param.blade_Ct0_1_1)*temp1-2.0*Fthrust)+(qdd[0]*temp14-2.0*q[0]*Fthrust*
         param.OverHang)*temp15+2.0*qdd[0]*param.tower_Me0_1_1+2.0*q[0]*param.tower_K0_1_1+2.0*qd[0]*param.tower_D0_1_1+2.0*q[0]*param.g*param.tower_Ct1_1_1_3);
        f[1]=-temp17*(qdd[1]*temp24*(-3.0*param.blade_mass*temp16*temp8-param.HubMass*temp16*temp8+param.NacMass*(-temp16*temp6-temp16*temp23)+temp12*temp22+temp21+temp20-param.NacXIner*temp16-param.GenIner*temp16)+param.tower_frame_11_psi0_1_2*(qdd[4]*temp12*temp22+qdd[4]*(temp21+temp20)+(3.0*qdd[3]*param.blade_Cr0_2_2*temp16+3.0*qdd[2]*param.blade_Cr0_1_2*temp16)*temp2+qdd[1]*param.tower_frame_11_origin1_2_2_1*(6.0*param.Twr2Shft*param.blade_mass*temp16+2.0*param.HubMass*param.Twr2Shft*temp16+2.0*param.NacCMzn*param.NacMass*temp16)+temp1*(-3.0*qdd[3]*param.blade_Cr0_2_1*temp16-3.0*qdd[2]*param.blade_Cr0_1_1*temp16)-param.NacCMyn*param.NacMass*param.g*temp16-Ftow_y*param.NacCMzn*temp16-qdd[5]*param.GenIner*temp16+Trot*temp16-u[1]*temp16+q[1]*param.DTTorSpr*param.GBRatio*param.TwTrans2Roll+qd[1]*param.DTTorDmp*param.GBRatio*param.TwTrans2Roll+q[4]*param.DTTorSpr*param.GBRatio+qd[4]*param.DTTorDmp*param.GBRatio-q[5]*param.DTTorSpr-qd[5]*param.DTTorDmp)+qdd[1]*temp18*temp19+q[1]*param.g*
         param.tower_frame_11_phi1_2_3_2*temp18+qdd[0]*param.NacCMxn*param.NacCMyn*param.NacMass*param.tower_frame_11_psi0_1_2*param.tower_frame_11_psi0_2_1*temp16+Ftow_y*param.tower_frame_11_origin1_2_2_1*temp16-qdd[1]*param.tower_Me0_2_2*temp16-q[1]*param.tower_K0_2_2*temp16-qd[1]*param.tower_D0_2_2*temp16-q[1]*param.g*param.tower_Ct1_2_2_3*temp16);
        f[2]=param.tower_frame_11_psi0_2_1*(qdd[0]*temp29+q[0]*(3.0*param.blade_Ct0_1_2*param.g*temp2-3.0*param.blade_Ct0_1_1*param.g*temp1))+qdd[1]*param.tower_frame_11_psi0_1_2*temp28+qdd[0]*param.tower_frame_11_origin1_1_1_1*temp27+(3.0*q[3]*param.blade_Oe1_2_1_2+3.0*q[2]*param.blade_Oe1_1_1_2)*temp25*temp26+temp2*((-3.0*q[3]*param.blade_Oe1_2_1_4-3.0*q[2]*param.blade_Oe1_1_1_4)*temp1*temp25-3.0*qdd[4]*param.blade_Cr0_1_2)+(3.0*q[3]*param.blade_Oe1_2_1_1+3.0*q[2]*param.blade_Oe1_1_1_1)*temp12*temp25+3.0*qdd[4]*param.blade_Cr0_1_1*temp1+3.0*qdd[3]*param.blade_Me0_1_2+3.0*qdd[2]*param.blade_Me0_1_1+3.0*q[3]*param.blade_K0_1_2+3.0*q[2]*param.blade_K0_1_1+3.0*qd[2]*param.blade_D0_1_1-3.0*modalFlapForce;
        f[3]=param.tower_frame_11_psi0_2_1*(qdd[0]*temp32+q[0]*(3.0*param.blade_Ct0_2_2*param.g*temp2-3.0*param.blade_Ct0_2_1*param.g*temp1))+qdd[1]*param.tower_frame_11_psi0_1_2*temp31+qdd[0]*param.tower_frame_11_origin1_1_1_1*temp30+(3.0*q[3]*param.blade_Oe1_2_2_2+3.0*q[2]*param.blade_Oe1_1_2_2)*temp25*temp26+temp2*((-3.0*q[3]*param.blade_Oe1_2_2_4-3.0*q[2]*param.blade_Oe1_1_2_4)*temp1*temp25-3.0*qdd[4]*param.blade_Cr0_2_2)+(3.0*q[3]*param.blade_Oe1_2_2_1+3.0*q[2]*param.blade_Oe1_1_2_1)*temp12*temp25+3.0*qdd[4]*param.blade_Cr0_2_1*temp1+3.0*qdd[3]*param.blade_Me0_2_2+3.0*qdd[2]*param.blade_Me0_2_1+3.0*q[3]*param.blade_K0_2_2+3.0*q[2]*param.blade_K0_2_1+3.0*qd[3]*param.blade_D0_2_2-3.0*modalEdgeForce;
        f[4]=-temp33*(temp15*((temp44+temp42+temp34)*temp47+q[0]*qd[0]*(qd[4]*temp12*temp43+qd[4]*temp41))+temp46+temp45+temp44+qdd[1]*param.tower_frame_11_psi0_1_2*(temp12*temp43+temp40+temp39)+temp42+temp38+temp37+temp36+temp35+temp34+(3.0*qdd[3]*param.GBRatio*param.blade_Cr0_2_2+3.0*qdd[2]*param.GBRatio*param.blade_Cr0_1_2)*temp2+(-3.0*qdd[3]*param.GBRatio*param.blade_Cr0_2_1-3.0*qdd[2]*param.GBRatio*param.blade_Cr0_1_1)*temp1);
        f[5]=temp17*(temp15*(qdd[5]*param.GenIner*temp16*temp47+q[0]*qd[0]*qd[5]*param.GenIner*temp16)+temp46+temp45+temp38+temp37+temp36+temp35+qdd[1]*param.GenIner*param.tower_frame_11_psi0_1_2*temp16+qdd[5]*param.GenIner*temp16+u[1]*temp16);

    }
    
    Jacobian= alphaM*M + alphaC*C + alphaK*K;

    for(int idof= 0; idof < nbrdof; idof++) {
        if(doflocked[idof]) {
            f[idof]= 0.0;
            Jacobian.col(idof).setZero();
        }
    }
}

void T2B2cG::calcB() {
    {
        real_type temp2=pow(param.tower_frame_11_psi0_2_1,2.0);
        real_type temp3=cos(u[2]);
        real_type temp4=sin(u[2]);
        real_type temp5=3.0*qdd[3]*param.blade_Cr0_2_2+3.0*qdd[2]*param.blade_Cr0_1_2;
        real_type temp6=-6.0*param.blade_I0_2_2+6.0*param.blade_I0_1_1;
        real_type temp7=qdd[4]*temp3*temp6+3.0*qdd[3]*param.blade_Cr0_2_1+3.0*qdd[2]*param.blade_Cr0_1_1;
        real_type temp8=pow(qd[4],2.0);
        real_type temp9=pow(temp3,2.0);
        real_type temp10=pow(temp4,2.0);
        real_type temp11=pow(q[0],2.0);

        B(0, 0)=-q[0]*dFthrust_dvwind*param.OverHang*temp2-dFthrust_dvwind*param.Twr2Shft*param.tower_frame_11_psi0_2_1-dFthrust_dvwind*param.tower_frame_11_origin1_1_1_1;
        B(0, 1)=0.0;
        B(0, 2)=-temp2*(qdd[0]*(3.0*param.blade_I0_2_2-3.0*param.blade_I0_1_1)*temp3*temp4+q[0]*dFthrust_dtheta*param.OverHang)-param.tower_frame_11_psi0_2_1*(((-3.0*q[3]*param.blade_md1_2_1_1-3.0*q[2]*param.blade_md1_1_1_1)*param.g+3.0*qdd[3]*param.Twr2Shft*param.blade_Ct0_2_1+3.0*qdd[2]*param.Twr2Shft*param.blade_Ct0_1_1)*temp4+((-3.0*q[3]*param.blade_md1_2_2_1-3.0*q[2]*param.blade_md1_1_2_1)*param.g+3.0*qdd[3]*param.Twr2Shft*param.blade_Ct0_2_2+3.0*qdd[2]*param.Twr2Shft*param.blade_Ct0_1_2)*temp3+dFthrust_dtheta*param.Twr2Shft)-param.tower_frame_11_origin1_1_1_1*((3.0*qdd[3]*param.blade_Ct0_2_1+3.0*qdd[2]*param.blade_Ct0_1_1)*temp4+(3.0*qdd[3]*param.blade_Ct0_2_2+3.0*qdd[2]*param.blade_Ct0_1_2)*temp3+dFthrust_dtheta);
        B(1, 0)=-dTrot_dvwind*param.tower_frame_11_psi0_1_2;
        B(1, 1)=param.tower_frame_11_psi0_1_2;
        B(1, 2)=-param.tower_frame_11_psi0_1_2*(temp4*temp7+temp3*temp5+dTrot_dtheta)-qdd[1]*pow(param.tower_frame_11_psi0_1_2,2.0)*temp3*temp4*temp6;
        B(2, 0)=-3.0*dmodalFlapForce_dvwind;
        B(2, 1)=0.0;
        B(2, 2)=-(3.0*q[3]*param.blade_Oe1_2_1_4+3.0*q[2]*param.blade_Oe1_1_1_4)*temp8*temp9-temp4*((q[3]*(-6.0*param.blade_Oe1_2_1_2+6.0*param.blade_Oe1_2_1_1)+q[2]*(-6.0*param.blade_Oe1_1_1_2+6.0*param.blade_Oe1_1_1_1))*temp3*temp8+3.0*qdd[4]*param.blade_Cr0_1_1)-(-3.0*q[3]*param.blade_Oe1_2_1_4-3.0*q[2]*param.blade_Oe1_1_1_4)*temp10*temp8-param.tower_frame_11_psi0_2_1*(q[0]*(-3.0*param.blade_Ct0_1_1*param.g*temp4-3.0*param.blade_Ct0_1_2*param.g*temp3)+qdd[0]*(3.0*param.Twr2Shft*param.blade_Ct0_1_1*temp4+3.0*param.Twr2Shft*param.blade_Ct0_1_2*temp3))-qdd[0]*param.tower_frame_11_origin1_1_1_1*(3.0*param.blade_Ct0_1_1*temp4+3.0*param.blade_Ct0_1_2*temp3)-qdd[1]*param.tower_frame_11_psi0_1_2*(3.0*param.blade_Cr0_1_1*temp4+3.0*param.blade_Cr0_1_2*temp3)-3.0*qdd[4]*param.blade_Cr0_1_2*temp3-3.0*dmodalFlapForce_dtheta;
        B(3, 0)=-3.0*dmodalEdgeForce_dvwind;
        B(3, 1)=0.0;
        B(3, 2)=-(3.0*q[3]*param.blade_Oe1_2_2_4+3.0*q[2]*param.blade_Oe1_1_2_4)*temp8*temp9-temp4*((q[3]*(-6.0*param.blade_Oe1_2_2_2+6.0*param.blade_Oe1_2_2_1)+q[2]*(-6.0*param.blade_Oe1_1_2_2+6.0*param.blade_Oe1_1_2_1))*temp3*temp8+3.0*qdd[4]*param.blade_Cr0_2_1)-(-3.0*q[3]*param.blade_Oe1_2_2_4-3.0*q[2]*param.blade_Oe1_1_2_4)*temp10*temp8-param.tower_frame_11_psi0_2_1*(q[0]*(-3.0*param.blade_Ct0_2_1*param.g*temp4-3.0*param.blade_Ct0_2_2*param.g*temp3)+qdd[0]*(3.0*param.Twr2Shft*param.blade_Ct0_2_1*temp4+3.0*param.Twr2Shft*param.blade_Ct0_2_2*temp3))-qdd[0]*param.tower_frame_11_origin1_1_1_1*(3.0*param.blade_Ct0_2_1*temp4+3.0*param.blade_Ct0_2_2*temp3)-qdd[1]*param.tower_frame_11_psi0_1_2*(3.0*param.blade_Cr0_2_1*temp4+3.0*param.blade_Cr0_2_2*temp3)-3.0*qdd[4]*param.blade_Cr0_2_2*temp3-3.0*dmodalEdgeForce_dtheta;
        B(4, 0)=-dTrot_dvwind*temp11*temp2-dTrot_dvwind;
        B(4, 1)=0.0;
        B(4, 2)=-temp4*temp7-temp2*(temp11*(qdd[4]*temp3*temp4*temp6+dTrot_dtheta)+q[0]*qd[0]*qd[4]*temp3*temp4*temp6)-qdd[1]*param.tower_frame_11_psi0_1_2*temp3*temp4*temp6-temp3*temp5-dTrot_dtheta;
        B(5, 0)=0.0;
        B(5, 1)=1.0;
        B(5, 2)=0.0;

    }
}

void T2B2cG::calcCDF() {
    {
        real_type temp1=q[3]*param.blade_frame_30_origin0_3_1*param.blade_frame_30_psi0_2_2+q[2]*param.blade_frame_30_origin0_3_1*param.blade_frame_30_psi0_2_1;
        real_type temp2=cos(param.cone);
        real_type temp3=pow(qd[4],2.0);
        real_type temp4=sin(param.cone);
        real_type temp5=cos(u[2]);
        real_type temp6=qdd[3]*param.blade_frame_30_origin1_2_1_1;
        real_type temp7=qdd[2]*param.blade_frame_30_origin1_1_1_1;
        real_type temp8=-2.0*qd[3]*param.blade_frame_30_origin1_2_2_1-2.0*qd[2]*param.blade_frame_30_origin1_1_2_1;
        real_type temp9=-q[3]*param.blade_frame_30_origin1_2_2_1-q[2]*param.blade_frame_30_origin1_1_2_1;
        real_type temp10=qdd[4]*temp4*temp9+qd[4]*temp4*temp8+temp2*(temp7+temp6);
        real_type temp11=pow(temp5,2.0);
        real_type temp12=qdd[3]*param.blade_frame_30_origin1_2_2_1;
        real_type temp13=qdd[2]*param.blade_frame_30_origin1_1_2_1;
        real_type temp14=-2.0*qd[3]*param.blade_frame_30_origin1_2_1_1-2.0*qd[2]*param.blade_frame_30_origin1_1_1_1;
        real_type temp15=temp3*temp9;
        real_type temp16=-q[3]*param.blade_frame_30_origin1_2_1_1-q[2]*param.blade_frame_30_origin1_1_1_1;
        real_type temp17=qdd[4]*temp16*temp4+qd[4]*temp14*temp4+(-qdd[3]*param.blade_frame_30_origin1_2_2_1-qdd[2]*param.blade_frame_30_origin1_1_2_1)*temp2+temp15+temp13+temp12;
        real_type temp18=temp17*temp5-qdd[4]*param.blade_frame_30_origin0_3_1;
        real_type temp19=sin(u[2]);
        real_type temp20=temp16*temp3;
        real_type temp21=temp7+temp6+temp20;
        real_type temp22=pow(temp19,2.0);
        real_type temp23=sin(q[4]);
        real_type temp24=cos(q[4]);
        real_type temp25=temp23*temp4*temp5+temp19*temp24;
        real_type temp26=-param.blade_frame_30_origin0_3_1;
        real_type temp27=temp26-param.Twr2Shft*temp24;
        real_type temp28=-param.Twr2Shft*temp23*temp4*temp5+temp19*temp27;
        real_type temp29=param.OverHang*temp4+param.blade_frame_30_origin0_3_1*temp2;
        real_type temp30=temp24*temp29+param.Twr2Shft*temp2;
        real_type temp31=temp30*temp5-param.OverHang*temp19*temp23;
        real_type temp32=-q[3]*param.blade_frame_30_origin0_3_1*param.blade_frame_30_psi0_1_2-q[2]*param.blade_frame_30_origin0_3_1*param.blade_frame_30_psi0_1_1;
        real_type temp33=temp15+temp13+temp12;
        real_type temp34=2.0*qd[3]*param.blade_frame_30_origin1_2_2_1+2.0*qd[2]*param.blade_frame_30_origin1_1_2_1;
        real_type temp35=q[3]*param.blade_frame_30_origin1_2_2_1+q[2]*param.blade_frame_30_origin1_1_2_1;
        real_type temp36=temp7+temp6+qdd[4]*temp35*temp4+qd[4]*temp34*temp4+temp20+(-qdd[3]*param.blade_frame_30_origin1_2_1_1-qdd[2]*param.blade_frame_30_origin1_1_1_1)*temp2;
        real_type temp37=temp36*temp5-param.blade_frame_30_origin0_3_1*temp3*temp4;
        real_type temp38=2.0*qd[3]*param.blade_frame_30_origin1_2_1_1+2.0*qd[2]*param.blade_frame_30_origin1_1_1_1;
        real_type temp39=q[3]*param.blade_frame_30_origin1_2_1_1+q[2]*param.blade_frame_30_origin1_1_1_1;
        real_type temp40=qdd[4]*temp39*temp4+qd[4]*temp38*temp4+(temp13+temp12)*temp2;
        real_type temp41=temp24*temp5-temp19*temp23*temp4;
        real_type temp42=temp27*temp5+param.Twr2Shft*temp19*temp23*temp4;
        real_type temp43=qdd[1]*temp42-2.0*qd[1]*qd[4]*param.blade_frame_30_origin0_3_1*temp19*temp4;
        real_type temp44=2.0*qd[0]*qd[4]*param.blade_frame_30_origin0_3_1*temp19*temp2*temp23;
        real_type temp45=-param.OverHang*temp23*temp5;
        real_type temp46=-param.OverHang*temp4-param.blade_frame_30_origin0_3_1*temp2;
        real_type temp47=temp24*temp46-param.Twr2Shft*temp2;
        real_type temp48=temp19*temp47+temp45;
        real_type temp49=9.0*qdd[4]*param.blade_I0_1_1-3.0*Trot;
        real_type temp50=-9.0*MyD23;
        real_type temp51=-2.0*Fthrust*param.Rrot;
        real_type temp52=-9.0*q[3]*param.blade_I1_2_3_1-9.0*q[2]*param.blade_I1_1_3_1;
        real_type temp53=temp3*temp5*temp52+temp51+temp50;
        real_type temp54=9.0*q[3]*param.blade_I1_2_3_2+9.0*q[2]*param.blade_I1_1_3_2;
        real_type temp55=9.0*q[3]*param.blade_I1_2_3_1+9.0*q[2]*param.blade_I1_1_3_1;
        real_type temp56=-9.0*q[3]*param.blade_I1_2_3_2-9.0*q[2]*param.blade_I1_1_3_2;
        real_type temp57=qdd[4]*temp22*temp56+qdd[4]*temp19*temp5*temp55;
        real_type temp58=temp51+temp50;
        real_type temp59=temp3*temp5*temp54-9.0*qdd[4]*param.blade_I0_2_2+3.0*Trot;
        real_type temp60=qdd[4]*temp11*temp55;
        real_type temp61=temp60+qdd[4]*temp19*temp5*temp56;
        real_type temp62=-9.0*q[0]*param.blade_md0_3_1*param.g*temp5+9.0*qdd[0]*param.Twr2Shft*param.blade_md0_3_1*temp5;
        real_type temp64=-2.0*dFthrust_dphi_rot_d*param.Rrot;
        real_type temp65=-9.0*dMyD23_dphi_rot_d;
        real_type temp67=-2.0*dFthrust_dvwind*param.Rrot-9.0*dMyD23_dvwind;
        real_type temp68=-2.0*dFthrust_dtheta*param.Rrot;
        real_type temp69=-9.0*dMyD23_dtheta;

        y[0]=qdd[0];
        y[1]=qdd[1];
        y[2]=qd[5];
        y[3]=param.tower_frame_11_psi0_1_2*(2.0*qd[1]*qd[4]*param.blade_frame_30_origin0_3_1*temp4*temp5+qdd[1]*temp28)+param.tower_frame_11_psi0_2_1*(-2.0*qd[0]*qd[4]*param.blade_frame_30_origin0_3_1*temp2*temp23*temp5+qdd[0]*temp31)+param.blade_frame_30_origin0_3_1*temp3*temp4*temp5+qdd[0]*param.tower_frame_11_origin1_1_1_1*temp2*temp5+temp1*temp2*temp3+qdd[1]*param.tower_frame_11_origin1_2_2_1*temp25+temp21*temp22+temp18*temp19+temp10*temp11;
        y[4]=-qdd[4]*param.blade_frame_30_origin0_3_1*temp5+param.tower_frame_11_psi0_2_1*(qdd[0]*temp48+temp44)+param.tower_frame_11_psi0_1_2*temp43+qdd[1]*param.tower_frame_11_origin1_2_2_1*temp41+temp22*temp40+temp19*temp37+temp11*temp33+temp2*temp3*temp32-qdd[0]*param.tower_frame_11_origin1_1_1_1*temp19*temp2;
        y[5]=-0.1111111111111111*(param.tower_frame_11_psi0_1_2*(q[1]*temp57+9.0*qdd[1]*param.blade_I0_1_1*temp5)+temp22*temp3*temp54+temp19*temp53+temp49*temp5+param.tower_frame_11_psi0_2_1*(-9.0*q[0]*param.blade_md0_3_1*param.g*temp19+9.0*qdd[0]*param.Twr2Shft*param.blade_md0_3_1*temp19)+9.0*qdd[0]*param.blade_md0_3_1*param.tower_frame_11_origin1_1_1_1*temp19+9.0*qdd[3]*param.blade_Cr0_2_1+9.0*qdd[2]*param.blade_Cr0_1_1);
        y[6]=-0.1111111111111111*(param.tower_frame_11_psi0_2_1*temp62+param.tower_frame_11_psi0_1_2*(q[1]*temp61-9.0*qdd[1]*param.blade_I0_2_2*temp19)+temp19*temp59+temp5*temp58+temp11*temp3*temp52+9.0*qdd[0]*param.blade_md0_3_1*param.tower_frame_11_origin1_1_1_1*temp5+9.0*qdd[3]*param.blade_Cr0_2_2+9.0*qdd[2]*param.blade_Cr0_1_2);

        CD(0, 0)=0.0;
        CD(0, 1)=0.0;
        CD(0, 2)=0.0;
        CD(0, 3)=0.0;
        CD(0, 4)=0.0;
        CD(0, 5)=0.0;
        CD(0, 6)=0.0;
        CD(0, 7)=0.0;
        CD(0, 8)=0.0;
        CD(0, 9)=0.0;
        CD(0, 10)=0.0;
        CD(0, 11)=0.0;
        CD(1, 0)=0.0;
        CD(1, 1)=0.0;
        CD(1, 2)=0.0;
        CD(1, 3)=0.0;
        CD(1, 4)=0.0;
        CD(1, 5)=0.0;
        CD(1, 6)=0.0;
        CD(1, 7)=0.0;
        CD(1, 8)=0.0;
        CD(1, 9)=0.0;
        CD(1, 10)=0.0;
        CD(1, 11)=0.0;
        CD(2, 0)=0.0;
        CD(2, 1)=0.0;
        CD(2, 2)=0.0;
        CD(2, 3)=0.0;
        CD(2, 4)=0.0;
        CD(2, 5)=0.0;
        CD(2, 6)=0.0;
        CD(2, 7)=0.0;
        CD(2, 8)=0.0;
        CD(2, 9)=0.0;
        CD(2, 10)=0.0;
        CD(2, 11)=1.0;
        CD(3, 0)=0.0;
        CD(3, 1)=0.0;
        CD(3, 2)=temp19*(-qdd[4]*param.blade_frame_30_origin1_1_1_1*temp4-param.blade_frame_30_origin1_1_2_1*temp3)*temp5-qdd[4]*param.blade_frame_30_origin1_1_2_1*temp11*temp4-param.blade_frame_30_origin1_1_1_1*temp22*temp3+param.blade_frame_30_origin0_3_1*param.blade_frame_30_psi0_2_1*temp2*temp3;
        CD(3, 3)=temp19*(-qdd[4]*param.blade_frame_30_origin1_2_1_1*temp4-param.blade_frame_30_origin1_2_2_1*temp3)*temp5-qdd[4]*param.blade_frame_30_origin1_2_2_1*temp11*temp4-param.blade_frame_30_origin1_2_1_1*temp22*temp3+param.blade_frame_30_origin0_3_1*param.blade_frame_30_psi0_2_2*temp2*temp3;
        CD(3, 4)=param.tower_frame_11_psi0_2_1*(qdd[0]*(-temp23*temp29*temp5-param.OverHang*temp19*temp24)-2.0*qd[0]*qd[4]*param.blade_frame_30_origin0_3_1*temp2*temp24*temp5)+qdd[1]*param.tower_frame_11_psi0_1_2*(-param.Twr2Shft*temp24*temp4*temp5+param.Twr2Shft*temp19*temp23)+qdd[1]*param.tower_frame_11_origin1_2_2_1*(temp24*temp4*temp5-temp19*temp23);
        CD(3, 5)=0.0;
        CD(3, 6)=-2.0*qd[4]*param.blade_frame_30_origin0_3_1*param.tower_frame_11_psi0_2_1*temp2*temp23*temp5;
        CD(3, 7)=2.0*qd[4]*param.blade_frame_30_origin0_3_1*param.tower_frame_11_psi0_1_2*temp4*temp5;
        CD(3, 8)=-2.0*qd[4]*param.blade_frame_30_origin1_1_1_1*temp19*temp4*temp5-2.0*qd[4]*param.blade_frame_30_origin1_1_2_1*temp11*temp4;
        CD(3, 9)=-2.0*qd[4]*param.blade_frame_30_origin1_2_1_1*temp19*temp4*temp5-2.0*qd[4]*param.blade_frame_30_origin1_2_2_1*temp11*temp4;
        CD(3, 10)=temp19*temp5*(2.0*qd[4]*temp9+temp14*temp4)+temp11*temp4*temp8+2.0*qd[1]*param.blade_frame_30_origin0_3_1*param.tower_frame_11_psi0_1_2*temp4*temp5+2.0*qd[4]*param.blade_frame_30_origin0_3_1*temp4*temp5-2.0*qd[0]*param.blade_frame_30_origin0_3_1*param.tower_frame_11_psi0_2_1*temp2*temp23*temp5+2.0*qd[4]*temp16*temp22+2.0*qd[4]*temp1*temp2;
        CD(3, 11)=0.0;
        CD(4, 0)=0.0;
        CD(4, 1)=0.0;
        CD(4, 2)=temp19*(qdd[4]*param.blade_frame_30_origin1_1_2_1*temp4-param.blade_frame_30_origin1_1_1_1*temp3)*temp5+qdd[4]*param.blade_frame_30_origin1_1_1_1*temp22*temp4-param.blade_frame_30_origin0_3_1*param.blade_frame_30_psi0_1_1*temp2*temp3-param.blade_frame_30_origin1_1_2_1*temp11*temp3;
        CD(4, 3)=temp19*(qdd[4]*param.blade_frame_30_origin1_2_2_1*temp4-param.blade_frame_30_origin1_2_1_1*temp3)*temp5+qdd[4]*param.blade_frame_30_origin1_2_1_1*temp22*temp4-param.blade_frame_30_origin0_3_1*param.blade_frame_30_psi0_1_2*temp2*temp3-param.blade_frame_30_origin1_2_2_1*temp11*temp3;
        CD(4, 4)=param.tower_frame_11_psi0_2_1*(qdd[0]*(-param.OverHang*temp24*temp5-temp19*temp23*temp46)+2.0*qd[0]*qd[4]*param.blade_frame_30_origin0_3_1*temp19*temp2*temp24)+qdd[1]*param.tower_frame_11_psi0_1_2*(param.Twr2Shft*temp23*temp5+param.Twr2Shft*temp19*temp24*temp4)+qdd[1]*param.tower_frame_11_origin1_2_2_1*(-temp23*temp5-temp19*temp24*temp4);
        CD(4, 5)=0.0;
        CD(4, 6)=2.0*qd[4]*param.blade_frame_30_origin0_3_1*param.tower_frame_11_psi0_2_1*temp19*temp2*temp23;
        CD(4, 7)=-2.0*qd[4]*param.blade_frame_30_origin0_3_1*param.tower_frame_11_psi0_1_2*temp19*temp4;
        CD(4, 8)=2.0*qd[4]*param.blade_frame_30_origin1_1_2_1*temp19*temp4*temp5+2.0*qd[4]*param.blade_frame_30_origin1_1_1_1*temp22*temp4;
        CD(4, 9)=2.0*qd[4]*param.blade_frame_30_origin1_2_2_1*temp19*temp4*temp5+2.0*qd[4]*param.blade_frame_30_origin1_2_1_1*temp22*temp4;
        CD(4, 10)=2.0*qd[4]*temp11*temp9+temp19*((temp34*temp4+2.0*qd[4]*temp16)*temp5-2.0*qd[4]*param.blade_frame_30_origin0_3_1*temp4)+temp22*temp38*temp4-2.0*qd[1]*param.blade_frame_30_origin0_3_1*param.tower_frame_11_psi0_1_2*temp19*temp4+2.0*qd[4]*temp2*temp32+2.0*qd[0]*param.blade_frame_30_origin0_3_1*param.tower_frame_11_psi0_2_1*temp19*temp2*temp23;
        CD(4, 11)=0.0;
        CD(5, 0)=param.blade_md0_3_1*param.g*param.tower_frame_11_psi0_2_1*temp19;
        CD(5, 1)=-0.1111111111111111*param.tower_frame_11_psi0_1_2*temp57;
        CD(5, 2)=-0.1111111111111111*(q[1]*param.tower_frame_11_psi0_1_2*(9.0*qdd[4]*param.blade_I1_1_3_1*temp19*temp5-9.0*qdd[4]*param.blade_I1_1_3_2*temp22)-9.0*param.blade_I1_1_3_1*temp19*temp3*temp5+9.0*param.blade_I1_1_3_2*temp22*temp3);
        CD(5, 3)=-0.1111111111111111*(q[1]*param.tower_frame_11_psi0_1_2*(9.0*qdd[4]*param.blade_I1_2_3_1*temp19*temp5-9.0*qdd[4]*param.blade_I1_2_3_2*temp22)-9.0*param.blade_I1_2_3_1*temp19*temp3*temp5+9.0*param.blade_I1_2_3_2*temp22*temp3);
        CD(5, 4)=0.0;
        CD(5, 5)=0.0;
        CD(5, 6)=-0.1111111111111111*(-3.0*dTrot_dtow_fa_d*temp5-2.0*dFthrust_dtow_fa_d*param.Rrot*temp19);
        CD(5, 7)=0.0;
        CD(5, 8)=-0.1111111111111111*(-3.0*dTrot_dbld_flp_d*temp5-2.0*dFthrust_dbld_flp_d*param.Rrot*temp19);
        CD(5, 9)=-0.1111111111111111*(-3.0*dTrot_dbld_edg_d*temp5-2.0*dFthrust_dbld_edg_d*param.Rrot*temp19);
        CD(5, 10)=-0.1111111111111111*(temp19*(temp65+temp64+2.0*qd[4]*temp5*temp52)+2.0*qd[4]*temp22*temp54-3.0*dTrot_dphi_rot_d*temp5);
        CD(5, 11)=0.0;
        CD(6, 0)=param.blade_md0_3_1*param.g*param.tower_frame_11_psi0_2_1*temp5;
        CD(6, 1)=-0.1111111111111111*param.tower_frame_11_psi0_1_2*temp61;
        CD(6, 2)=-0.1111111111111111*(q[1]*param.tower_frame_11_psi0_1_2*(-9.0*qdd[4]*param.blade_I1_1_3_2*temp19*temp5+9.0*qdd[4]*param.blade_I1_1_3_1*temp11)+9.0*param.blade_I1_1_3_2*temp19*temp3*temp5-9.0*param.blade_I1_1_3_1*temp11*temp3);
        CD(6, 3)=-0.1111111111111111*(q[1]*param.tower_frame_11_psi0_1_2*(-9.0*qdd[4]*param.blade_I1_2_3_2*temp19*temp5+9.0*qdd[4]*param.blade_I1_2_3_1*temp11)+9.0*param.blade_I1_2_3_2*temp19*temp3*temp5-9.0*param.blade_I1_2_3_1*temp11*temp3);
        CD(6, 4)=0.0;
        CD(6, 5)=0.0;
        CD(6, 6)=-0.1111111111111111*(-2.0*dFthrust_dtow_fa_d*param.Rrot*temp5+3.0*dTrot_dtow_fa_d*temp19);
        CD(6, 7)=0.0;
        CD(6, 8)=-0.1111111111111111*(-2.0*dFthrust_dbld_flp_d*param.Rrot*temp5+3.0*dTrot_dbld_flp_d*temp19);
        CD(6, 9)=-0.1111111111111111*(-2.0*dFthrust_dbld_edg_d*param.Rrot*temp5+3.0*dTrot_dbld_edg_d*temp19);
        CD(6, 10)=-0.1111111111111111*(temp5*(temp65+temp64)+temp19*(2.0*qd[4]*temp5*temp54+3.0*dTrot_dphi_rot_d)+2.0*qd[4]*temp11*temp52);
        CD(6, 11)=0.0;

        CD.block(0, 2*nbrdof, nbrout, nbrin)(0, 0)=0.0;
        CD.block(0, 2*nbrdof, nbrout, nbrin)(0, 1)=0.0;
        CD.block(0, 2*nbrdof, nbrout, nbrin)(0, 2)=0.0;
        CD.block(0, 2*nbrdof, nbrout, nbrin)(1, 0)=0.0;
        CD.block(0, 2*nbrdof, nbrout, nbrin)(1, 1)=0.0;
        CD.block(0, 2*nbrdof, nbrout, nbrin)(1, 2)=0.0;
        CD.block(0, 2*nbrdof, nbrout, nbrin)(2, 0)=0.0;
        CD.block(0, 2*nbrdof, nbrout, nbrin)(2, 1)=0.0;
        CD.block(0, 2*nbrdof, nbrout, nbrin)(2, 2)=0.0;
        CD.block(0, 2*nbrdof, nbrout, nbrin)(3, 0)=0.0;
        CD.block(0, 2*nbrdof, nbrout, nbrin)(3, 1)=0.0;
        CD.block(0, 2*nbrdof, nbrout, nbrin)(3, 2)=2.0*temp19*temp21*temp5-2.0*temp10*temp19*temp5+temp18*temp5+param.tower_frame_11_psi0_2_1*(qdd[0]*(temp45-temp19*temp30)+temp44)+param.tower_frame_11_psi0_1_2*temp43+qdd[1]*param.tower_frame_11_origin1_2_2_1*temp41-param.blade_frame_30_origin0_3_1*temp19*temp3*temp4-temp17*temp22-qdd[0]*param.tower_frame_11_origin1_1_1_1*temp19*temp2;
        CD.block(0, 2*nbrdof, nbrout, nbrin)(4, 0)=0.0;
        CD.block(0, 2*nbrdof, nbrout, nbrin)(4, 1)=0.0;
        CD.block(0, 2*nbrdof, nbrout, nbrin)(4, 2)=param.tower_frame_11_psi0_2_1*(qdd[0]*(temp47*temp5+param.OverHang*temp19*temp23)+2.0*qd[0]*qd[4]*param.blade_frame_30_origin0_3_1*temp2*temp23*temp5)+param.tower_frame_11_psi0_1_2*(qdd[1]*(param.Twr2Shft*temp23*temp4*temp5-temp19*temp27)-2.0*qd[1]*qd[4]*param.blade_frame_30_origin0_3_1*temp4*temp5)+qdd[1]*param.tower_frame_11_origin1_2_2_1*(-temp23*temp4*temp5-temp19*temp24)+2.0*temp19*temp40*temp5+temp37*temp5-2.0*temp19*temp33*temp5-qdd[0]*param.tower_frame_11_origin1_1_1_1*temp2*temp5-temp22*temp36+qdd[4]*param.blade_frame_30_origin0_3_1*temp19;
        CD.block(0, 2*nbrdof, nbrout, nbrin)(5, 0)=-0.1111111111111111*(temp19*temp67-3.0*dTrot_dvwind*temp5);
        CD.block(0, 2*nbrdof, nbrout, nbrin)(5, 1)=0.0;
        CD.block(0, 2*nbrdof, nbrout, nbrin)(5, 2)=-0.1111111111111111*(temp19*(temp69+temp68-temp19*temp3*temp52)+param.tower_frame_11_psi0_2_1*temp62+param.tower_frame_11_psi0_1_2*(q[1]*(temp60+2.0*qdd[4]*temp19*temp5*temp56-qdd[4]*temp22*temp55)-9.0*qdd[1]*param.blade_I0_1_1*temp19)+2.0*temp19*temp3*temp5*temp54+temp5*temp53+9.0*qdd[0]*param.blade_md0_3_1*param.tower_frame_11_origin1_1_1_1*temp5-3.0*dTrot_dtheta*temp5-temp19*temp49);
        CD.block(0, 2*nbrdof, nbrout, nbrin)(6, 0)=-0.1111111111111111*(temp5*temp67+3.0*dTrot_dvwind*temp19);
        CD.block(0, 2*nbrdof, nbrout, nbrin)(6, 1)=0.0;
        CD.block(0, 2*nbrdof, nbrout, nbrin)(6, 2)=-0.1111111111111111*(temp5*(temp69+temp68)+temp5*temp59-temp19*temp58+param.tower_frame_11_psi0_1_2*(q[1]*(-qdd[4]*temp22*temp56+qdd[4]*temp11*temp56-2.0*qdd[4]*temp19*temp5*temp55)-9.0*qdd[1]*param.blade_I0_2_2*temp5)+temp19*(-temp19*temp3*temp54+3.0*dTrot_dtheta)-2.0*temp19*temp3*temp5*temp52+param.tower_frame_11_psi0_2_1*(9.0*q[0]*param.blade_md0_3_1*param.g*temp19-9.0*qdd[0]*param.Twr2Shft*param.blade_md0_3_1*temp19)-9.0*qdd[0]*param.blade_md0_3_1*param.tower_frame_11_origin1_1_1_1*temp19);

        F(0, 0)=1.0;
        F(0, 1)=0.0;
        F(0, 2)=0.0;
        F(0, 3)=0.0;
        F(0, 4)=0.0;
        F(0, 5)=0.0;
        F(1, 0)=0.0;
        F(1, 1)=1.0;
        F(1, 2)=0.0;
        F(1, 3)=0.0;
        F(1, 4)=0.0;
        F(1, 5)=0.0;
        F(2, 0)=0.0;
        F(2, 1)=0.0;
        F(2, 2)=0.0;
        F(2, 3)=0.0;
        F(2, 4)=0.0;
        F(2, 5)=0.0;
        F(3, 0)=param.tower_frame_11_origin1_1_1_1*temp2*temp5+param.tower_frame_11_psi0_2_1*temp31;
        F(3, 1)=param.tower_frame_11_psi0_1_2*temp28+param.tower_frame_11_origin1_2_2_1*temp25;
        F(3, 2)=temp19*(-param.blade_frame_30_origin1_1_2_1*temp2+param.blade_frame_30_origin1_1_2_1)*temp5+param.blade_frame_30_origin1_1_1_1*temp22+param.blade_frame_30_origin1_1_1_1*temp11*temp2;
        F(3, 3)=temp19*(-param.blade_frame_30_origin1_2_2_1*temp2+param.blade_frame_30_origin1_2_2_1)*temp5+param.blade_frame_30_origin1_2_1_1*temp22+param.blade_frame_30_origin1_2_1_1*temp11*temp2;
        F(3, 4)=temp11*temp4*temp9+temp19*(temp16*temp4*temp5+temp26);
        F(3, 5)=0.0;
        F(4, 0)=param.tower_frame_11_psi0_2_1*temp48-param.tower_frame_11_origin1_1_1_1*temp19*temp2;
        F(4, 1)=param.tower_frame_11_psi0_1_2*temp42+param.tower_frame_11_origin1_2_2_1*temp41;
        F(4, 2)=temp19*(-param.blade_frame_30_origin1_1_1_1*temp2+param.blade_frame_30_origin1_1_1_1)*temp5+param.blade_frame_30_origin1_1_2_1*temp2*temp22+param.blade_frame_30_origin1_1_2_1*temp11;
        F(4, 3)=temp19*(-param.blade_frame_30_origin1_2_1_1*temp2+param.blade_frame_30_origin1_2_1_1)*temp5+param.blade_frame_30_origin1_2_2_1*temp2*temp22+param.blade_frame_30_origin1_2_2_1*temp11;
        F(4, 4)=temp19*temp35*temp4*temp5-param.blade_frame_30_origin0_3_1*temp5+temp22*temp39*temp4;
        F(4, 5)=0.0;
        F(5, 0)=-0.1111111111111111*(9.0*param.Twr2Shft*param.blade_md0_3_1*param.tower_frame_11_psi0_2_1*temp19+9.0*param.blade_md0_3_1*param.tower_frame_11_origin1_1_1_1*temp19);
        F(5, 1)=-param.blade_I0_1_1*param.tower_frame_11_psi0_1_2*temp5;
        F(5, 2)=-param.blade_Cr0_1_1;
        F(5, 3)=-param.blade_Cr0_2_1;
        F(5, 4)=-0.1111111111111111*(q[1]*param.tower_frame_11_psi0_1_2*(temp22*temp56+temp19*temp5*temp55)+9.0*param.blade_I0_1_1*temp5);
        F(5, 5)=0.0;
        F(6, 0)=-0.1111111111111111*(9.0*param.Twr2Shft*param.blade_md0_3_1*param.tower_frame_11_psi0_2_1*temp5+9.0*param.blade_md0_3_1*param.tower_frame_11_origin1_1_1_1*temp5);
        F(6, 1)=param.blade_I0_2_2*param.tower_frame_11_psi0_1_2*temp19;
        F(6, 2)=-param.blade_Cr0_1_2;
        F(6, 3)=-param.blade_Cr0_2_2;
        F(6, 4)=-0.1111111111111111*(q[1]*param.tower_frame_11_psi0_1_2*(temp19*temp5*temp56+temp11*temp55)-9.0*param.blade_I0_2_2*temp19);
        F(6, 5)=0.0;

    }
}

void T2B2cG::calcOut() {
    {
        real_type temp1=cos(param.cone);
        real_type temp2=pow(qd[4],2.0);
        real_type temp3=sin(param.cone);
        real_type temp4=cos(u[2]);
        real_type temp5=qdd[3]*param.blade_frame_30_origin1_2_1_1;
        real_type temp6=qdd[2]*param.blade_frame_30_origin1_1_1_1;
        real_type temp7=-q[3]*param.blade_frame_30_origin1_2_2_1-q[2]*param.blade_frame_30_origin1_1_2_1;
        real_type temp8=pow(temp4,2.0);
        real_type temp9=qdd[3]*param.blade_frame_30_origin1_2_2_1;
        real_type temp10=qdd[2]*param.blade_frame_30_origin1_1_2_1;
        real_type temp11=temp2*temp7;
        real_type temp12=-q[3]*param.blade_frame_30_origin1_2_1_1-q[2]*param.blade_frame_30_origin1_1_1_1;
        real_type temp13=sin(u[2]);
        real_type temp14=temp12*temp2;
        real_type temp15=pow(temp13,2.0);
        real_type temp16=sin(q[4]);
        real_type temp17=cos(q[4]);
        real_type temp18=-param.Twr2Shft*temp17-param.blade_frame_30_origin0_3_1;
        real_type temp19=-9.0*MyD23;
        real_type temp20=-2.0*Fthrust*param.Rrot;
        real_type temp21=-9.0*q[3]*param.blade_I1_2_3_1-9.0*q[2]*param.blade_I1_1_3_1;
        real_type temp22=9.0*q[3]*param.blade_I1_2_3_2+9.0*q[2]*param.blade_I1_1_3_2;
        real_type temp23=9.0*q[3]*param.blade_I1_2_3_1+9.0*q[2]*param.blade_I1_1_3_1;
        real_type temp24=-9.0*q[3]*param.blade_I1_2_3_2-9.0*q[2]*param.blade_I1_1_3_2;
        y[0]=qdd[0];
        y[1]=qdd[1];
        y[2]=qd[5];
        y[3]=temp13*(temp4*(temp9+qdd[4]*temp12*temp3+qd[4]*(-2.0*qd[3]*param.blade_frame_30_origin1_2_1_1-2.0*qd[2]*param.blade_frame_30_origin1_1_1_1)*temp3+temp11+temp10+(-qdd[3]*param.blade_frame_30_origin1_2_2_1-qdd[2]*param.blade_frame_30_origin1_1_2_1)*temp1)-qdd[4]*param.blade_frame_30_origin0_3_1)+(qdd[4]*temp3*temp7+temp1*(temp6+temp5)+qd[4]*(-2.0*qd[3]*param.blade_frame_30_origin1_2_2_1-2.0*qd[2]*param.blade_frame_30_origin1_1_2_1)*temp3)*temp8+temp15*(temp6+temp5+temp14)+param.tower_frame_11_psi0_2_1*(qdd[0]*((temp17*(param.OverHang*temp3+param.blade_frame_30_origin0_3_1*temp1)+param.Twr2Shft*temp1)*temp4-param.OverHang*temp13*temp16)-2.0*qd[0]*qd[4]*param.blade_frame_30_origin0_3_1*temp1*temp16*temp4)+param.tower_frame_11_psi0_1_2*(qdd[1]*(-param.Twr2Shft*temp16*temp3*temp4+temp13*temp18)+2.0*qd[1]*qd[4]*param.blade_frame_30_origin0_3_1*temp3*temp4)+qdd[1]*param.tower_frame_11_origin1_2_2_1*(temp16*temp3*temp4+temp13*temp17)+param.blade_frame_30_origin0_3_1*temp2*temp3*
         temp4+qdd[0]*param.tower_frame_11_origin1_1_1_1*temp1*temp4+(q[3]*param.blade_frame_30_origin0_3_1*param.blade_frame_30_psi0_2_2+q[2]*param.blade_frame_30_origin0_3_1*param.blade_frame_30_psi0_2_1)*temp1*temp2;
        y[4]=temp15*(temp1*(temp9+temp10)+qd[4]*(2.0*qd[3]*param.blade_frame_30_origin1_2_1_1+2.0*qd[2]*param.blade_frame_30_origin1_1_1_1)*temp3+qdd[4]*(q[3]*param.blade_frame_30_origin1_2_1_1+q[2]*param.blade_frame_30_origin1_1_1_1)*temp3)+temp8*(temp9+temp11+temp10)+temp13*(temp4*(temp6+temp5+qd[4]*(2.0*qd[3]*param.blade_frame_30_origin1_2_2_1+2.0*qd[2]*param.blade_frame_30_origin1_1_2_1)*temp3+qdd[4]*(q[3]*param.blade_frame_30_origin1_2_2_1+q[2]*param.blade_frame_30_origin1_1_2_1)*temp3+temp14+(-qdd[3]*param.blade_frame_30_origin1_2_1_1-qdd[2]*param.blade_frame_30_origin1_1_1_1)*temp1)-param.blade_frame_30_origin0_3_1*temp2*temp3)+param.tower_frame_11_psi0_1_2*(qdd[1]*(temp18*temp4+param.Twr2Shft*temp13*temp16*temp3)-2.0*qd[1]*qd[4]*param.blade_frame_30_origin0_3_1*temp13*temp3)+param.tower_frame_11_psi0_2_1*(qdd[0]*(-param.OverHang*temp16*temp4+temp13*(temp17*(-param.OverHang*temp3-param.blade_frame_30_origin0_3_1*temp1)-param.Twr2Shft*temp1))+2.0*qd[0]*qd[4]*
         param.blade_frame_30_origin0_3_1*temp1*temp13*temp16)+qdd[1]*param.tower_frame_11_origin1_2_2_1*(temp17*temp4-temp13*temp16*temp3)-qdd[4]*param.blade_frame_30_origin0_3_1*temp4+(-q[3]*param.blade_frame_30_origin0_3_1*param.blade_frame_30_psi0_1_2-q[2]*param.blade_frame_30_origin0_3_1*param.blade_frame_30_psi0_1_1)*temp1*temp2-qdd[0]*param.tower_frame_11_origin1_1_1_1*temp1*temp13;
        y[5]=-0.1111111111111111*(param.tower_frame_11_psi0_1_2*(q[1]*(qdd[4]*temp13*temp23*temp4+qdd[4]*temp15*temp24)+9.0*qdd[1]*param.blade_I0_1_1*temp4)+temp13*(temp2*temp21*temp4+temp20+temp19)+(9.0*qdd[4]*param.blade_I0_1_1-3.0*Trot)*temp4+temp15*temp2*temp22+param.tower_frame_11_psi0_2_1*(-9.0*q[0]*param.blade_md0_3_1*param.g*temp13+9.0*qdd[0]*param.Twr2Shft*param.blade_md0_3_1*temp13)+9.0*qdd[0]*param.blade_md0_3_1*param.tower_frame_11_origin1_1_1_1*temp13+9.0*qdd[3]*param.blade_Cr0_2_1+9.0*qdd[2]*param.blade_Cr0_1_1);
        y[6]=-0.1111111111111111*(param.tower_frame_11_psi0_1_2*(q[1]*(qdd[4]*temp23*temp8+qdd[4]*temp13*temp24*temp4)-9.0*qdd[1]*param.blade_I0_2_2*temp13)+temp2*temp21*temp8+temp13*(temp2*temp22*temp4-9.0*qdd[4]*param.blade_I0_2_2+3.0*Trot)+param.tower_frame_11_psi0_2_1*(-9.0*q[0]*param.blade_md0_3_1*param.g*temp4+9.0*qdd[0]*param.Twr2Shft*param.blade_md0_3_1*temp4)+(temp20+temp19)*temp4+9.0*qdd[0]*param.blade_md0_3_1*param.tower_frame_11_origin1_1_1_1*temp4+9.0*qdd[3]*param.blade_Cr0_2_2+9.0*qdd[2]*param.blade_Cr0_1_2);

    }
}

#include "T2B2cG_Externals.hpp"

