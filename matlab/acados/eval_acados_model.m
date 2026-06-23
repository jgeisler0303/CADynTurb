function [f, y] = eval_acados_model(model, x, xdot, u, ap)
f_impl_expr=casadi.Function('f_impl_expr', {model.x, model.xdot, model.u, model.p}, {model.f_impl_expr});
f= full(f_impl_expr(x, xdot, u, ap));

cost_y_expr=casadi.Function('cost_y_expr', {model.x, model.u, model.p}, {model.cost_y_expr});
y= full(cost_y_expr(x, u, ap));
