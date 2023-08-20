function compileModel(model_name, model_dir, gen_dir, files_to_generate, win_on_linux)

if ~exist('win_on_linux', 'var')
    win_on_linux= false;
end

base_dir= fileparts(mfilename('fullpath'));

old_dir= pwd;
cleanupObj = onCleanup(@()cd(old_dir));
cd(gen_dir)

%% compile stand alone simulator
includes= ['-I' fullfile(fileparts(getenv('cagem_path')), '../src') ' -I' gen_dir ' -I' fullfile(base_dir, '../../simulator')];
if any(strcmp(files_to_generate, 'cpp_direct'))
    sim_cpp= fullfile(model_dir, ['sim_' model_name '.cpp']);
    out_name= fullfile(gen_dir, ['sim_' model_name]);
    dependencies= {
        [model_name '_direct.hpp']
        [model_name '_param.hpp']
        fullfile(fileparts(getenv('cagem_path')), '../src/NewmarkBeta.hpp')
        };
    
    compileProg(sim_cpp, out_name, dependencies, {}, includes, {}, {}, {}, win_on_linux)
end
if any(strcmp(files_to_generate, 'cpp_direct_gmres'))
    sim_cpp= fullfile(model_dir, ['sim_' model_name '_gmres.cpp']);
    out_name= fullfile(gen_dir, ['sim_' model_name '_gmres']);
    dependencies= {
        [model_name '_gmres.hpp']
        [model_name '_param.hpp']
        fullfile(fileparts(getenv('cagem_path')), '../src/NewmarkBeta_gmres.hpp')
        };

    compileProg(sim_cpp, out_name, dependencies, {}, includes, {}, {}, {}, win_on_linux)
end

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