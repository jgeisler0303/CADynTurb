function compileAcados(model_name, model_dir, gen_dir, win_on_linux)

if ~exist('win_on_linux', 'var')
    win_on_linux= false;
end

base_dir= fileparts(mfilename('fullpath'));

old_dir= pwd;
cleanupObj = onCleanup(@()cd(old_dir));
cd(gen_dir)

%% compile stand alone simulator
includes= {
    model_dir
    '.'
    fullfile(base_dir, '../../simulator')
    fullfile(base_dir, '../../../CADyn/src')
    'c_generated_code'
    fullfile(getenv('ACADOS_INSTALL_DIR'), 'include')
    fullfile(getenv('ACADOS_INSTALL_DIR'), 'include/blasfeo/include')
    fullfile(getenv('ACADOS_INSTALL_DIR'), 'include/hpipm/include')
    };

sources= {
    fullfile(model_dir, ['sim_' model_name '_acados.cpp']);
    fullfile('c_generated_code', ['acados_sim_solver_' model_name '_acados.c'])
    fullfile('c_generated_code', [model_name '_acados_model'], [model_name '_acados_impl_dae_fun_jac_x_xdot_u.c'])
    fullfile('c_generated_code', [model_name '_acados_model'], [model_name '_acados_impl_dae_fun_jac_x_xdot_z.c'])
    fullfile('c_generated_code', [model_name '_acados_model'], [model_name '_acados_impl_dae_fun.c'])
    % fullfile('c_generated_code', [model_name '_acados_model'], [model_name '_acados_impl_dae_hess.c'])
    fullfile('c_generated_code', [model_name '_acados_model'], [model_name '_acados_impl_dae_jac_x_xdot_u_z.c'])
    };

lib_dirs= {
    fullfile(getenv('ACADOS_INSTALL_DIR'), 'lib')
    };

libs= {
    'acados'
    'blasfeo'
    'hpipm'
    };

if ispc
    flags= '-fpermissive -g -std=c++17';
else
    flags= ['-fpermissive -g -std=c++17 -Wl,--disable-new-dtags,-rpath,' getenv('ACADOS_INSTALL_DIR') '/lib'];
end

out_name= fullfile(gen_dir, ['sim_' model_name '_acados']);

compileProg(sources, out_name, {}, '', includes, lib_dirs, libs, flags, win_on_linux)
