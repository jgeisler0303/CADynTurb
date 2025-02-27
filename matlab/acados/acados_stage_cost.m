function c= acados_stage_cost(ocp_solver, param, parameter_names, x, u)

n= ocp_solver.ocp.solver_options.N_horizon;

param0= param;
param0.w_cost(:)= 0;
ap= acados_params(parameter_names, param);
ap0= acados_params(parameter_names, param0);

ocp_solver.set('init_x', x);
ocp_solver.set('init_u', u);

c= zeros(n+1, 1);
for i= 1:n+1
    ocp_solver.set('p', ap0);
    ocp_solver.set('p', ap, i-1);

    c(i)= ocp_solver.get_cost;
end