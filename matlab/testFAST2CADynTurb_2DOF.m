%% prepare paths
set_path

dn= fullfile('..', 'sim');
if ~exist(dn, 'dir')
    mkdir(dn);
end
dn= fullfile('..', 'sim', 'gen2');
if ~exist(dn, 'dir')
    mkdir(dn);
end
    
%% make model
param= prepareModel('../5MW_Baseline/5MW_Land_IMP_6.fst', '../model/turbine_T1_aero.mac', '../sim/gen2', {[1 -2]}, 1);

%%
old_dir= pwd;
cleanupObj = onCleanup(@()cd(old_dir));
cd(dn)

system('g++ -g -std=c++17 -I. -I../../simulator -I../../../CADyn/src -Iturbine_T1_aero ../../../CADyn/src/ODEOrder2.cpp ../../../CADyn/src/IntegratorGNUPlotVisitor.cpp ../../simulator/turbine_T1_aero_sim.cpp -ldl -o turbine_T1_aero_sim')

%% simulate model
cd('..')
sim_command= 'gen2/turbine_T1_aero_sim -p gen2/params.txt  -a 0.965 -o simp_12_2DOF.outb ../5MW_Baseline/5MW_Land_IMP_12.fst';
if isunix
    system(['LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 ' sim_command])
else
    system(sim_command)
end


%% plot results
d= loadFAST('simp_12_2DOF.outb');
plot_timeseries(d, {'RtVAvgxh', 'PtchPMzc', 'LSSTipVxa', 'GenTq', 'YawBrTDxp'});

cd(old_dir)