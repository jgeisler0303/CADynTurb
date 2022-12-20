function [param, tw_sid, bd_sid]= make_model(model_name, model_dir, tower_modes, blade_modes)

%% prepare paths
dn= fileparts(model_dir);
if ~exist(dn, 'dir')
    mkdir(dn);
end
dn= model_dir;
if ~exist(dn, 'dir')
    mkdir(dn);
end

%% make model
[param, tw_sid, bd_sid]= prepareModel('../5MW_Baseline/5MW_Land_IMP_6.fst', ['../model/' model_name '.mac'], model_dir, tower_modes, blade_modes);

%%
old_dir= pwd;
cleanupObj = onCleanup(@()cd(old_dir));
cd(model_dir)

%% compile stand alone simulator
fprintf('Compiling standalone simulator\n')
if isunix
    system(['g++ -g -std=c++17 -I. -I../../simulator -I../../../CADyn/src ../../simulator/' model_name '_sim.cpp -ldl -o ' model_name '_sim']);
else
    system(['g++ -g -std=c++17 -D _USE_MATH_DEFINES -I. -I../../simulator -I../../../CADyn/src ../../simulator/' model_name '_sim.cpp -o ' model_name '_sim']);
end

%% compile mex simulator
makeMex(model_name, '.')
