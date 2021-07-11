%% prepare paths
set_path

dn= fullfile('..', 'sim');
if ~exist(dn, 'dir')
    mkdir(dn);
end
dn= fullfile('..', 'sim', 'gen');
if ~exist(dn, 'dir')
    mkdir(dn);
end
    
%% make model
param= prepareModel('../5MW_Baseline/5MW_Land_IMP_6.fst', '../model/turbine_T2B2cG_aero.mac', '../sim/gen');

old_dir= pwd;
cd(dn)

system('g++ -g -std=c++17 -I. -I../../simulator -I../../../CADyn/src -Iturbine_T2B2cG_aero ../../../CADyn/src/ODEOrder2.cpp ../../../CADyn/src/IntegratorGNUPlotVisitor.cpp ../../simulator/turbine_T2B2cG_aero_sim.cpp -ldl -o turbine_T2B2cG_aero_sim')

%% simulate model
cd('..')
if isunix
    system('LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 gen/turbine_T2B2cG_aero_sim -p gen/params.txt  -d ../5MW_Baseline/DISCON.dll -w ../5MW_Baseline/NRELOffshrBsline5MW_InflowWind_IMP_12.dat -a 0.965 -t 150 -o simp_12.outb')
else
    system('gen/turbine_T2B2cG_aero_sim -p gen/params.txt  -d ../5MW_Baseline/DISCON.dll -w ../5MW_Baseline/NRELOffshrBsline5MW_InflowWind_IMP_12.dat -a 0.965 -t 150 -o simp_12.outb')
end


%% plot results
d= loadFAST('simp_12.outb');
plot_timeseries(d, {'RtVAvgxh', 'PtchPMzc', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'});

cd(old_dir)