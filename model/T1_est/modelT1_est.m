function T1_est = modelT1_est(params)
% Simulation of a simplified horizontal axis wind turbine

T1_est = MultiBodySystem('T1_est', {'tow_fa' 'phi_rot'}, {'dvwind' 'Tgen' 'theta'});

T1_est.addAuxState('vwind')
T1_est.addAuxImplODE(T1_est.getTimeDeriv(T1_est.aux_state.vwind)-T1_est.inputs.dvwind)

T1_est.addParameter(params);
T1_est.addExternal('cm');
T1_est.addExternal('ct');
T1_est.addExternal('theta_deg');
T1_est.addExternal('lam');
T1_est.addExternal('Trot', [T1_est.dof.tow_fa_d, T1_est.dof.phi_rot_d, T1_est.aux_state.vwind, T1_est.inputs.theta]);
T1_est.addExternal('Fthrust', [T1_est.dof.tow_fa_d, T1_est.dof.phi_rot_d, T1_est.aux_state.vwind, T1_est.inputs.theta]);
% TODO fix vector parameters
T1_est.addExternalParameter('cm_lut', [], params.cm_lut);
T1_est.addExternalParameter('ct_lut', [], params.ct_lut);
T1_est.addExternalParameter('Arot', [], params.Arot);
T1_est.addExternalParameter('Rrot', [], params.Rrot);
T1_est.addExternalParameter('lambdaMax', [], params.lambdaMax);
T1_est.addExternalParameter('lambdaMin', [], params.lambdaMin);
T1_est.addExternalParameter('lambdaStep', [], params.lambdaStep);
T1_est.addExternalParameter('rho', [], params.rho);
T1_est.addExternalParameter('thetaMax', [], params.thetaMax);
T1_est.addExternalParameter('thetaMin', [], params.thetaMin);
T1_est.addExternalParameter('thetaStep', [], params.thetaStep);

T1_est.gravity(3) = -T1_est.params.g;

% Tower
tw_SID = SID(params.tw_sid, -1e-6, 'tower', T1_est);
tower= ElasticBody(T1_est.dof.tow_fa, tw_SID, 'tower');
T1_est.addChild(tower)

% Nacelle
nacelle = RigidBody('nacelle', [], T1_est.params.NacMass, diag([T1_est.params.NacXIner, T1_est.params.NacYIner, T1_est.params.NacZIner]));
nacelle.translate([T1_est.params.NacCMxn, T1_est.params.NacCMyn, T1_est.params.NacCMzn])
tower.addChild(nacelle)

% Hub
hub = RigidBody('hub', [], T1_est.params.HubMass, diag([T1_est.params.HubIner, T1_est.params.HubIner, T1_est.params.HubIner]));
hub.translate([T1_est.params.HubCM+T1_est.params.OverHang-T1_est.params.NacCMxn, -T1_est.params.NacCMyn, T1_est.params.Twr2Shft-T1_est.params.NacCMzn]);
hub.rotateLocalAxis('x', T1_est.dof.phi_rot)
nacelle.addChild(hub);

% Blades
for i = 1:3
    blade = RigidBody(sprintf('blade%d', i), [], T1_est.params.blade_mass, diag([T1_est.params.blade_I0_1_1, T1_est.params.blade_I0_2_2, T1_est.params.blade_I0_3_3]));
    blade.translate([-T1_est.params.HubCM, 0, 0]);
    % sym(2) is important to be able to simplify equations
    blade.rotateLocalAxis('x', (i-1)*T1_est.sym(2)/3*T1_est.sym(pi))
    blade.rotateLocalAxis('z', T1_est.inputs.theta)
    blade.translate([0, 0, T1_est.params.blade_md0_3_1/T1_est.params.blade_mass]);
    hub.addChild(blade)
end


% Geno (effectively fixed to hub but with gear ratio)
geno = RigidBody('generator', [], 0, diag([T1_est.params.GenIner, 0, 0]));
geno.rotateLocalAxis('x', T1_est.dof.phi_rot*T1_est.params.GBRatio)
nacelle.addChild(geno)

% at least for forces given in local coordinates, the kinematic modeling
% must be completed
T1_est.finishKinematics()

% Applied forces and moments
hub.applyForce([T1_est.externals.Fthrust, 0, 0].')
hub.applyMoment([T1_est.externals.Trot, 0, 0].')
geno.applyMoment([-T1_est.inputs.Tgen, 0, 0].')

T1_est.finishKinetics()

T1_est.addOutput('tow_fa_acc', T1_est.dof.tow_fa_dd);
T1_est.addOutput('gen_speed', T1_est.dof.phi_rot_d*T1_est.params.GBRatio);

