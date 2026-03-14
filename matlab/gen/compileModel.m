function compileModel(model_name, model_dir, gen_dir, files_to_generate, win_on_linux)

if ~exist('win_on_linux', 'var')
    win_on_linux= false;
end

base_dir= fileparts(mfilename('fullpath'));

old_dir= pwd;
cleanupObj = onCleanup(@()cd(old_dir));
cd(gen_dir)

includes= ['-I' fullfile(fileparts(getenv('cagem_path')), '../src') ' -I' gen_dir ' -I' fullfile(base_dir, '../../simulator') ' -I' getenv('EIGEN3')];
if any(strcmp(files_to_generate, '_direct.hpp'))
    fprintf('Newmark beta Form\n')
    dependencies= {
        [model_name '_direct.hpp']
        [model_name '_param.hpp']
        };

    % compile stand alone simulator
    compileStandalone( ...
        fullfile(gen_dir, ['sim_' model_name]), ...
        model_name, includes, ...
        [dependencies; {fullfile(fileparts(getenv('cagem_path')), '../src/NewmarkBeta.hpp')}], ...
        fullfile(base_dir, '../../simulator/standalone_simulator.cpp'), ...
        win_on_linux)

    %% compile mex simulator
    compileMexSimulator( ...
        [model_name '_mex'], ...
        model_name, ...
        fullfile(base_dir, '../../simulator'), ...
        [dependencies; {fullfile(fileparts(getenv('cagem_path')), '../src/NewmarkBeta.hpp')}], ...
        fullfile(fileparts(getenv('cagem_path')), '../src/CADyn_mex.cpp'))

    % compile EKF
    if endsWith(model_name, '_est')
        compileMexEKF(model_name, model_dir, gen_dir, dependencies, base_dir)
    end
end

if any(strcmp(files_to_generate, '_ode1.hpp'))
    fprintf('ODE1 Form\n')
    dependencies= {
        [model_name '_ode1.hpp']
        [model_name '_param.hpp']
        };

    % compile stand alone simulator
    compileStandalone( ...
        fullfile(gen_dir, ['sim_' model_name '_RK1']), ...
        model_name, includes, ...
        [dependencies; {fullfile(fileparts(getenv('cagem_path')), '../src/RK1condensed.hpp')}], ...
        fullfile(base_dir, '../../simulator/standalone_simulator_RK1.cpp'), ...
        win_on_linux)

    %% compile mex simulator
    compileMexSimulator( ...
        [model_name '_RK1_mex'], ...
        model_name, ...
        fullfile(base_dir, '../../simulator'), ...
        [dependencies; {fullfile(fileparts(getenv('cagem_path')), '../src/RK1condensed.hpp')}], ...
        fullfile(fileparts(getenv('cagem_path')), '../src/CADyn_RK1condensed_mex.cpp'))

    % compile EKF
    if endsWith(model_name, '_est')
        compileMexEKF([model_name '_RK1'], model_dir, gen_dir, dependencies, base_dir)
    end
end

if any(strcmp(files_to_generate, '_descriptor_form.hpp'))
    fprintf('Descriptor Form\n')
    dependencies= {
        [model_name '_descriptor_form.hpp']
        [model_name '_param.hpp']
        };
    compileMexSimulator( ...
        [model_name '_descriptor_mex'], ...
        model_name, ...
        fullfile(base_dir, '../../simulator'), ...
        dependencies, ...
        fullfile(fileparts(getenv('cagem_path')), '../src/CADyn_descriptor_mex.cpp'))
end
end

function compileStandalone(out_name, model_name, includes, dependencies, sim_cpp, win_on_linux)
defines= {['MODEL_NAME=' model_name]};
if ~endsWith(model_name, '_est') && recompile([model_name '_mex.' mexext], [dependencies sim_cpp])
    fprintf('Compiling standalone simulator\n')
    compileProg(sim_cpp, out_name, dependencies, defines, includes, {}, {}, {}, win_on_linux)
else
    fprintf('Skipping compilation of standalone simulator\n')
end
end

function compileMexSimulator(out_name, model_name, includes, dependencies, mex_cpp)
if recompile([out_name '.' mexext], [dependencies(:)' {mex_cpp}])
    fprintf('Compiling mex simulator\n')
    makeCADynMex(model_name, '.', mex_cpp, out_name, includes)
else
    fprintf('Skipping compilation of mex simulator\n')
end    
end

function compileMexEKF(model_name, model_dir, gen_dir, dependencies, base_dir)
if endsWith(model_name, '_RK1')
    mex_cpp = fullfile(base_dir, '../../../CADyn/src/CADynEKF_RK1_mex.cpp');
else
    mex_cpp = fullfile(gen_dir, [model_name '_ekf_mex.cpp']);
end
if recompile([model_name '_ekf_mex.' mexext], [dependencies(:)' {mex_cpp}])
    makeCADynEKFMex(model_name, model_dir, gen_dir)
end    
end