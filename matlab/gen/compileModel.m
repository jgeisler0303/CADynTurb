function compileModel(model_name, model_dir, gen_dir, files_to_generate, win_on_linux)

if ~exist('win_on_linux', 'var')
    win_on_linux= false;
end

base_dir= fileparts(mfilename('fullpath'));

old_dir= pwd;
cleanupObj = onCleanup(@()cd(old_dir));
cd(gen_dir)

includes= ['-I' fullfile(fileparts(getenv('cagem_path')), '../src') ' -I' gen_dir ' -I' fullfile(base_dir, '../../simulator') '-I' getenv('EIGEN3')];
if any(strcmp(files_to_generate, '_direct.hpp'))
    % compile stand alone simulator
    sim_cpp= fullfile(base_dir, ['../../simulator/standalone_simulator.cpp']);
    out_name= fullfile(gen_dir, ['sim_' model_name]);
    dependencies= {
        [model_name '_direct.hpp']
        [model_name '_param.hpp']
        fullfile(fileparts(getenv('cagem_path')), '../src/NewmarkBeta.hpp')
        };
    defines= {['MODEL_NAME=' model_name]};

    compileProg(sim_cpp, out_name, dependencies, defines, includes, {}, {}, {}, win_on_linux)

    %% compile mex simulator
    dependencies= {
        [model_name '_direct.hpp']
        [model_name '_param.hpp']
        fullfile(fileparts(getenv('cagem_path')), '../src/NewmarkBeta.hpp')
        fullfile(fileparts(getenv('cagem_path')), '../src/CADyn_mex.cpp')
        };
    if recompile([model_name '_mex.' mexext], dependencies)
        fprintf('Compiling mex simulator\n')
        makeCADynMex(model_name, '.', '', '', fullfile(base_dir, '../../simulator'))
    else
        fprintf('Skipping compilation of mex simulator\n')
    end    
end

if any(strcmp(files_to_generate, '_descriptor_form.hpp'))
    dependencies= {
        [model_name '_descriptor_form.hpp']
        [model_name '_param.hpp']
        fullfile(fileparts(getenv('cagem_path')), '../src/CADyn_descriptor_mex.cpp')
        };
    if recompile([model_name '_descriptor_mex.' mexext], dependencies)
        fprintf('Compiling mex simulator\n')
        makeCADynMex(model_name, '.', 'CADyn_descriptor_mex.cpp', [model_name '_descriptor_mex'], fullfile(base_dir, '../../simulator'))
    else
        fprintf('Skipping compilation of mex simulator\n')
    end    
end

if any(strcmp(files_to_generate, '_direct_gmres.hpp'))
    sim_cpp= fullfile(model_dir, ['sim_' model_name '_gmres.cpp']);
    out_name= fullfile(gen_dir, ['sim_' model_name '_gmres']);
    dependencies= {
        [model_name '_gmres.hpp']
        [model_name '_param.hpp']
        fullfile(fileparts(getenv('cagem_path')), '../src/NewmarkBeta_gmres.hpp')
        };

    compileProg(sim_cpp, out_name, dependencies, {}, includes, {}, {}, {}, win_on_linux)
end
