function plot_eco_cost(ocp_solver, param, parameter_names, phi_rot_d_idx)

n= ocp_solver.ocp.solver_options.N_horizon;
nx= length(ocp_solver.ocp.model.x);
nu= length(ocp_solver.ocp.model.u);
x= zeros(nx, n+1);
u= zeros(nu, n);

w= param.w_cost;

rpm_l= param.rpm_min * 0.9;
rpm_u= param.rpm_max * 1.1;
RPM= linspace(rpm_l, rpm_u, n-1);
x(phi_rot_d_idx, 2:end-1)= RPM/param.GBRatio/30*pi;

n_wind= 10;
VWIND= linspace(3, 15, n_wind);
colors= jet(n_wind);

clf
tiledlayout(3, 1)
nexttile
hold on
for i= 1:n_wind
    plot_eco_cost_wind(VWIND(i), colors(i, :), RPM, ocp_solver, param, parameter_names, x, u)
end
grid on
xlabel('Gen. speed in rpm')
ylabel('Cost value')

nexttile
x= zeros(nx, n+1);
trq_l= 0;
trq_u= param.power_max/(param.rpm_max/30*pi) *1.2;
TRQ= linspace(trq_l, trq_u, n-1);
x(2, 2:end-1)= TRQ;
[xs, ys]= calc_cp_max_spline(param);
hold on
for i= 1:n_wind
    param.vwind= VWIND(i);
    param.w_cost(:)= 0;
    param.w_cost(4)= w(4);

    Pwind= 0.5*param.rho*param.Arot*param.vwind^3;
    om_rot_max= param.rpm_max/30*pi/param.GBRatio;
    Pmech= Pwind*spline(xs, ys, om_rot_max*param.Rrot/param.vwind);
    rated_operation= 0.5*(1+tanh(((Pmech-param.power_max)/param.power_max*100-10)*2/10));
    trq_set= param.power_max/(om_rot_max*param.GBRatio);
    multi_cost_trq=  w(4) * rated_operation * ((TRQ-trq_set)/trq_set).^2; % Maybe add pitch dependent offset

    c_trq= acados_stage_cost(ocp_solver, param, parameter_names, x, u);
    
    plot(TRQ, c_trq(2:end-1), '-', 'Color', colors(i, :))  
    plot(TRQ, multi_cost_trq, ':', 'Color', colors(i, :))  
end
grid on
xlabel('Gen. Torque in Nm')
ylabel('Cost value')


nexttile
x= zeros(nx, n+1);
pit_l= 0;
pit_u= 20;
PIT= linspace(pit_l, pit_u, n-1);
x(3, 2:end-1)= -PIT/180*pi;
hold on
for i= 1:n_wind
    param.vwind= VWIND(i);
    param.w_cost(:)= 0;
    param.w_cost(3)= w(3);

    Pwind= 0.5*param.rho*param.Arot*param.vwind^3;
    om_rot_max= param.rpm_max/30*pi/param.GBRatio;
    Pmech= Pwind*spline(xs, ys, om_rot_max*param.Rrot/param.vwind);
    rated_operation= 0.5*(1+tanh(((Pmech-param.power_max)/param.power_max*100-10)*2/10));
    pit_min= 0;
    multi_cost_theta= w(3) * (1-rated_operation) * (-PIT/180*pi-pit_min).^2; % Maybe add torque dependent offset

    c_pit= acados_stage_cost(ocp_solver, param, parameter_names, x, u);
    
    plot(PIT, c_pit(2:end-1), '-', 'Color', colors(i, :))    
    plot(PIT, multi_cost_theta, ':', 'Color', colors(i, :))    
end
grid on
xlabel('Pitch in °')
ylabel('Cost value')

function plot_eco_cost_wind(vwind, color, RPM, ocp_solver, param, parameter_names, x, u)
param.vwind= vwind;
w= param.w_cost;
param.w_cost(:)= 0;

param.w_cost(1)= w(1);
c_cp= acados_stage_cost(ocp_solver, param, parameter_names, x, u);
min_cp= min(c_cp(2:end-1));
% param.w_cost(:)= 0; param.w_cost(2)= w(2);
% c_rpm= acados_stage_cost(ocp_solver, param, parameter_names, x, u);
param.w_cost(1:2)= w(1:2);
c_eco= acados_stage_cost(ocp_solver, param, parameter_names, x, u);

% plot(RPM, c_cp(2:end-1), ':b', RPM, c_rpm(2:end-1), '-.b', RPM, c_eco(2:end-1), '-b')
plot(RPM, c_cp(2:end-1), ':', 'Color', color)
plot(RPM, c_eco(2:end-1), '-', 'Color', color)
