function sim_solver= make_acados_sim(model_name, gen_dir, sim_opts)
cd(gen_dir)
acados_model_func= str2func([model_name '_acados']);
model= acados_model_func();
% [~, ~]= mkdir('c_generated_code');
% copy_acados_libs(fullfile(gen_dir, 'c_generated_code'))

sim = AcadosSim();
sim.model = model;
sim.solver_options.Tsim = 0.01; % simulation time
sim.solver_options.integrator_type = 'IRK';

% if ~exist('sim_opts', 'var')
%     sim_opts = acados_sim_opts();
%     sim_opts.set('compile_interface', 'auto');
%     sim_opts.set('num_stages', 2);
%     sim_opts.set('num_steps', 1);
%     sim_opts.set('newton_iter', 2);
%     sim_opts.set('method', 'irk');
%     sim_opts.set('sens_forw', 'true');
% end

%% create integrator
sim_solver = AcadosSimSolver(sim);

