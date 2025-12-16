% cost
model_fixed_params
controller_param

load('cp_tab')
param.rpm_max= 1452;
param.GBRatio= p.GearRatio;
param.Rrot= Rrot;
param.cp= cp_tab.cp';
param.lambda= cp_tab.lam;
param.theta= cp_tab.th;

omgen= casadi.MX.sym('omgen', 1);
sym_p= casadi.MX.sym('sym_p', 1);
vwind= sym_p(1);

rated_rpm= 1452;
rated_power= 3430e3;
rated_torque= rated_power/(rated_rpm/30*pi);
rho= 1.225;

w= ones(1, 9);
w(2)= 1e-2;
[multi_cost, theta_min]= eco_multi_cost(param, sym_p, vwind, p.GearRatio, Rrot, omgen/p.GearRatio, 0, 0, 0, 0, 0, rho, rated_rpm, rated_torque, w);


%%
cost_cp_rpm_fun = casadi.Function('cost_cp_rpm_fun', {omgen, sym_p}, {multi_cost.eco, multi_cost.rpm_max});

%%
rpm_l= 800 * 0.9;
rpm_u= rated_rpm * 1.1;
RPM= linspace(rpm_l, rpm_u, 50);

n_wind= 7;
VWIND= linspace(4, 10, n_wind);
colors= jet(n_wind);

clf
% tiledlayout(3, 1)
% nexttile
hold on
for i= 1:n_wind
    plot_eco_cost_wind(cost_cp_rpm_fun, VWIND(i), RPM, colors(i, :), sprintf('v=%.1f', VWIND(i)))
end
xline(rated_rpm, 'k', LineWidth=2)

grid on
legend
xlabel('Gen. speed in rpm')
ylabel('Cost value')

% nexttile
% x= zeros(nx, n+1);
% trq_l= 0;
% trq_u= param.power_max/(param.rpm_max/30*pi) *1.2;
% TRQ= linspace(trq_l, trq_u, n-1);
% x(2, 2:end-1)= TRQ;
% [xs, ys]= calc_cp_max_spline(param);
% hold on
% for i= 1:n_wind
%     param.vwind= VWIND(i);
%     param.w_cost(:)= 0;
%     param.w_cost(4)= w(4);
% 
%     Pwind= 0.5*param.rho*param.Arot*param.vwind^3;
%     om_rot_max= param.rpm_max/30*pi/param.GBRatio;
%     Pmech= Pwind*spline(xs, ys, om_rot_max*param.Rrot/param.vwind);
%     rated_operation= 0.5*(1+tanh(((Pmech-param.power_max)/param.power_max*100-10)*2/10));
%     trq_set= param.power_max/(om_rot_max*param.GBRatio);
%     multi_cost_trq=  w(4) * rated_operation * ((TRQ-trq_set)/trq_set).^2; % Maybe add pitch dependent offset
% 
%     c_trq= acados_stage_cost(ocp_solver, param, parameter_names, x, u);
% 
%     plot(TRQ, c_trq(2:end-1), '-', 'Color', colors(i, :))  
%     plot(TRQ, multi_cost_trq, ':', 'Color', colors(i, :))  
% end
% grid on
% xlabel('Gen. Torque in Nm')
% ylabel('Cost value')
% 
% 
% nexttile
% x= zeros(nx, n+1);
% pit_l= 0;
% pit_u= 20;
% PIT= linspace(pit_l, pit_u, n-1);
% x(3, 2:end-1)= -PIT/180*pi;
% hold on
% for i= 1:n_wind
%     param.vwind= VWIND(i);
%     param.w_cost(:)= 0;
%     param.w_cost(3)= w(3);
% 
%     Pwind= 0.5*param.rho*param.Arot*param.vwind^3;
%     om_rot_max= param.rpm_max/30*pi/param.GBRatio;
%     Pmech= Pwind*spline(xs, ys, om_rot_max*param.Rrot/param.vwind);
%     rated_operation= 0.5*(1+tanh(((Pmech-param.power_max)/param.power_max*100-10)*2/10));
%     pit_min= 0;
%     multi_cost_theta= w(3) * (1-rated_operation) * (-PIT/180*pi-pit_min).^2; % Maybe add torque dependent offset
% 
%     c_pit= acados_stage_cost(ocp_solver, param, parameter_names, x, u);
% 
%     plot(PIT, c_pit(2:end-1), '-', 'Color', colors(i, :))    
%     plot(PIT, multi_cost_theta, ':', 'Color', colors(i, :))    
% end
% grid on
% xlabel('Pitch in °')
% ylabel('Cost value')

function plot_eco_cost_wind(cost_cp_rpm_fun, vwind, RPM, color, name)
c_cp= RPM*0;
c_rpm= RPM*0;
for i= 1:length(RPM)
    [cost_cp, cost_rpm]= cost_cp_rpm_fun(RPM(i)/30*pi, vwind);
    c_cp(i)= full(cost_cp.evalf);
    c_rpm(i)= full(cost_rpm.evalf);
end

plot(RPM, c_cp, '-', 'Color', color, DisplayName=name)
plot(RPM, c_cp+c_rpm, ':', 'Color', color, HandleVisibility='off')
end