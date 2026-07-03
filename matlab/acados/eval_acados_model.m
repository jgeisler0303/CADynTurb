function [f, y, extra_val] = eval_acados_model(model, x, xdot, u, ap, extra)
N = size(x, 2);
ap = repmat(ap, 1, N);

f_impl_expr=casadi.Function('f_impl_expr', {model.x, model.xdot, model.u, model.p}, {model.f_impl_expr});
f_impl_expr_map = f_impl_expr.map(N);

f= full(f_impl_expr_map(x, xdot, u, ap));

cost_y_expr=casadi.Function('cost_y_expr', {model.x, model.u, model.p}, {model.cost_y_expr});
cost_y_expr_map = cost_y_expr.map(N);
y= full(cost_y_expr_map(x, u, ap));

fn = fieldnames(extra);
for i = 1:length(fn)
    extra_fun=casadi.Function(fn{i}, {model.x, model.u, model.p}, {extra.(fn{i})});
    extra_fun_map = extra_fun.map(N);
    extra_val.(fn{i}) = full(extra_fun_map(x, u, ap));
end