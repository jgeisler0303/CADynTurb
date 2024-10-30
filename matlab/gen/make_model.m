function [param, tw_sid, bd_sid]= make_model(model_name, model_dir, gen_dir, tower_modes, blade_modes, files_to_generate)

%% TODO: replace with makefile based approach
%% prepare paths
dn= fileparts(gen_dir);
if ~exist(dn, 'dir')
    mkdir(dn);
end
dn= gen_dir;
if ~exist(dn, 'dir')
    mkdir(dn);
end
if ~exist('files_to_generate', 'var')
    files_to_generate= {'cpp_direct'};
end

base_dir= fileparts(mfilename('fullpath'));

%% make model
[param, tw_sid, bd_sid]= prepareModel(fullfile(base_dir, '../../5MW_Baseline/5MW_Land_DLL_WTurb.fst'), [model_name '.mac'], gen_dir, tower_modes, blade_modes, files_to_generate);

%%
old_dir= pwd;
cleanupObj = onCleanup(@()cd(old_dir));
cd(gen_dir)

%% compile stand alone simulator
includes= ['-I' fullfile(fileparts(getenv('cagem_path')), '../src') ' -I' gen_dir ' -I' fullfile(base_dir, '../simulator')];
if any(strcmp(files_to_generate, 'cpp_direct'))
    % TODO: use compileProg?
    fprintf('Compiling standalone simulator\n')
    sim_cpp= fullfile(model_dir, ['sim_' model_name '.cpp']);
    out_name= fullfile(gen_dir, ['sim_' model_name]);

    if isunix
        system([getenv('CPP') ' -g -std=c++17 ', includes , ' ', sim_cpp, ' -ldl -o ' out_name]);
    else
        system([getenv('CPP') ' -g -std=c++17 -D _USE_MATH_DEFINES ', includes, ' ', sim_cpp, ' -o ' out_name]);
    end
end
if any(strcmp(files_to_generate, 'cpp_direct_gmres'))
    fprintf('Compiling GMRES standalone simulator\n')
    sim_cpp= fullfile(model_dir, ['sim_' model_name '_gmres.cpp']);
    out_name= fullfile(gen_dir, ['sim_' model_name '_gmres']);

    if isunix
        system([getenv('CPP') ' -g -std=c++17 ', includes, ' ', sim_cpp, ' -ldl -o ' out_name]);
    else
        system([getenv('CPP') ' -g -std=c++17 -D _USE_MATH_DEFINES ', includes, ' ', sim_cpp, ' -o ' out_name]);
    end
end

%% compile mex simulator
makeMex(model_name, '.')
