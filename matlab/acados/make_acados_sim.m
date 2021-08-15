function as= make_acados_sim(model, sim_opts)

sim_model = acados_sim_model();
sim_model.set('name', 'T2B2cG_aero');
sim_model.set('T', 0.01);
sim_model.set('sym_x', model.sym_x);
sim_model.set('sym_u', model.sym_u);
sim_model.set('sym_p', model.sym_p)
sim_model.set('dyn_type', 'implicit');
sim_model.set('dyn_expr_f', model.expr_f_impl);
sim_model.set('sym_xdot', model.sym_xdot);

if ~exist('sim_opts', 'var')
    sim_opts = acados_sim_opts();
    sim_opts.set('compile_interface', 'auto');
    sim_opts.set('num_stages', 2);
    sim_opts.set('num_steps', 1);
    sim_opts.set('newton_iter', 2);
    sim_opts.set('method', 'irk');
    sim_opts.set('sens_forw', 'true');
end

as = acados_sim(sim_model, sim_opts);