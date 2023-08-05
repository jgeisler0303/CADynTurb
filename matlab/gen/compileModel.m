function compileModel(model_name, model_dir, gen_dir, files_to_generate, win_on_linux)

base_dir= fileparts(mfilename('fullpath'));

old_dir= pwd;
cleanupObj = onCleanup(@()cd(old_dir));
cd(gen_dir)

%% compile stand alone simulator
includes= ['-I' fullfile(fileparts(getenv('cagem_path')), '../src') ' -I' gen_dir ' -I' fullfile(base_dir, '../../simulator')];
if any(strcmp(files_to_generate, 'cpp_direct'))
    fprintf('Compiling standalone simulator\n')
    sim_cpp= fullfile(model_dir, ['sim_' model_name '.cpp']);
    out_name= fullfile(gen_dir, ['sim_' model_name]);
    
    if exist('win_on_linux', 'var') && win_on_linux
        system(['i686-w64-mingw32-g++ -g -std=c++17 -D _USE_MATH_DEFINES ', includes , ' ', sim_cpp, ' -o ' out_name]);
    else
        if isunix
            system(['g++ -g -std=c++17 ', includes , ' ', sim_cpp, ' -ldl -o ' out_name]);
        else
            system(['g++ -g -std=c++17 -D _USE_MATH_DEFINES ', includes, ' ', sim_cpp, ' -o ' out_name]);
        end
    end
end
if any(strcmp(files_to_generate, 'cpp_direct_gmres'))
    fprintf('Compiling GMRES standalone simulator\n')
    sim_cpp= fullfile(model_dir, ['sim_' model_name '_gmres.cpp']);
    out_name= fullfile(gen_dir, ['sim_' model_name '_gmres']);

    if exist('win_on_linux', 'var') && win_on_linux
        system(['i686-w64-mingw32-g++ -g -std=c++17 -D _USE_MATH_DEFINES ', includes , ' ', sim_cpp, ' -o ' out_name]);
    else
        if isunix
            system(['g++ -g -std=c++17 ', includes, ' ', sim_cpp, ' -ldl -o ' out_name]);
        else
            system(['g++ -g -std=c++17 -D _USE_MATH_DEFINES ', includes, ' ', sim_cpp, ' -o ' out_name]);
        end
    end
end

%% compile mex simulator
makeCADynMex(model_name, '.', '', '', fullfile(base_dir, '../../simulator'))