function T2B1i1cG = modelT2B1i1cG(params)
% Simulation of a simplified horizontal axis wind turbine

T2B1i1cG = MultiBodySystem('T2B1i1cG', {'tow_fa' 'tow_ss' 'bld1_flp' 'bld2_flp' 'bld3_flp' 'bld_edg' 'phi_rot' 'phi_gen'}, {'Tgen' 'theta1' 'theta2' 'theta3' 'vwind' 'h_shear' 'v_shear'});
T2B1i1cG.addParameter(params);
T2B1i1cG.addExternal('cm1');
T2B1i1cG.addExternal('cm2');
T2B1i1cG.addExternal('cm3');
T2B1i1cG.addExternal('ct1');
T2B1i1cG.addExternal('ct2');
T2B1i1cG.addExternal('ct3');
T2B1i1cG.addExternal('cflp1');
T2B1i1cG.addExternal('cflp2');
T2B1i1cG.addExternal('cflp3');
T2B1i1cG.addExternal('cedg');
T2B1i1cG.addExternal('cmy_D23_1');
T2B1i1cG.addExternal('cmy_D23_2');
T2B1i1cG.addExternal('cmy_D23_3');
T2B1i1cG.addExternal('theta_deg1');
T2B1i1cG.addExternal('theta_deg2');
T2B1i1cG.addExternal('theta_deg3');
T2B1i1cG.addExternal('lam');
T2B1i1cG.addExternal('Trot1', [T2B1i1cG.dof.tow_fa_d, T2B1i1cG.dof.phi_rot_d, T2B1i1cG.dof.bld2_flp_d, T2B1i1cG.dof.bld_edg_d, T2B1i1cG.inputs.vwind, T2B1i1cG.inputs.theta1, T2B1i1cG.inputs.h_shear, T2B1i1cG.inputs.v_shear, T2B1i1cG.dof.phi_rot]);
T2B1i1cG.addExternal('Trot2', [T2B1i1cG.dof.tow_fa_d, T2B1i1cG.dof.phi_rot_d, T2B1i1cG.dof.bld2_flp_d, T2B1i1cG.dof.bld_edg_d, T2B1i1cG.inputs.vwind, T2B1i1cG.inputs.theta2, T2B1i1cG.inputs.h_shear, T2B1i1cG.inputs.v_shear, T2B1i1cG.dof.phi_rot]);
T2B1i1cG.addExternal('Trot3', [T2B1i1cG.dof.tow_fa_d, T2B1i1cG.dof.phi_rot_d, T2B1i1cG.dof.bld3_flp_d, T2B1i1cG.dof.bld_edg_d, T2B1i1cG.inputs.vwind, T2B1i1cG.inputs.theta3, T2B1i1cG.inputs.h_shear, T2B1i1cG.inputs.v_shear, T2B1i1cG.dof.phi_rot]);
T2B1i1cG.addExternal('Fthrust1', [T2B1i1cG.dof.tow_fa_d, T2B1i1cG.dof.phi_rot_d, T2B1i1cG.dof.bld2_flp_d, T2B1i1cG.dof.bld_edg_d, T2B1i1cG.inputs.vwind, T2B1i1cG.inputs.theta1, T2B1i1cG.inputs.h_shear, T2B1i1cG.inputs.v_shear, T2B1i1cG.dof.phi_rot]);
T2B1i1cG.addExternal('Fthrust2', [T2B1i1cG.dof.tow_fa_d, T2B1i1cG.dof.phi_rot_d, T2B1i1cG.dof.bld2_flp_d, T2B1i1cG.dof.bld_edg_d, T2B1i1cG.inputs.vwind, T2B1i1cG.inputs.theta2, T2B1i1cG.inputs.h_shear, T2B1i1cG.inputs.v_shear, T2B1i1cG.dof.phi_rot]);
T2B1i1cG.addExternal('Fthrust3', [T2B1i1cG.dof.tow_fa_d, T2B1i1cG.dof.phi_rot_d, T2B1i1cG.dof.bld3_flp_d, T2B1i1cG.dof.bld_edg_d, T2B1i1cG.inputs.vwind, T2B1i1cG.inputs.theta3, T2B1i1cG.inputs.h_shear, T2B1i1cG.inputs.v_shear, T2B1i1cG.dof.phi_rot]);
T2B1i1cG.addExternal('modalFlapForce1', [T2B1i1cG.dof.tow_fa_d, T2B1i1cG.dof.phi_rot_d, T2B1i1cG.dof.bld2_flp_d, T2B1i1cG.dof.bld_edg_d, T2B1i1cG.inputs.vwind, T2B1i1cG.inputs.theta1, T2B1i1cG.inputs.h_shear, T2B1i1cG.inputs.v_shear, T2B1i1cG.dof.phi_rot]);
T2B1i1cG.addExternal('modalFlapForce2', [T2B1i1cG.dof.tow_fa_d, T2B1i1cG.dof.phi_rot_d, T2B1i1cG.dof.bld2_flp_d, T2B1i1cG.dof.bld_edg_d, T2B1i1cG.inputs.vwind, T2B1i1cG.inputs.theta2, T2B1i1cG.inputs.h_shear, T2B1i1cG.inputs.v_shear, T2B1i1cG.dof.phi_rot]);
T2B1i1cG.addExternal('modalFlapForce3', [T2B1i1cG.dof.tow_fa_d, T2B1i1cG.dof.phi_rot_d, T2B1i1cG.dof.bld3_flp_d, T2B1i1cG.dof.bld_edg_d, T2B1i1cG.inputs.vwind, T2B1i1cG.inputs.theta3, T2B1i1cG.inputs.h_shear, T2B1i1cG.inputs.v_shear, T2B1i1cG.dof.phi_rot]);
T2B1i1cG.addExternal('modalEdgeForce', [T2B1i1cG.dof.tow_fa_d, T2B1i1cG.dof.phi_rot_d, T2B1i1cG.dof.bld2_flp_d, T2B1i1cG.dof.bld2_flp_d, T2B1i1cG.dof.bld3_flp_d, T2B1i1cG.dof.bld_edg_d, T2B1i1cG.inputs.vwind, T2B1i1cG.inputs.theta1, T2B1i1cG.inputs.theta2, T2B1i1cG.inputs.theta3]);
T2B1i1cG.addExternal('MyD23_1', [T2B1i1cG.dof.tow_fa_d, T2B1i1cG.dof.phi_rot_d, T2B1i1cG.dof.bld2_flp_d, T2B1i1cG.inputs.theta1, T2B1i1cG.inputs.vwind, T2B1i1cG.inputs.h_shear, T2B1i1cG.inputs.v_shear, T2B1i1cG.dof.phi_rot]);
T2B1i1cG.addExternal('MyD23_2', [T2B1i1cG.dof.tow_fa_d, T2B1i1cG.dof.phi_rot_d, T2B1i1cG.dof.bld2_flp_d, T2B1i1cG.inputs.theta2, T2B1i1cG.inputs.vwind, T2B1i1cG.inputs.h_shear, T2B1i1cG.inputs.v_shear, T2B1i1cG.dof.phi_rot]);
T2B1i1cG.addExternal('MyD23_3', [T2B1i1cG.dof.tow_fa_d, T2B1i1cG.dof.phi_rot_d, T2B1i1cG.dof.bld3_flp_d, T2B1i1cG.inputs.theta3, T2B1i1cG.inputs.vwind, T2B1i1cG.inputs.h_shear, T2B1i1cG.inputs.v_shear, T2B1i1cG.dof.phi_rot]);
T2B1i1cG.addExternal('Ftow_y', T2B1i1cG.dof.tow_ss_d);

% TODO fix vector parameters
T2B1i1cG.addExternalParameter('cm_lut', [], params.cm_lut);
T2B1i1cG.addExternalParameter('ct_lut', [], params.ct_lut);
T2B1i1cG.addExternalParameter('cf_lut', [], params.ct_lut);
T2B1i1cG.addExternalParameter('ce_lut', [], params.ce_lut);
T2B1i1cG.addExternalParameter('dcm_dvf_v_lut', [], params.ct_lut);
T2B1i1cG.addExternalParameter('dcm_dve_v_lut', [], params.dcm_dve_v_lut);
T2B1i1cG.addExternalParameter('dcm_dkappa_v_lut', [], params.dcm_dkappa_v_lut);
T2B1i1cG.addExternalParameter('dct_dvf_v_lut', [], params.ct_lut);
T2B1i1cG.addExternalParameter('dct_dve_v_lut', [], params.dct_dve_v_lut);
T2B1i1cG.addExternalParameter('dct_dkappa_v_lut', [], params.dct_dkappa_v_lut);
T2B1i1cG.addExternalParameter('dcf_dvf_v_lut', [], params.ct_lut);
T2B1i1cG.addExternalParameter('dcf_dve_v_lut', [], params.dcf_dve_v_lut);
T2B1i1cG.addExternalParameter('dcf_dkappa_v_lut', [], params.dcf_dkappa_v_lut);
T2B1i1cG.addExternalParameter('dce_dvf_v_lut', [], params.dce_dvf_v_lut);
T2B1i1cG.addExternalParameter('dce_dve_v_lut', [], params.dce_dve_v_lut);
T2B1i1cG.addExternalParameter('cmy_D23_lut', [], params.cmy_D23_lut);
T2B1i1cG.addExternalParameter('dcmy_D23_dvf_v_lut', [], params.dcmy_D23_dvf_v_lut);
T2B1i1cG.addExternalParameter('dcmy_D23_dkappa_v_lut', [], params.dcmy_D23_dkappa_v_lut);
T2B1i1cG.addExternalParameter('dcs_dvy_v_lut', [], params.dcs_dvy_v_lut);
T2B1i1cG.addExternalParameter('Arot', [], params.Arot);
T2B1i1cG.addExternalParameter('Rrot', [], params.Rrot);
T2B1i1cG.addExternalParameter('lambdaMax', [], params.lambdaMax);
T2B1i1cG.addExternalParameter('lambdaMin', [], params.lambdaMin);
T2B1i1cG.addExternalParameter('lambdaStep', [], params.lambdaStep);
T2B1i1cG.addExternalParameter('rho', [], params.rho);
T2B1i1cG.addExternalParameter('thetaMax', [], params.thetaMax);
T2B1i1cG.addExternalParameter('thetaMin', [], params.thetaMin);
T2B1i1cG.addExternalParameter('thetaStep', [], params.thetaStep);

T2B1i1cG.addConstraintCoordinate({'M_flp1' 'M_flp2' 'M_flp3' 'M_edg1' 'M_edg2' 'M_edg3' 'M_tow_x' 'M_tow_y'})

T2B1i1cG.gravity(3) = -T2B1i1cG.params.g;

% Tower
tw_SID = SID(params.tw_sid, -1e-6, 'tower', T2B1i1cG);
tower= ElasticBody([T2B1i1cG.dof.tow_fa T2B1i1cG.dof.tow_ss], tw_SID, 'tower');
tower.rotateLocalAxis('y', T2B1i1cG.doc.M_tow_y)
tower.rotateLocalAxis('x', T2B1i1cG.doc.M_tow_x)
T2B1i1cG.addChild(tower)

% Nacelle
nacelle = RigidBody('nacelle', [], T2B1i1cG.params.NacMass, diag([T2B1i1cG.params.NacXIner, T2B1i1cG.params.NacYIner, T2B1i1cG.params.NacZIner]));
nacelle.translate([T2B1i1cG.params.NacCMxn, T2B1i1cG.params.NacCMyn, T2B1i1cG.params.NacCMzn])
tower.addChild(nacelle)

% Hub
hub = RigidBody('hub', [], T2B1i1cG.params.HubMass, diag([T2B1i1cG.params.HubIner, T2B1i1cG.params.HubIner, T2B1i1cG.params.HubIner]));
hub.translate([T2B1i1cG.params.HubCM+T2B1i1cG.params.OverHang-T2B1i1cG.params.NacCMxn, -T2B1i1cG.params.NacCMyn, T2B1i1cG.params.Twr2Shft-T2B1i1cG.params.NacCMzn]);
hub.rotateLocalAxis('x', T2B1i1cG.dof.phi_rot)
nacelle.addChild(hub);

% Blades
bd_SID = SID(params.bd_sid, -1e-6, 'blade', T2B1i1cG);
for i = 1:3
    blade(i) = ElasticBody([T2B1i1cG.dof.(sprintf('bld%d_flp', i)) T2B1i1cG.dof.bld_edg], bd_SID, sprintf('blade%d', i));
    blade(i).translate([-T2B1i1cG.params.HubCM, 0, 0]);
    % sym(2) is important to be able to simplify equations
    blade(i).rotateLocalAxis('x', (i-1)*sym(2)/3*sym(pi))
    blade(i).rotateLocalAxis('z', T2B1i1cG.inputs.(sprintf('theta%d', i)))
    blade(i).rotateLocalAxis('x', T2B1i1cG.doc.(sprintf('M_edg%d', i)))
    blade(i).rotateLocalAxis('y', T2B1i1cG.doc.(sprintf('M_flp%d', i)))
    hub.addChild(blade(i))
end

% Geno (effectively fixed to hub but with gear ratio)
geno = RigidBody('generator', [], 0, diag([T2B1i1cG.params.GenIner, 0, 0]));
geno.rotateLocalAxis('x', T2B1i1cG.dof.phi_gen)
nacelle.addChild(geno)

% at least for forces given in local coordinates, the kinematic modeling
% must be completed
T2B1i1cG.completeSetup()

% Outputs need finished kinematic setup
T2B1i1cG.addOutput('tow_fa_acc', T2B1i1cG.dof.tow_fa_dd);
T2B1i1cG.addOutput('tow_ss_acc', T2B1i1cG.dof.tow_ss_dd);
T2B1i1cG.addOutput('gen_speed', T2B1i1cG.dof.phi_gen_d);
% for now calculate these later, after the kinetic calculations are finished
% T2B1i1cG.addOutput('bld_edg1_mom', T2B2cG.getConstraintForce('M_edg1'));
% T2B1i1cG.addOutput('bld2_flp_mom', T2B2cG.getConstraintForce('M_flp1'));

% Applied forces and moments
M_DT = T2B1i1cG.params.DTTorSpr*(T2B1i1cG.dof.phi_gen/T2B1i1cG.params.GBRatio-T2B1i1cG.dof.phi_rot) + T2B1i1cG.params.DTTorDmp*(T2B1i1cG.dof.phi_gen_d/T2B1i1cG.params.GBRatio-T2B1i1cG.dof.phi_rot_d);
hub.applyMoment([M_DT, 0, 0])
geno.applyMoment([-M_DT/T2B1i1cG.params.GBRatio, 0, 0])
geno.applyMoment([-T2B1i1cG.inputs.Tgen, 0, 0])

nacelle.applyMoment([-M_DT, 0, 0])
nacelle.applyForce([0, T2B1i1cG.externals.Ftow_y, 0])


for i = 1:3
    % Thrust (out of plane)
    OoPforce= T2B1i1cG.externals.(sprintf('Fthrust%d', i));
    thrustForceRadius= sym('2/3')*T2B1i1cG.params.Rrot;
    % flapwise
    blade(i).applyForceInLocal([0 0 thrustForceRadius]', OoPforce*[cos(T2B1i1cG.inputs.(sprintf('theta%d', i))) 0 0]')
    % edgewise
    blade(i).applyForceInLocal([0 0 thrustForceRadius]', OoPforce*[0 -sin(T2B1i1cG.inputs.(sprintf('theta%d', i))) 0]')

    Rtheta= Body.rotationMatrix([0 0 1], -T2B1i1cG.inputs.(sprintf('theta%d', i)));
    blade(i).applyMoment(blade(i).T0(1:3, 1:3)*Rtheta(1:3, 1:3) * [0 T2B1i1cG.externals.(sprintf('MyD23_%d', i)) 0]');

    % Torque (in plane)
    IPforce= T2B1i1cG.externals.(sprintf('Trot%d', i))/T2B1i1cG.params.torqueForceRadius;
    % flapwise
    blade(i).applyForceInLocal([0 0 T2B1i1cG.params.torqueForceRadius]', IPforce*[-sin(T2B1i1cG.inputs.(sprintf('theta%d', i))) 0 0]')
    % edgewise
    blade(i).applyForceInLocal([0 0 T2B1i1cG.params.torqueForceRadius]', IPforce*[0 -cos(T2B1i1cG.inputs.(sprintf('theta%d', i))) 0]')

    % modal forces
    blade(i).applyElasticForce([T2B1i1cG.externals.(sprintf('modalFlapForce%d', i)) T2B1i1cG.externals.modalEdgeForce]')
end
