function T1 = modelT1(params)
% Simulation of a simplified horizontal axis wind turbine
import MAMaS.*

T1 = MultiBodySystem('T1', {'tow_fa' 'phi_rot'}, {'vwind' 'Tgen' 'theta'});
T1.addParameter(params);
T1.addExternal('cm');
T1.addExternal('ct');
T1.addExternal('theta_deg');
T1.addExternal('lam');
T1.addExternal('Trot', [T1.dof.tow_fa_d, T1.dof.phi_rot_d, T1.inputs.vwind, T1.inputs.theta]);
T1.addExternal('Fthrust', [T1.dof.tow_fa_d, T1.dof.phi_rot_d, T1.inputs.vwind, T1.inputs.theta]);
% TODO fix vector parameters
T1.addExternalParameter('cm_lut', [], params.cm_lut);
T1.addExternalParameter('ct_lut', [], params.ct_lut);
T1.addExternalParameter('Arot', [], params.Arot);
T1.addExternalParameter('Rrot', [], params.Rrot);
T1.addExternalParameter('lambdaMax', [], params.lambdaMax);
T1.addExternalParameter('lambdaMin', [], params.lambdaMin);
T1.addExternalParameter('lambdaStep', [], params.lambdaStep);
T1.addExternalParameter('rho', [], params.rho);
T1.addExternalParameter('thetaMax', [], params.thetaMax);
T1.addExternalParameter('thetaMin', [], params.thetaMin);
T1.addExternalParameter('thetaStep', [], params.thetaStep);

T1.addOutput('tow_fa_acc', T1.dof.tow_fa_dd);
T1.addOutput('gen_speed', T1.dof.phi_rot_d*T1.params.GBRatio);
% just to preserve this state in the acados simulation
T1.addOutput('phi_rot', T1.dof.phi_rot);

T1.gravity(3) = -T1.params.g;

% Tower
tw_SID = SID(params.tw_sid, -1e-6, 'tower', T1);
tower= ElasticBody(T1.dof.tow_fa, tw_SID, 'tower');
T1.addChild(tower)

% Nacelle
nacelle = RigidBody('nacelle', [], T1.params.NacMass, diag([T1.params.NacXIner, T1.params.NacYIner, T1.params.NacZIner]));
nacelle.translate([T1.params.NacCMxn, T1.params.NacCMyn, T1.params.NacCMzn])
tower.addChild(nacelle)

% Hub
hub = RigidBody('hub', [], T1.params.HubMass, diag([T1.params.HubIner, T1.params.HubIner, T1.params.HubIner]));
hub.translate([T1.params.HubCM+T1.params.OverHang-T1.params.NacCMxn, -T1.params.NacCMyn, T1.params.Twr2Shft-T1.params.NacCMzn]);
hub.rotateLocalAxis('x', T1.dof.phi_rot)
nacelle.addChild(hub);

% Blades
for i = 1:3
    blade = RigidBody(sprintf('blade%d', i), [], T1.params.blade_mass, diag([T1.params.blade_I0_1_1, T1.params.blade_I0_2_2, T1.params.blade_I0_3_3]));
    blade.translate([-T1.params.HubCM, 0, 0]);
    % sym(2) is important to be able to simplify equations, use
    % MultiBodySystem access to sym to abstract MATLAB Symbolics and MAMaS
    blade.rotateLocalAxis('x', (i-1)*T1.sym(2)/3*T1.sym(pi))
    blade.rotateLocalAxis('z', T1.inputs.theta)
    blade.translate([0, 0, T1.params.blade_md0_3_1/T1.params.blade_mass]);
    hub.addChild(blade)
end


% Geno (effectively fixed to hub but with gear ratio)
geno = RigidBody('generator', [], 0, diag([T1.params.GenIner, 0, 0]));
geno.rotateLocalAxis('x', T1.dof.phi_rot*T1.params.GBRatio)
nacelle.addChild(geno)

% at least for forces given in local coordinates, the kinematic modeling
% must be completed
T1.completeSetup()

% Applied forces and moments
hub.applyForce([T1.externals.Fthrust, 0, 0].')
hub.applyMoment([T1.externals.Trot, 0, 0].')
geno.applyMoment([-T1.inputs.Tgen, 0, 0].')



