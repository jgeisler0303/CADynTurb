function out_name = compileMPC_DISCON(ocp_model, ocp_model_dir, ocp_gen_dir, ekf_gen_dir, CADynTurb_dir, win_on_linux, tracking)
if ~exist('win_on_linux', 'var')
    win_on_linux = false; % Default value if not provided
end
if ~exist('tracking', 'var')
    tracking = false; % Default value if not provided
end

% copy relevant files to gen_dir
prefix_name = strrep(ocp_model, '_opt', '_mpc');
copyfile(fullfile(ocp_model_dir, [prefix_name '_def.hpp']), ocp_gen_dir)
copyfile(fullfile(ocp_model_dir, [prefix_name '_params.hpp']), ocp_gen_dir)
if tracking
    MPC_source = 'DISCON_tracking_MPC.cpp';
    copyfile(fullfile(ocp_model_dir, 'calc_tracking_references.hpp'), ocp_gen_dir)
else
    MPC_source = 'DISCON_MPC.cpp';
end

sources= {
    fullfile(CADynTurb_dir, 'simulator', MPC_source)
    fullfile(ocp_gen_dir, 'c_generated_code', ['acados_solver_' ocp_model '_acados.c'])
    };

if tracking
    out_name= ['DISCON_' strrep(ocp_model, '_opt', '') '_tracking_MPC.dll'];
else
    out_name= ['DISCON_' strrep(ocp_model, '_opt', '') '_MPC.dll'];
end

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
    getenv('EIGEN3')
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
    };

if isunix
    flags{end+1} = ['-Wl,--disable-new-dtags,-rpath,\$ORIGIN,-rpath,' fullfile(getenv('ACADOS_INSTALL_DIR'), 'lib')];
end

compileProg(sources, out_name, dependencies, defines, includes, lib_dirs, libs, flags, win_on_linux);

if isunix
    lib_name = ['libacados_ocp_solver_' ocp_model '_acados.so'];
else
    lib_name = ['acados_ocp_solver_' ocp_model '_acados.dll'];
end    
copyfile(fullfile('./c_generated_code', lib_name), ocp_gen_dir)

