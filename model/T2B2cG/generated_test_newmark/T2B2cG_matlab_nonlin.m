f= [
    (param.tower_frame_11_psi0_2_1*((-2*param.NacCMxn*param.NacCMyn*param.NacMass*param.tower_frame_11_psi0_1_2*tow_ss_dd)+(12*param.Twr2Shft*param.blade_mass+4*param.HubMass*param.Twr2Shft+4*param.NacCMzn*param.NacMass)*param.tower_frame_11_origin1_1_1_1*tow_fa_dd+((6*bld_edg*param.blade_md1_2_2_1+6*bld_flp*param.blade_md1_1_2_1)*param.g-6*bld_edg_dd*param.Twr2Shft*param.blade_Ct0_2_2-6*bld_flp_dd*param.Twr2Shft*param.blade_Ct0_1_2)*sin(theta)+(((-6*bld_edg*param.blade_md1_2_1_1)-6*bld_flp*param.blade_md1_1_1_1)*param.g+6*bld_edg_dd*param.Twr2Shft*param.blade_Ct0_2_1+6*bld_flp_dd*param.Twr2Shft*param.blade_Ct0_1_1)*cos(theta)+((-6*param.OverHang*param.blade_mass)-2*param.HubMass*param.OverHang-2*param.NacCMxn*param.NacMass-2*param.HubCM*param.HubMass)*param.g-2*Fthrust*param.Twr2Shft)+param.tower_frame_11_psi0_2_1^2*(((3*param.blade_I0_2_2-3*param.blade_I0_1_1)*cos(theta)^2+(6*param.Twr2Shft^2+6*param.OverHang^2)*param.blade_mass+3*param.blade_I0_3_3+3*param.blade_I0_1_1+2*param.HubMass*param.Twr2Shft^2+2*param.HubMass*param.OverHang^2+4*param.HubCM*param.HubMass*param.OverHang+2*param.NacYIner+(2*param.NacCMzn^2+2*param.NacCMxn^2)*param.NacMass+2*param.HubCM^2*param.HubMass+2*param.HubIner)*tow_fa_dd-2*Fthrust*param.OverHang*tow_fa)+(6*param.blade_mass+2*param.NacMass+2*param.HubMass)*param.tower_frame_11_origin1_1_1_1^2*tow_fa_dd+2*param.tower_Me0_1_1*tow_fa_dd+2*param.tower_D0_1_1*tow_fa_d+(6*param.blade_mass+2*param.NacMass+2*param.HubMass)*param.g*param.tower_frame_11_phi1_1_3_1*tow_fa+2*param.tower_K0_1_1*tow_fa+2*param.g*param.tower_Ct1_1_1_3*tow_fa+param.tower_frame_11_origin1_1_1_1*(((-6*bld_edg_dd*param.blade_Ct0_2_2)-6*bld_flp_dd*param.blade_Ct0_1_2)*sin(theta)+(6*bld_edg_dd*param.blade_Ct0_2_1+6*bld_flp_dd*param.blade_Ct0_1_1)*cos(theta)-2*Fthrust))/2
    -(param.tower_frame_11_psi0_1_2*((6*param.GBRatio^2*param.Twr2Shft*param.blade_mass+2*param.GBRatio^2*param.HubMass*param.Twr2Shft+2*param.GBRatio^2*param.NacCMzn*param.NacMass)*param.tower_frame_11_origin1_2_2_1*tow_ss_dd+(3*bld_edg_dd*param.GBRatio^2*param.blade_Cr0_2_2+3*bld_flp_dd*param.GBRatio^2*param.blade_Cr0_1_2)*sin(theta)+(3*param.GBRatio^2*param.blade_I0_2_2-3*param.GBRatio^2*param.blade_I0_1_1)*phi_rot_dd*cos(theta)^2+((-3*bld_edg_dd*param.GBRatio^2*param.blade_Cr0_2_1)-3*bld_flp_dd*param.GBRatio^2*param.blade_Cr0_1_1)*cos(theta)+((-3*param.GBRatio^2*param.blade_I0_2_2)-param.GBRatio^2*param.HubIner)*phi_rot_dd+param.DTTorDmp*param.GBRatio*phi_rot_d+param.DTTorSpr*param.GBRatio*phi_rot-param.GBRatio^2*param.GenIner*phi_gen_dd-param.DTTorDmp*phi_gen_d-param.DTTorSpr*phi_gen-param.GBRatio^2*param.NacCMyn*param.NacMass*param.g-Ftow_y*param.GBRatio^2*param.NacCMzn+Trot*param.GBRatio^2-Tgen*param.GBRatio^2)+param.tower_frame_11_psi0_1_2^2*((3*param.GBRatio^2*param.blade_I0_2_2-3*param.GBRatio^2*param.blade_I0_1_1)*cos(theta)^2-3*param.GBRatio^2*param.Twr2Shft^2*param.blade_mass-3*param.GBRatio^2*param.blade_I0_2_2-param.GBRatio^2*param.HubMass*param.Twr2Shft^2-param.GBRatio^2*param.NacXIner+((-param.GBRatio^2*param.NacCMzn^2)-param.GBRatio^2*param.NacCMyn^2)*param.NacMass-param.GBRatio^2*param.HubIner-param.GBRatio^2*param.GenIner)*tow_ss_dd+((-3*param.GBRatio^2*param.blade_mass)-param.GBRatio^2*param.NacMass-param.GBRatio^2*param.HubMass)*param.tower_frame_11_origin1_2_2_1^2*tow_ss_dd-param.GBRatio^2*param.tower_Me0_2_2*tow_ss_dd-param.GBRatio^2*param.tower_D0_2_2*tow_ss_d+((-3*param.GBRatio^2*param.blade_mass)-param.GBRatio^2*param.NacMass-param.GBRatio^2*param.HubMass)*param.g*param.tower_frame_11_phi1_2_3_2*tow_ss-param.GBRatio^2*param.tower_K0_2_2*tow_ss-param.GBRatio^2*param.g*param.tower_Ct1_2_2_3*tow_ss+param.GBRatio^2*param.NacCMxn*param.NacCMyn*param.NacMass*param.tower_frame_11_psi0_1_2*param.tower_frame_11_psi0_2_1*tow_fa_dd+Ftow_y*param.GBRatio^2*param.tower_frame_11_origin1_2_2_1)/param.GBRatio^2
    param.tower_frame_11_psi0_1_2*(3*param.blade_Cr0_1_1*cos(theta)-3*param.blade_Cr0_1_2*sin(theta))*tow_ss_dd+param.tower_frame_11_psi0_2_1*((3*param.Twr2Shft*param.blade_Ct0_1_1*cos(theta)-3*param.Twr2Shft*param.blade_Ct0_1_2*sin(theta))*tow_fa_dd+(3*param.blade_Ct0_1_2*param.g*sin(theta)-3*param.blade_Ct0_1_1*param.g*cos(theta))*tow_fa)+param.tower_frame_11_origin1_1_1_1*(3*param.blade_Ct0_1_1*cos(theta)-3*param.blade_Ct0_1_2*sin(theta))*tow_fa_dd+(3*bld_edg*param.blade_Oe1_2_1_2+3*bld_flp*param.blade_Oe1_1_1_2)*phi_rot_d^2*sin(theta)^2+(((-3*bld_edg*param.blade_Oe1_2_1_4)-3*bld_flp*param.blade_Oe1_1_1_4)*phi_rot_d^2*cos(theta)-3*param.blade_Cr0_1_2*phi_rot_dd)*sin(theta)+(3*bld_edg*param.blade_Oe1_2_1_1+3*bld_flp*param.blade_Oe1_1_1_1)*phi_rot_d^2*cos(theta)^2+3*param.blade_Cr0_1_1*phi_rot_dd*cos(theta)+3*bld_edg_dd*param.blade_Me0_1_2+3*bld_flp_dd*param.blade_Me0_1_1+3*bld_edg*param.blade_K0_1_2+3*bld_flp*param.blade_K0_1_1+3*bld_flp_d*param.blade_D0_1_1-3*modalFlapForce
    param.tower_frame_11_psi0_1_2*(3*param.blade_Cr0_2_1*cos(theta)-3*param.blade_Cr0_2_2*sin(theta))*tow_ss_dd+param.tower_frame_11_psi0_2_1*((3*param.Twr2Shft*param.blade_Ct0_2_1*cos(theta)-3*param.Twr2Shft*param.blade_Ct0_2_2*sin(theta))*tow_fa_dd+(3*param.blade_Ct0_2_2*param.g*sin(theta)-3*param.blade_Ct0_2_1*param.g*cos(theta))*tow_fa)+param.tower_frame_11_origin1_1_1_1*(3*param.blade_Ct0_2_1*cos(theta)-3*param.blade_Ct0_2_2*sin(theta))*tow_fa_dd+(3*bld_edg*param.blade_Oe1_2_2_2+3*bld_flp*param.blade_Oe1_1_2_2)*phi_rot_d^2*sin(theta)^2+(((-3*bld_edg*param.blade_Oe1_2_2_4)-3*bld_flp*param.blade_Oe1_1_2_4)*phi_rot_d^2*cos(theta)-3*param.blade_Cr0_2_2*phi_rot_dd)*sin(theta)+(3*bld_edg*param.blade_Oe1_2_2_1+3*bld_flp*param.blade_Oe1_1_2_1)*phi_rot_d^2*cos(theta)^2+3*param.blade_Cr0_2_1*phi_rot_dd*cos(theta)+3*bld_edg_dd*param.blade_Me0_2_2+3*bld_flp_dd*param.blade_Me0_2_1+3*bld_edg*param.blade_K0_2_2+3*bld_flp*param.blade_K0_2_1+3*bld_edg_d*param.blade_D0_2_2-3*modalEdgeForce
    -(param.tower_frame_11_psi0_1_2*((3*param.GBRatio*param.blade_I0_2_2-3*param.GBRatio*param.blade_I0_1_1)*cos(theta)^2-3*param.GBRatio*param.blade_I0_2_2-param.GBRatio*param.HubIner)*tow_ss_dd+param.tower_frame_11_psi0_2_1^2*(((3*param.GBRatio*param.blade_I0_2_2-3*param.GBRatio*param.blade_I0_1_1)*phi_rot_d*cos(theta)^2+((-3*param.GBRatio*param.blade_I0_2_2)-param.GBRatio*param.HubIner)*phi_rot_d)*tow_fa*tow_fa_d+((3*param.GBRatio*param.blade_I0_2_2-3*param.GBRatio*param.blade_I0_1_1)*phi_rot_dd*cos(theta)^2+((-3*param.GBRatio*param.blade_I0_2_2)-param.GBRatio*param.HubIner)*phi_rot_dd+Trot*param.GBRatio)*tow_fa^2)+(3*bld_edg_dd*param.GBRatio*param.blade_Cr0_2_2+3*bld_flp_dd*param.GBRatio*param.blade_Cr0_1_2)*sin(theta)+(3*param.GBRatio*param.blade_I0_2_2-3*param.GBRatio*param.blade_I0_1_1)*phi_rot_dd*cos(theta)^2+((-3*bld_edg_dd*param.GBRatio*param.blade_Cr0_2_1)-3*bld_flp_dd*param.GBRatio*param.blade_Cr0_1_1)*cos(theta)+((-3*param.GBRatio*param.blade_I0_2_2)-param.GBRatio*param.HubIner)*phi_rot_dd-param.DTTorDmp*param.GBRatio*phi_rot_d-param.DTTorSpr*param.GBRatio*phi_rot+param.DTTorDmp*phi_gen_d+param.DTTorSpr*phi_gen+Trot*param.GBRatio)/param.GBRatio
    (param.GBRatio^2*param.GenIner*param.tower_frame_11_psi0_1_2*tow_ss_dd+param.tower_frame_11_psi0_2_1^2*(param.GBRatio^2*param.GenIner*phi_gen_d*tow_fa*tow_fa_d+param.GBRatio^2*param.GenIner*phi_gen_dd*tow_fa^2)-param.DTTorDmp*param.GBRatio*phi_rot_d-param.DTTorSpr*param.GBRatio*phi_rot+param.GBRatio^2*param.GenIner*phi_gen_dd+param.DTTorDmp*phi_gen_d+param.DTTorSpr*phi_gen+Tgen*param.GBRatio^2)/param.GBRatio^2
];

y= [
    tow_fa_dd
    tow_ss_dd
    phi_gen_d
    param.tower_frame_11_psi0_1_2*((((-param.Twr2Shft*cos(phi_rot))-param.blade_frame_30_origin0_3_1)*sin(theta)-param.Twr2Shft*sin(param.cone)*sin(phi_rot)*cos(theta))*tow_ss_dd+2*param.blade_frame_30_origin0_3_1*sin(param.cone)*phi_rot_d*cos(theta)*tow_ss_d)+param.tower_frame_11_origin1_2_2_1*(cos(phi_rot)*sin(theta)+sin(param.cone)*sin(phi_rot)*cos(theta))*tow_ss_dd+param.tower_frame_11_psi0_2_1*((((param.OverHang*sin(param.cone)+param.blade_frame_30_origin0_3_1*cos(param.cone))*cos(phi_rot)+param.Twr2Shft*cos(param.cone))*cos(theta)-param.OverHang*sin(phi_rot)*sin(theta))*tow_fa_dd-2*param.blade_frame_30_origin0_3_1*cos(param.cone)*sin(phi_rot)*phi_rot_d*cos(theta)*tow_fa_d)+cos(param.cone)*param.tower_frame_11_origin1_1_1_1*cos(theta)*tow_fa_dd+(((-bld_edg*param.blade_frame_30_origin1_2_1_1)-bld_flp*param.blade_frame_30_origin1_1_1_1)*phi_rot_d^2+bld_edg_dd*param.blade_frame_30_origin1_2_1_1+bld_flp_dd*param.blade_frame_30_origin1_1_1_1)*sin(theta)^2+((((-bld_edg*param.blade_frame_30_origin1_2_1_1)-bld_flp*param.blade_frame_30_origin1_1_1_1)*sin(param.cone)*phi_rot_dd+((-bld_edg*param.blade_frame_30_origin1_2_2_1)-bld_flp*param.blade_frame_30_origin1_1_2_1)*phi_rot_d^2+((-2*bld_edg_d*param.blade_frame_30_origin1_2_1_1)-2*bld_flp_d*param.blade_frame_30_origin1_1_1_1)*sin(param.cone)*phi_rot_d+((-bld_edg_dd*param.blade_frame_30_origin1_2_2_1)-bld_flp_dd*param.blade_frame_30_origin1_1_2_1)*cos(param.cone)+bld_edg_dd*param.blade_frame_30_origin1_2_2_1+bld_flp_dd*param.blade_frame_30_origin1_1_2_1)*cos(theta)-param.blade_frame_30_origin0_3_1*phi_rot_dd)*sin(theta)+(((-bld_edg*param.blade_frame_30_origin1_2_2_1)-bld_flp*param.blade_frame_30_origin1_1_2_1)*sin(param.cone)*phi_rot_dd+((-2*bld_edg_d*param.blade_frame_30_origin1_2_2_1)-2*bld_flp_d*param.blade_frame_30_origin1_1_2_1)*sin(param.cone)*phi_rot_d+(bld_edg_dd*param.blade_frame_30_origin1_2_1_1+bld_flp_dd*param.blade_frame_30_origin1_1_1_1)*cos(param.cone))*cos(theta)^2+param.blade_frame_30_origin0_3_1*sin(param.cone)*phi_rot_d^2*cos(theta)+(bld_edg*param.blade_frame_30_origin0_3_1*param.blade_frame_30_psi0_2_2+bld_flp*param.blade_frame_30_origin0_3_1*param.blade_frame_30_psi0_2_1)*cos(param.cone)*phi_rot_d^2
    param.tower_frame_11_psi0_1_2*((param.Twr2Shft*sin(param.cone)*sin(phi_rot)*sin(theta)+((-param.Twr2Shft*cos(phi_rot))-param.blade_frame_30_origin0_3_1)*cos(theta))*tow_ss_dd-2*param.blade_frame_30_origin0_3_1*sin(param.cone)*phi_rot_d*sin(theta)*tow_ss_d)+param.tower_frame_11_origin1_2_2_1*(cos(phi_rot)*cos(theta)-sin(param.cone)*sin(phi_rot)*sin(theta))*tow_ss_dd+param.tower_frame_11_psi0_2_1*(((((-param.OverHang*sin(param.cone))-param.blade_frame_30_origin0_3_1*cos(param.cone))*cos(phi_rot)-param.Twr2Shft*cos(param.cone))*sin(theta)-param.OverHang*sin(phi_rot)*cos(theta))*tow_fa_dd+2*param.blade_frame_30_origin0_3_1*cos(param.cone)*sin(phi_rot)*phi_rot_d*sin(theta)*tow_fa_d)-cos(param.cone)*param.tower_frame_11_origin1_1_1_1*sin(theta)*tow_fa_dd+((bld_edg*param.blade_frame_30_origin1_2_1_1+bld_flp*param.blade_frame_30_origin1_1_1_1)*sin(param.cone)*phi_rot_dd+(2*bld_edg_d*param.blade_frame_30_origin1_2_1_1+2*bld_flp_d*param.blade_frame_30_origin1_1_1_1)*sin(param.cone)*phi_rot_d+(bld_edg_dd*param.blade_frame_30_origin1_2_2_1+bld_flp_dd*param.blade_frame_30_origin1_1_2_1)*cos(param.cone))*sin(theta)^2+(((bld_edg*param.blade_frame_30_origin1_2_2_1+bld_flp*param.blade_frame_30_origin1_1_2_1)*sin(param.cone)*phi_rot_dd+((-bld_edg*param.blade_frame_30_origin1_2_1_1)-bld_flp*param.blade_frame_30_origin1_1_1_1)*phi_rot_d^2+(2*bld_edg_d*param.blade_frame_30_origin1_2_2_1+2*bld_flp_d*param.blade_frame_30_origin1_1_2_1)*sin(param.cone)*phi_rot_d+((-bld_edg_dd*param.blade_frame_30_origin1_2_1_1)-bld_flp_dd*param.blade_frame_30_origin1_1_1_1)*cos(param.cone)+bld_edg_dd*param.blade_frame_30_origin1_2_1_1+bld_flp_dd*param.blade_frame_30_origin1_1_1_1)*cos(theta)-param.blade_frame_30_origin0_3_1*sin(param.cone)*phi_rot_d^2)*sin(theta)+(((-bld_edg*param.blade_frame_30_origin1_2_2_1)-bld_flp*param.blade_frame_30_origin1_1_2_1)*phi_rot_d^2+bld_edg_dd*param.blade_frame_30_origin1_2_2_1+bld_flp_dd*param.blade_frame_30_origin1_1_2_1)*cos(theta)^2-param.blade_frame_30_origin0_3_1*phi_rot_dd*cos(theta)+((-bld_edg*param.blade_frame_30_origin0_3_1*param.blade_frame_30_psi0_1_2)-bld_flp*param.blade_frame_30_origin0_3_1*param.blade_frame_30_psi0_1_1)*cos(param.cone)*phi_rot_d^2
    -(param.tower_frame_11_psi0_1_2*(9*param.blade_I0_1_1*cos(theta)*tow_ss_dd+(((-9*bld_edg*param.blade_I1_2_3_2)-9*bld_flp*param.blade_I1_1_3_2)*phi_rot_dd*sin(theta)^2+(9*bld_edg*param.blade_I1_2_3_1+9*bld_flp*param.blade_I1_1_3_1)*phi_rot_dd*cos(theta)*sin(theta))*tow_ss)+param.tower_frame_11_psi0_2_1*(9*param.Twr2Shft*param.blade_md0_3_1*sin(theta)*tow_fa_dd-9*param.blade_md0_3_1*param.g*sin(theta)*tow_fa)+9*param.blade_md0_3_1*param.tower_frame_11_origin1_1_1_1*sin(theta)*tow_fa_dd+(9*bld_edg*param.blade_I1_2_3_2+9*bld_flp*param.blade_I1_1_3_2)*phi_rot_d^2*sin(theta)^2+(((-9*bld_edg*param.blade_I1_2_3_1)-9*bld_flp*param.blade_I1_1_3_1)*phi_rot_d^2*cos(theta)-2*Fthrust*param.Rrot-9*MyD23)*sin(theta)+(9*param.blade_I0_1_1*phi_rot_dd-3*Trot)*cos(theta)+9*bld_edg_dd*param.blade_Cr0_2_1+9*bld_flp_dd*param.blade_Cr0_1_1)/9
    -(param.tower_frame_11_psi0_1_2*((((-9*bld_edg*param.blade_I1_2_3_2)-9*bld_flp*param.blade_I1_1_3_2)*phi_rot_dd*cos(theta)*sin(theta)+(9*bld_edg*param.blade_I1_2_3_1+9*bld_flp*param.blade_I1_1_3_1)*phi_rot_dd*cos(theta)^2)*tow_ss-9*param.blade_I0_2_2*sin(theta)*tow_ss_dd)+param.tower_frame_11_psi0_2_1*(9*param.Twr2Shft*param.blade_md0_3_1*cos(theta)*tow_fa_dd-9*param.blade_md0_3_1*param.g*cos(theta)*tow_fa)+9*param.blade_md0_3_1*param.tower_frame_11_origin1_1_1_1*cos(theta)*tow_fa_dd+((9*bld_edg*param.blade_I1_2_3_2+9*bld_flp*param.blade_I1_1_3_2)*phi_rot_d^2*cos(theta)-9*param.blade_I0_2_2*phi_rot_dd+3*Trot)*sin(theta)+((-9*bld_edg*param.blade_I1_2_3_1)-9*bld_flp*param.blade_I1_1_3_1)*phi_rot_d^2*cos(theta)^2+((-2*Fthrust*param.Rrot)-9*MyD23)*cos(theta)+9*bld_edg_dd*param.blade_Cr0_2_2+9*bld_flp_dd*param.blade_Cr0_1_2)/9
];