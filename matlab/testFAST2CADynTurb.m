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
param= prepareModel('../5MW_Baseline/5MW_Land_IMP_6.fst', ['../model/' model_name '.mac'], model_dir);

%%
old_dir= pwd;
cleanupObj = onCleanup(@()cd(old_dir));
cd(model_dir)

%% compile stand alone simulator
if isunix
    system(['g++ -g -std=c++17 -I. -I../../simulator -I../../../CADyn/src ../../simulator/' model_name '_sim.cpp -ldl -o ' model_name '_sim'])
else
    system(['g++ -g -std=c++17 -D _USE_MATH_DEFINES -I. -I../../simulator -I../../../CADyn/src ../../simulator/' model_name '_sim.cpp -o ' model_name '_sim'])
end

%% simulate stand alone model

sim_command= [model_name '_sim -a 0.965 -o simp_12_6DOF.outb ../../5MW_Baseline/5MW_Land_IMP_12.fst'];
if isunix
    system(['LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 ./' sim_command])
else
    system(['set path=' getenv('PATH') ' & ' sim_command])
end
d1= loadFAST('simp_12_6DOF.outb');

%% compile mex simulator
makeMex(model_name, '.')

%%
plot_timeseries(d1, {'RtVAvgxh', 'PtchPMzc', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'});

%%
cd(old_dir)
