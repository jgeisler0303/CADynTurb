function compileMPC_DISCON(ocp_model, ocp_gen_dir, ekf_gen_dir, CADynTurb_dir, win_on_linux)

sources= {
    fullfile(CADynTurb_dir, 'simulator', 'DISCON_MPC.cpp')
    fullfile(ocp_gen_dir, 'c_generated_code', ['acados_solver_' ocp_model '_acados.c'])
    };

out_name= ['DISCON_' strrep(ocp_model, '_opt', '') '_MPC.dll'];

dependencies= {};

defines= {['MPC_DEF=' strrep(ocp_model, '_opt', '_mpc_def.hpp')]};
if ~exist('win_on_linux', 'var')
    win_on_linux= false;
end

includes= {
    ocp_gen_dir
    fullfile(ocp_gen_dir, 'c_generated_code')
    ekf_gen_dir
    fullfile(CADynTurb_dir, 'simulator')
    fullfile(CADynTurb_dir, '..', 'CADyn', 'src')
    fullfile(getenv('ACADOS_INSTALL_DIR'), 'include')
    fullfile(getenv('ACADOS_INSTALL_DIR'), 'include', 'blasfeo', 'include')
    fullfile(getenv('ACADOS_INSTALL_DIR'), 'include', 'hpipm', 'include')

    };
lib_dirs= {
    fullfile(getenv('ACADOS_INSTALL_DIR'), 'lib')
    fullfile(ocp_gen_dir, 'c_generated_code')
    };

libs= {
    'acados'
    'hpipm'
    'blasfeo'
    ['acados_ocp_solver_' ocp_model '_acados']
    };

flags= {
    '-std=c++17'
    '-shared'
    '-fpermissive'
    '-fPIC'
    ['-Wl,--disable-new-dtags,-rpath,\$ORIGIN,-rpath,' fullfile(getenv('ACADOS_INSTALL_DIR'), 'lib')]
    };

compileProg(sources, out_name, dependencies, defines, includes, lib_dirs, libs, flags, win_on_linux);