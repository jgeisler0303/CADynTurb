static void calc_conv_poly(real_type lambdaMin, real_type lambdaMax, real_type lambdaStep, real_type thetaMin, real_type thetaMax, real_type thetaStep, real_type lam, real_type theta_deg, int &lambdaIdx, int &thetaIdx, real_type conv_poly[16]) {
    if(lam>lambdaMax*(1.0-std::numeric_limits<real_type>::epsilon())) lam= lambdaMax*(1.0-std::numeric_limits<real_type>::epsilon());
    if(lam<lambdaMin) lam= lambdaMin;
    if(theta_deg>thetaMax*(1.0-std::numeric_limits<real_type>::epsilon())) theta_deg= thetaMax*(1.0-std::numeric_limits<real_type>::epsilon());
    if(theta_deg<thetaMin) theta_deg= thetaMin;
    
    real_type lambdaScaled= (lam-lambdaMin)/lambdaStep;
    lambdaIdx= std::floor(lambdaScaled);
    real_type thetaScaled= (theta_deg-thetaMin)/thetaStep;
    thetaIdx= std::floor(thetaScaled);
    real_type lambdaFact= 1.0 - lambdaScaled + lambdaIdx;
    real_type thetaFact= 1.0 - thetaScaled + thetaIdx;

    lambdaIdx--;
    thetaIdx--;
    
    real_type t3 = pow(lambdaFact, 2);
    real_type t4 = pow(lambdaFact, 3);
    real_type t5 = pow(thetaFact, 2);
    real_type t6 = pow(thetaFact, 3);
    real_type t12 = thetaFact/2.0;
    real_type t7 = t3*2.0;
    real_type t8 = t3*4.0;
    real_type t9 = t4*3.0;
    real_type t10 = t3*5.0;
    real_type t11 = t5*2.0;
    real_type t14 = -t4;
    real_type t17 = -t5;
    real_type t18 = t5/2.0;
    real_type t19 = t6/2.0;
    real_type t20 = t6*(3.0/2.0);
    real_type t21 = t5*(5.0/2.0);
    real_type t13 = -t7;
    real_type t15 = -t9;
    real_type t16 = -t10;
    real_type t22 = -t19;
    real_type t23 = -t20;
    real_type t24 = -t21;
    real_type t25 = t3+t14;
    real_type t31 = t12+t17+t19;
    real_type t26 = lambdaFact+t4+t13;
    real_type t27 = lambdaFact+t8+t15;
    real_type t28 = t9+t16+2.0;
    real_type t29 = t18+t22;
    real_type t30 = t20+t24+1.0;
    real_type t32 = t11+t12+t23;
    
    conv_poly[0]= (t25*t29)/2.0;
    conv_poly[1]= t27*t29*(-1.0/2.0);
    conv_poly[2]= t28*t29*(-1.0/2.0);
    conv_poly[3]= (t26*t29)/2.0;
    conv_poly[4]= t25*t32*(-1.0/2.0);
    conv_poly[5]= (t27*t32)/2.0;
    conv_poly[6]= (t28*t32)/2.0;
    conv_poly[7]= t26*t32*(-1.0/2.0);
    conv_poly[8]= t25*t30*(-1.0/2.0);
    conv_poly[9]= (t27*t30)/2.0;
    conv_poly[10]= (t28*t30)/2.0;
    conv_poly[11]= t26*t30*(-1.0/2.0);
    conv_poly[12]= (t25*t31)/2.0;
    conv_poly[13]= t27*t31*(-1.0/2.0);
    conv_poly[14]= t28*t31*(-1.0/2.0);
    conv_poly[15]= (t26*t31)/2.0;    
}

static real_type interp_bicubic(real_type conv_poly[16], const Eigen::Ref<const MatCx> &cx_tab, int lambdaIdx, int thetaIdx) {
    const int lambdaNum= cx_tab.rows();
    const int thetaNum= cx_tab.cols();
   
    real_type cc[16];
    const real_type boundry_coeffs[3]= {3.0, -3.0, 1.0};
    // c11
    if(thetaIdx<0) {
        if(lambdaIdx<0) {
            cc[0]= 0.0;
            for(int r= 1; r<=3; ++r)
                for(int c= 1; c<=3; ++c)
                    cc[0]+= cx_tab(lambdaIdx+r, thetaIdx+c) * boundry_coeffs[r-1] * boundry_coeffs[c-1];
        } else {
            cc[0]= 3.0*cx_tab(lambdaIdx, thetaIdx+1)-3.0*cx_tab(lambdaIdx, thetaIdx+2)+cx_tab(lambdaIdx, thetaIdx+3);
        }
    } else {
        if(lambdaIdx<0) {
            cc[0]= 3.0*cx_tab(lambdaIdx+1, thetaIdx)-3.0*cx_tab(lambdaIdx+2, thetaIdx)+cx_tab(lambdaIdx+3, thetaIdx);
        } else {
            cc[0]= cx_tab(lambdaIdx, thetaIdx);
        }
    }
    // c21
    if(thetaIdx<0) {
        cc[1]= 3.0*cx_tab(lambdaIdx+1, thetaIdx+1)-3.0*cx_tab(lambdaIdx+1, thetaIdx+2)+cx_tab(lambdaIdx+1, thetaIdx+3);
    } else {
        cc[1]= cx_tab(lambdaIdx+1, thetaIdx);    
    }
    // c31
    if(thetaIdx<0) {
        cc[2]= 3.0*cx_tab(lambdaIdx+2, thetaIdx+1)-3.0*cx_tab(lambdaIdx+2, thetaIdx+2)+cx_tab(lambdaIdx+2, thetaIdx+3);
    } else {
        cc[2]= cx_tab(lambdaIdx+2, thetaIdx);    
    }
    //c41
    if(thetaIdx<0) {
        if(lambdaIdx+3 >= lambdaNum) {
            cc[3]= 0.0;
            for(int r= 0; r<=2; ++r)
                for(int c= 1; c<=3; ++c)
                    cc[3]+= cx_tab(lambdaIdx+r, thetaIdx+c) * boundry_coeffs[2-r] * boundry_coeffs[c-1];
        } else {
            cc[3]= 3.0*cx_tab(lambdaIdx+3, thetaIdx+1)-3.0*cx_tab(lambdaIdx+3, thetaIdx+2)+cx_tab(lambdaIdx+3, thetaIdx+3);
        }
    } else {
        if(lambdaIdx+3 >= lambdaNum) {
            cc[3]= 3.0*cx_tab(lambdaIdx+2, thetaIdx)-3.0*cx_tab(lambdaIdx+1, thetaIdx)+cx_tab(lambdaIdx, thetaIdx);
        } else {
            cc[3]= cx_tab(lambdaIdx+3, thetaIdx);    
        }
    }
    //c12
    if(lambdaIdx<0) {
        cc[4]= 3.0*cx_tab(lambdaIdx+1, thetaIdx+1)-3.0*cx_tab(lambdaIdx+2, thetaIdx+1)+cx_tab(lambdaIdx+3, thetaIdx+1);
    } else {
        cc[4]= cx_tab(lambdaIdx, thetaIdx+1);
    }
    //c22
    cc[5]= cx_tab(lambdaIdx+1, thetaIdx+1);
    //c32
    cc[6]= cx_tab(lambdaIdx+2, thetaIdx+1);
    //c42
    if(lambdaIdx+3 >= lambdaNum) {
        cc[7]= 3.0*cx_tab(lambdaIdx+2, thetaIdx+1)-3.0*cx_tab(lambdaIdx+1, thetaIdx+1)+cx_tab(lambdaIdx, thetaIdx+1);
    } else {
        cc[7]= cx_tab(lambdaIdx+3, thetaIdx+1);
    }
    //c13
    if(lambdaIdx<0) {
        cc[8]= 3.0*cx_tab(lambdaIdx+1, thetaIdx+2)-3.0*cx_tab(lambdaIdx+2, thetaIdx+2)+cx_tab(lambdaIdx+3, thetaIdx+2);
    } else {
        cc[8]= cx_tab(lambdaIdx, thetaIdx+2);
    }
    //c23
    cc[9]= cx_tab(lambdaIdx+1, thetaIdx+2);
    //c33
    cc[10]= cx_tab(lambdaIdx+2, thetaIdx+2);
    //c43
    if(lambdaIdx+3 >= lambdaNum) {
        cc[11]= 3.0*cx_tab(lambdaIdx+2, thetaIdx+2)-3.0*cx_tab(lambdaIdx+1, thetaIdx+2)+cx_tab(lambdaIdx, thetaIdx+2);
    } else {
        cc[11]= cx_tab(lambdaIdx+3, thetaIdx+2);
    }
    //c14
    if(thetaIdx+3 >= thetaNum) {
        if(lambdaIdx<0) {
            cc[12]= 0.0;
            for(int r= 1; r<=3; ++r)
                for(int c= 0; c<=2; ++c)
                    cc[12]+= cx_tab(lambdaIdx+r, thetaIdx+c) * boundry_coeffs[r-1] * boundry_coeffs[2-c];
        } else {
            cc[12]= 3.0*cx_tab(lambdaIdx, thetaIdx+2)-3.0*cx_tab(lambdaIdx, thetaIdx+1)+cx_tab(lambdaIdx, thetaIdx);
        }
    } else {
        if(lambdaIdx<0) {
            cc[12]= 3.0*cx_tab(lambdaIdx+1, thetaIdx+3)-3.0*cx_tab(lambdaIdx+2, thetaIdx+3)+cx_tab(lambdaIdx+3, thetaIdx+3);
        } else {
            cc[12]= cx_tab(lambdaIdx, thetaIdx+3);
        }
    }
    //c24
    if(thetaIdx+3 >= thetaNum) {
        cc[13]= 3.0*cx_tab(lambdaIdx+1, thetaIdx+2)-3.0*cx_tab(lambdaIdx+1, thetaIdx+1)+cx_tab(lambdaIdx+1, thetaIdx);
    } else {
        cc[13]= cx_tab(lambdaIdx+1, thetaIdx+3);
    }
    //c34
    if(thetaIdx+3 >= thetaNum) {
        cc[14]= 3.0*cx_tab(lambdaIdx+2, thetaIdx+2)-3.0*cx_tab(lambdaIdx+2, thetaIdx+1)+cx_tab(lambdaIdx+2, thetaIdx);
    } else {
        cc[14]= cx_tab(lambdaIdx+2, thetaIdx+3);
    }
    //c44
    if(thetaIdx+3 >= thetaNum) {
        if(lambdaIdx+3 >= lambdaNum) {
            cc[15]= 0.0;
            for(int r= 0; r<=2; ++r)
                for(int c= 0; c<=2; ++c)
                    cc[15]+= cx_tab(lambdaIdx+r, thetaIdx+c) * boundry_coeffs[2-r] * boundry_coeffs[2-c];
        } else {
            cc[15]= 3.0*cx_tab(lambdaIdx+3, thetaIdx+2)-3.0*cx_tab(lambdaIdx+3, thetaIdx+1)+cx_tab(lambdaIdx+3, thetaIdx);
        }
    } else {
        if(lambdaIdx+3 >=  lambdaNum) {
            cc[15]= 3.0*cx_tab(lambdaIdx+2, thetaIdx+3)-3.0*cx_tab(lambdaIdx+1, thetaIdx+3)+cx_tab(lambdaIdx, thetaIdx+3);
        } else {
            cc[15]= cx_tab(lambdaIdx+3, thetaIdx+3);
        }
    }

    real_type cx= 0.0;
    for(int i= 0; i<16; ++i)
        cx+= conv_poly[i] * cc[i];
    
    return cx;
}
