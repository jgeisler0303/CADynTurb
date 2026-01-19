function T2B2cG = modelT2B2cG(params)
% Simulation of a simplified horizontal axis wind turbine

T2B2cG = MultiBodySystem('T2B2cG', {'tow_fa' 'tow_ss' 'bld_flp' 'bld_edg' 'phi_rot' 'phi_gen'}, {'vwind' 'Tgen' 'theta'});
T2B2cG.addParameter(params);
T2B2cG.addExternal('cm');
T2B2cG.addExternal('ct');
T2B2cG.addExternal('cflp');
T2B2cG.addExternal('cedg');
T2B2cG.addExternal('cmy_D23');
T2B2cG.addExternal('theta_deg');
T2B2cG.addExternal('lam');
T2B2cG.addExternal('Trot', [T2B2cG.dof.tow_fa_d, T2B2cG.dof.phi_rot_d, T2B2cG.dof.bld_flp_d, T2B2cG.dof.bld_edg_d, T2B2cG.inputs.vwind, T2B2cG.inputs.theta]);
T2B2cG.addExternal('Fthrust', [T2B2cG.dof.tow_fa_d, T2B2cG.dof.phi_rot_d, T2B2cG.dof.bld_flp_d, T2B2cG.dof.bld_edg_d, T2B2cG.inputs.vwind, T2B2cG.inputs.theta]);
T2B2cG.addExternal('modalFlapForce', [T2B2cG.dof.tow_fa_d, T2B2cG.dof.phi_rot_d, T2B2cG.dof.bld_flp_d, T2B2cG.dof.bld_edg_d, T2B2cG.inputs.vwind, T2B2cG.inputs.theta]);
T2B2cG.addExternal('modalEdgeForce', [T2B2cG.dof.tow_fa_d, T2B2cG.dof.phi_rot_d, T2B2cG.dof.bld_flp_d, T2B2cG.dof.bld_edg_d, T2B2cG.inputs.vwind, T2B2cG.inputs.theta]);
T2B2cG.addExternal('MyD23', [T2B2cG.dof.phi_rot_d, T2B2cG.inputs.vwind, T2B2cG.inputs.theta]);
T2B2cG.addExternal('Ftow_y', T2B2cG.dof.tow_ss_d);

% TODO fix vector parameters
T2B2cG.addExternalParameter('cm_lut', [], params.cm_lut);
T2B2cG.addExternalParameter('ct_lut', [], params.ct_lut);
T2B2cG.addExternalParameter('cf_lut', [], params.ct_lut);
T2B2cG.addExternalParameter('ce_lut', [], params.ce_lut);
T2B2cG.addExternalParameter('dcm_dvf_v_lut', [], params.ct_lut);
T2B2cG.addExternalParameter('dcm_dve_v_lut', [], params.dcm_dve_v_lut);
T2B2cG.addExternalParameter('dct_dvf_v_lut', [], params.ct_lut);
T2B2cG.addExternalParameter('dct_dve_v_lut', [], params.dct_dve_v_lut);
T2B2cG.addExternalParameter('dcf_dvf_v_lut', [], params.ct_lut);
T2B2cG.addExternalParameter('dcf_dve_v_lut', [], params.dcf_dve_v_lut);
T2B2cG.addExternalParameter('dce_dvf_v_lut', [], params.dce_dvf_v_lut);
T2B2cG.addExternalParameter('dce_dve_v_lut', [], params.dce_dve_v_lut);
T2B2cG.addExternalParameter('cmy_D23_lut', [], params.cmy_D23_lut);
T2B2cG.addExternalParameter('dcs_dvy_v_lut', [], params.dcs_dvy_v_lut);
T2B2cG.addExternalParameter('Arot', [], params.Arot);
T2B2cG.addExternalParameter('Rrot', [], params.Rrot);
T2B2cG.addExternalParameter('lambdaMax', [], params.lambdaMax);
T2B2cG.addExternalParameter('lambdaMin', [], params.lambdaMin);
T2B2cG.addExternalParameter('lambdaStep', [], params.lambdaStep);
T2B2cG.addExternalParameter('rho', [], params.rho);
T2B2cG.addExternalParameter('thetaMax', [], params.thetaMax);
T2B2cG.addExternalParameter('thetaMin', [], params.thetaMin);
T2B2cG.addExternalParameter('thetaStep', [], params.thetaStep);

T2B2cG.addConstraintCoordinate({'M_edg' 'M_flp'})

T2B2cG.gravity(3) = -T2B2cG.params.g;

% Tower
tw_SID = SID(params.tw_sid, -1e-6, 'tower', T2B2cG);
tower= ElasticBody([T2B2cG.dof.tow_fa T2B2cG.dof.tow_ss], tw_SID, 'tower');
T2B2cG.addChild(tower)

% Nacelle
nacelle = RigidBody('nacelle', [], T2B2cG.params.NacMass, diag([T2B2cG.params.NacXIner, T2B2cG.params.NacYIner, T2B2cG.params.NacZIner]));
nacelle.translate([T2B2cG.params.NacCMxn, T2B2cG.params.NacCMyn, T2B2cG.params.NacCMzn])
tower.addChild(nacelle)

% Hub
hub = RigidBody('hub', [], T2B2cG.params.HubMass, diag([T2B2cG.params.HubIner, T2B2cG.params.HubIner, T2B2cG.params.HubIner]));
hub.translate([T2B2cG.params.HubCM+T2B2cG.params.OverHang-T2B2cG.params.NacCMxn, -T2B2cG.params.NacCMyn, T2B2cG.params.Twr2Shft-T2B2cG.params.NacCMzn]);
hub.rotateLocalAxis('x', T2B2cG.dof.phi_rot)
nacelle.addChild(hub);

% Blades
bd_SID = SID(params.bd_sid, -1e-6, 'blade', T2B2cG);
for i = 1:3
    blade(i) = ElasticBody([T2B2cG.dof.bld_flp T2B2cG.dof.bld_edg], bd_SID, sprintf('blade%d', i));
    blade(i).translate([-T2B2cG.params.HubCM, 0, 0]);
    % sym(2) is important to be able to simplify equations
    blade(i).rotateLocalAxis('x', (i-1)*sym(2)/3*sym(pi))
    blade(i).rotateLocalAxis('z', T2B2cG.inputs.theta)
    blade(i).rotateLocalAxis('x', T2B2cG.doc.M_edg)
    blade(i).rotateLocalAxis('y', T2B2cG.doc.M_flp)
    hub.addChild(blade(i))
end

% Geno (effectively fixed to hub but with gear ratio)
geno = RigidBody('generator', [], 0, diag([T2B2cG.params.GenIner, 0, 0]));
geno.rotateLocalAxis('x', T2B2cG.dof.phi_gen)
nacelle.addChild(geno)

% at least for forces given in local coordinates, the kinematic modeling
% must be completed
T2B2cG.completeSetup()

% Outputs need finished kinematic setup
T2B2cG.addOutput('tow_fa_acc', T2B2cG.dof.tow_fa_dd);
T2B2cG.addOutput('tow_ss_acc', T2B2cG.dof.tow_ss_dd);
T2B2cG.addOutput('gen_speed', T2B2cG.dof.phi_gen_d);
Rcone= Body.rotationMatrix('y', T2B2cG.params.cone);
Rtheta= Body.rotationMatrix('z', T2B2cG.inputs.theta);
Relast= T2B2cG.bodies.blade1.Trot_elast(30);
Rlocal= (T2B2cG.bodies.hub.T0(1:3, 1:3)*Rcone(1:3, 1:3)*Rtheta(1:3, 1:3)*Relast)';
abs_accel_elast= T2B2cG.bodies.blade1.getA0Elast(30);
bld_accel= Rlocal * abs_accel_elast;
T2B2cG.addOutput('bld_flp_acc', Body.removeEps(bld_accel(1)));
T2B2cG.addOutput('bld_edg_acc', Body.removeEps(bld_accel(2)));
% for now calculate these later, after the kinetic calculations are finished
% T2B2cG.addOutput('bld_edg_mom', T2B2cG.getConstraintForce('M_edg')/3);
% T2B2cG.addOutput('bld_flp_mom', T2B2cG.getConstraintForce('M_flp')/3);

% Applied forces and moments
M_DT = T2B2cG.params.DTTorSpr*(T2B2cG.dof.phi_gen/T2B2cG.params.GBRatio-T2B2cG.dof.phi_rot) + T2B2cG.params.DTTorDmp*(T2B2cG.dof.phi_gen_d/T2B2cG.params.GBRatio-T2B2cG.dof.phi_rot_d);
hub.applyMoment([M_DT, 0, 0])
geno.applyMoment([-M_DT/T2B2cG.params.GBRatio, 0, 0])
geno.applyMoment([-T2B2cG.inputs.Tgen, 0, 0])

nacelle.applyMoment([-M_DT, 0, 0])
nacelle.applyForce([0, T2B2cG.externals.Ftow_y, 0])


for i = 1:3
    % Thrust (out of plane)
    OoPforce= T2B2cG.externals.Fthrust/3;
    thrustForceRadius= sym('2/3')*T2B2cG.params.Rrot;
    % flapwise
    blade(i).applyForceInLocal([0 0 thrustForceRadius]', OoPforce*[cos(T2B2cG.inputs.theta) 0 0]')
    % edgewise
    blade(i).applyForceInLocal([0 0 thrustForceRadius]', OoPforce*[0 -sin(T2B2cG.inputs.theta) 0]')

    Rtheta= Body.rotationMatrix([0 0 1], -T2B2cG.inputs.theta);
    blade(i).applyMoment(blade(i).T0(1:3, 1:3)*Rtheta(1:3, 1:3) * [0 T2B2cG.externals.MyD23 0]');

    % Torque (in plane)
    IPforce= T2B2cG.externals.Trot/3/T2B2cG.params.torqueForceRadius;
    % flapwise
    blade(i).applyForceInLocal([0 0 T2B2cG.params.torqueForceRadius]', IPforce*[-sin(T2B2cG.inputs.theta) 0 0]')
    % edgewise
    blade(i).applyForceInLocal([0 0 T2B2cG.params.torqueForceRadius]', IPforce*[0 -cos(T2B2cG.inputs.theta) 0]')

    % modal forces
    blade(i).applyElasticForce([T2B2cG.externals.modalFlapForce T2B2cG.externals.modalEdgeForce]')
end
