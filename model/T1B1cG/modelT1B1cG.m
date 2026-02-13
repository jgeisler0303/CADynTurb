function T1B1cG = modelT1B1cG(params)
% Simulation of a simplified horizontal axis wind turbine

T1B1cG = MultiBodySystem('T1B1cG', {'tow_fa' 'bld_flp' 'phi_rot' 'phi_gen'}, {'vwind' 'Tgen' 'theta'});
T1B1cG.addParameter(params);
T1B1cG.addExternal('cm');
T1B1cG.addExternal('ct');
T1B1cG.addExternal('cflp');
T1B1cG.addExternal('theta_deg');
T1B1cG.addExternal('lam');
T1B1cG.addExternal('Trot', [T1B1cG.dof.tow_fa_d, T1B1cG.dof.phi_rot_d, T1B1cG.dof.bld_flp_d, T1B1cG.inputs.vwind, T1B1cG.inputs.theta]);
T1B1cG.addExternal('Fthrust', [T1B1cG.dof.tow_fa_d, T1B1cG.dof.phi_rot_d, T1B1cG.dof.bld_flp_d, T1B1cG.inputs.vwind, T1B1cG.inputs.theta]);
T1B1cG.addExternal('modalFlapForce', [T1B1cG.dof.tow_fa_d, T1B1cG.dof.phi_rot_d, T1B1cG.dof.bld_flp_d, T1B1cG.inputs.vwind, T1B1cG.inputs.theta]);
% TODO fix vector parameters
T1B1cG.addExternalParameter('cm_lut', [], params.cm_lut);
T1B1cG.addExternalParameter('ct_lut', [], params.ct_lut);
T1B1cG.addExternalParameter('cf_lut', [], params.ct_lut);
T1B1cG.addExternalParameter('dcm_dvf_v_lut', [], params.ct_lut);
T1B1cG.addExternalParameter('dct_dvf_v_lut', [], params.ct_lut);
T1B1cG.addExternalParameter('dcf_dvf_v_lut', [], params.ct_lut);
T1B1cG.addExternalParameter('Arot', [], params.Arot);
T1B1cG.addExternalParameter('Rrot', [], params.Rrot);
T1B1cG.addExternalParameter('lambdaMax', [], params.lambdaMax);
T1B1cG.addExternalParameter('lambdaMin', [], params.lambdaMin);
T1B1cG.addExternalParameter('lambdaStep', [], params.lambdaStep);
T1B1cG.addExternalParameter('rho', [], params.rho);
T1B1cG.addExternalParameter('thetaMax', [], params.thetaMax);
T1B1cG.addExternalParameter('thetaMin', [], params.thetaMin);
T1B1cG.addExternalParameter('thetaStep', [], params.thetaStep);

T1B1cG.addOutput('tow_fa_acc', T1B1cG.dof.tow_fa_dd);
T1B1cG.addOutput('gen_speed', T1B1cG.dof.phi_gen_d);

T1B1cG.gravity(3) = -T1B1cG.params.g;

% Tower
tw_SID = SID(params.tw_sid, -1e-6, 'tower', T1B1cG);
tower= ElasticBody(T1B1cG.dof.tow_fa, tw_SID, 'tower');
T1B1cG.addChild(tower)

% Nacelle
nacelle = RigidBody('nacelle', [], T1B1cG.params.NacMass, diag([T1B1cG.params.NacXIner, T1B1cG.params.NacYIner, T1B1cG.params.NacZIner]));
nacelle.translate([T1B1cG.params.NacCMxn, T1B1cG.params.NacCMyn, T1B1cG.params.NacCMzn])
tower.addChild(nacelle)

% Hub
hub = RigidBody('hub', [], T1B1cG.params.HubMass, diag([T1B1cG.params.HubIner, T1B1cG.params.HubIner, T1B1cG.params.HubIner]));
hub.translate([T1B1cG.params.HubCM+T1B1cG.params.OverHang-T1B1cG.params.NacCMxn, -T1B1cG.params.NacCMyn, T1B1cG.params.Twr2Shft-T1B1cG.params.NacCMzn]);
hub.rotateLocalAxis('x', T1B1cG.dof.phi_rot)
nacelle.addChild(hub);

% Blades
bd_SID = SID(params.bd_sid, -1e-6, 'blade', T1B1cG);
for i = 1:3
    blade(i) = ElasticBody(T1B1cG.dof.bld_flp, bd_SID, sprintf('blade%d', i));
    blade(i).translate([-T1B1cG.params.HubCM, 0, 0]);
    % sym(2) is important to be able to simplify equations
    blade(i).rotateLocalAxis('x', (i-1)*T1B1cG.sym(2)/3*T1B1cG.sym(pi))
    blade(i).rotateLocalAxis('z', T1B1cG.inputs.theta)
    hub.addChild(blade(i))
end

% Geno (effectively fixed to hub but with gear ratio)
geno = RigidBody('generator', [], 0, diag([T1B1cG.params.GenIner, 0, 0]));
geno.rotateLocalAxis('x', T1B1cG.dof.phi_gen)
nacelle.addChild(geno)

% at least for forces given in local coordinates, the kinematic modeling
% must be completed
T1B1cG.completeSetup()

% Applied forces and moments
M_DT = T1B1cG.params.DTTorSpr*(T1B1cG.dof.phi_gen/T1B1cG.params.GBRatio-T1B1cG.dof.phi_rot) + T1B1cG.params.DTTorDmp*(T1B1cG.dof.phi_gen_d/T1B1cG.params.GBRatio-T1B1cG.dof.phi_rot_d);
hub.applyMoment([M_DT, 0, 0].')
geno.applyMoment([-M_DT/T1B1cG.params.GBRatio, 0, 0].')
geno.applyMoment([-T1B1cG.inputs.Tgen, 0, 0].')


for i = 1:3
    % Thrust (out of plane)
    OoPforce= T1B1cG.externals.Fthrust/3;
    % flapwise
    blade(i).applyForceInLocal([0 0 T1B1cG.params.thrustForceRadius].', OoPforce*[cos(T1B1cG.inputs.theta) 0 0].')
    % edgewise
    blade(i).applyForceInLocal([0 0 T1B1cG.params.thrustForceRadius].', OoPforce*[0 -sin(T1B1cG.inputs.theta) 0].')

    % Torque (in plane)
    IPforce= T1B1cG.externals.Trot/3/T1B1cG.params.torqueForceRadius;
    % flapwise
    blade(i).applyForceInLocal([0 0 T1B1cG.params.torqueForceRadius].', IPforce*[-sin(T1B1cG.inputs.theta) 0 0].')
    % edgewise
    blade(i).applyForceInLocal([0 0 T1B1cG.params.torqueForceRadius].', IPforce*[0 -cos(T1B1cG.inputs.theta) 0].')

    % modal forces
    blade(i).applyElasticForce(T1B1cG.externals.modalFlapForce)
end
