function T1B1cG_est = modelT1B1cG_est(params)
% Simulation of a simplified horizontal axis wind turbine

T1B1cG_est = MultiBodySystem('T1B1cG_est', {'tow_fa' 'bld_flp' 'phi_rot' 'Dphi_gen'}, {'dvwind' 'Tgen' 'theta'});

T1B1cG_est.addAuxState('vwind')
T1B1cG_est.addAuxImplODE(T1B1cG_est.getTimeDeriv(T1B1cG_est.aux_state.vwind)-T1B1cG_est.inputs.dvwind)

T1B1cG_est.addParameter(params);
T1B1cG_est.addExternal('cm');
T1B1cG_est.addExternal('ct');
T1B1cG_est.addExternal('cflp');
T1B1cG_est.addExternal('theta_deg');
T1B1cG_est.addExternal('lam');
T1B1cG_est.addExternal('Trot', [T1B1cG_est.dof.tow_fa_d, T1B1cG_est.dof.phi_rot_d, T1B1cG_est.dof.bld_flp_d, T1B1cG_est.aux_state.vwind, T1B1cG_est.inputs.theta]);
T1B1cG_est.addExternal('Fthrust', [T1B1cG_est.dof.tow_fa_d, T1B1cG_est.dof.phi_rot_d, T1B1cG_est.dof.bld_flp_d, T1B1cG_est.aux_state.vwind, T1B1cG_est.inputs.theta]);
T1B1cG_est.addExternal('modalFlapForce', [T1B1cG_est.dof.tow_fa_d, T1B1cG_est.dof.phi_rot_d, T1B1cG_est.dof.bld_flp_d, T1B1cG_est.aux_state.vwind, T1B1cG_est.inputs.theta]);
% TODO fix vector parameters
T1B1cG_est.addExternalParameter('cm_lut', [], params.cm_lut);
T1B1cG_est.addExternalParameter('ct_lut', [], params.ct_lut);
T1B1cG_est.addExternalParameter('cf_lut', [], params.ct_lut);
T1B1cG_est.addExternalParameter('dcm_dvf_v_lut', [], params.ct_lut);
T1B1cG_est.addExternalParameter('dct_dvf_v_lut', [], params.ct_lut);
T1B1cG_est.addExternalParameter('dcf_dvf_v_lut', [], params.ct_lut);
T1B1cG_est.addExternalParameter('Arot', [], params.Arot);
T1B1cG_est.addExternalParameter('Rrot', [], params.Rrot);
T1B1cG_est.addExternalParameter('lambdaMax', [], params.lambdaMax);
T1B1cG_est.addExternalParameter('lambdaMin', [], params.lambdaMin);
T1B1cG_est.addExternalParameter('lambdaStep', [], params.lambdaStep);
T1B1cG_est.addExternalParameter('rho', [], params.rho);
T1B1cG_est.addExternalParameter('thetaMax', [], params.thetaMax);
T1B1cG_est.addExternalParameter('thetaMin', [], params.thetaMin);
T1B1cG_est.addExternalParameter('thetaStep', [], params.thetaStep);

T1B1cG_est.addOutput('tow_fa_acc', T1B1cG_est.dof.tow_fa_dd);
T1B1cG_est.addOutput('gen_speed', T1B1cG_est.dof.phi_rot_d*T1B1cG_est.params.GBRatio+T1B1cG_est.dof.Dphi_gen_d);

T1B1cG_est.gravity(3) = -T1B1cG_est.params.g;

% Tower
tw_SID = SID(params.tw_sid, -1e-6, 'tower', T1B1cG_est);
tower= ElasticBody(T1B1cG_est.dof.tow_fa, tw_SID, 'tower');
T1B1cG_est.addChild(tower)

% Nacelle
nacelle = RigidBody('nacelle', [], T1B1cG_est.params.NacMass, diag([T1B1cG_est.params.NacXIner, T1B1cG_est.params.NacYIner, T1B1cG_est.params.NacZIner]));
nacelle.translate([T1B1cG_est.params.NacCMxn, T1B1cG_est.params.NacCMyn, T1B1cG_est.params.NacCMzn])
tower.addChild(nacelle)

% Hub
hub = RigidBody('hub', [], T1B1cG_est.params.HubMass, diag([T1B1cG_est.params.HubIner, T1B1cG_est.params.HubIner, T1B1cG_est.params.HubIner]));
hub.translate([T1B1cG_est.params.HubCM+T1B1cG_est.params.OverHang-T1B1cG_est.params.NacCMxn, -T1B1cG_est.params.NacCMyn, T1B1cG_est.params.Twr2Shft-T1B1cG_est.params.NacCMzn]);
hub.rotateLocalAxis('x', T1B1cG_est.dof.phi_rot)
nacelle.addChild(hub);

% Blades
bd_SID = SID(params.bd_sid, -1e-6, 'blade', T1B1cG_est);
for i = 1:3
    blade(i) = ElasticBody(T1B1cG_est.dof.bld_flp, bd_SID, sprintf('blade%d', i));
    blade(i).translate([-T1B1cG_est.params.HubCM, 0, 0]);
    % sym(2) is important to be able to simplify equations
    blade(i).rotateLocalAxis('x', (i-1)*sym(2)/3*sym(pi))
    blade(i).rotateLocalAxis('z', T1B1cG_est.inputs.theta)
    hub.addChild(blade(i))
end

% Geno (effectively fixed to hub but with gear ratio)
geno = RigidBody('generator', [], 0, diag([T1B1cG_est.params.GenIner, 0, 0]));
geno.rotateLocalAxis('x', T1B1cG_est.dof.phi_rot*T1B1cG_est.params.GBRatio+T1B1cG_est.dof.Dphi_gen)
nacelle.addChild(geno)

% at least for forces given in local coordinates, the kinematic modeling
% must be completed
T1B1cG_est.completeSetup()

% Applied forces and moments
M_DT = T1B1cG_est.params.DTTorSpr*(T1B1cG_est.dof.Dphi_gen/T1B1cG_est.params.GBRatio) + T1B1cG_est.params.DTTorDmp*(T1B1cG_est.dof.Dphi_gen_d/T1B1cG_est.params.GBRatio);
hub.applyMoment([M_DT, 0, 0])
geno.applyMoment([-M_DT/T1B1cG_est.params.GBRatio, 0, 0])
geno.applyMoment([-T1B1cG_est.inputs.Tgen, 0, 0])


for i = 1:3
    % Thrust (out of plane)
    OoPforce= T1B1cG_est.externals.Fthrust/3;
    % flapwise
    blade(i).applyForceInLocal([0 0 T1B1cG_est.params.thrustForceRadius]', OoPforce*[cos(T1B1cG_est.inputs.theta) 0 0]')
    % edgewise
    blade(i).applyForceInLocal([0 0 T1B1cG_est.params.thrustForceRadius]', OoPforce*[0 -sin(T1B1cG_est.inputs.theta) 0]')

    % Torque (in plane)
    IPforce= T1B1cG_est.externals.Trot/3/T1B1cG_est.params.torqueForceRadius;
    % flapwise
    blade(i).applyForceInLocal([0 0 T1B1cG_est.params.torqueForceRadius]', IPforce*[-sin(T1B1cG_est.inputs.theta) 0 0]')
    % edgewise
    blade(i).applyForceInLocal([0 0 T1B1cG_est.params.torqueForceRadius]', IPforce*[0 -cos(T1B1cG_est.inputs.theta) 0]')

    % modal forces
    blade(i).applyElasticForce(T1B1cG_est.externals.modalFlapForce)
end
