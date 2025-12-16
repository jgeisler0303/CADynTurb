function sim_solver= make_acados_sim(param, model_name, gen_dir, sim_opts)
cd(gen_dir)
acados_model_func= str2func([model_name '_acados']);
model= acados_model_func(param);
% [~, ~]= mkdir('c_generated_code');
% copy_acados_libs(fullfile(gen_dir, 'c_generated_code'))

sim = AcadosSim();
sim.model = model;

if exist('sim_opts', 'var')
    sim.solver_options= sim_opts;
else
    sim.solver_options.Tsim = 0.01; % simulation time
    sim.solver_options.integrator_type = 'IRK';
end

%% create integrator
sim_solver = AcadosSimSolver(sim);
sim_solver.sim.model= model;

