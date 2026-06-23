% cost
omgen= casadi.MX.sym('omgen', 1);
sym_p= casadi.MX.sym('sym_p', 1);
vwind= sym_p(1);

w= ones(1, 9);
w(2)= 1e-2;
[multi_cost, theta_min]= eco_multi_cost(param, sym_p, vwind, param.GBRatio, param.Rrot, omgen/param.GBRatio, 0, 0, 0, 0, 0, param.rho, param.rpm_max, param.power_max/(param.rpm_max/30*pi), w);


%%
cost_cp_rpm_fun = casadi.Function('cost_cp_rpm_fun', {omgen, sym_p}, {multi_cost.eco, multi_cost.rpm_max});

%%
rpm_l= param.rpm_min * 0.9;
rpm_u= param.rpm_max * 1.1;
RPM= linspace(rpm_l, rpm_u, 50);

n_wind= 7;
VWIND= linspace(4, 10, n_wind);
colors= jet(n_wind);

clf
hold on
for i= 1:n_wind
    plot_eco_cost_wind(cost_cp_rpm_fun, VWIND(i), RPM, colors(i, :), sprintf('v=%.1f', VWIND(i)))
end
xline(param.rpm_max, 'k', LineWidth=2)

grid on
legend
xlabel('Gen. speed in rpm')
ylabel('Cost value')


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