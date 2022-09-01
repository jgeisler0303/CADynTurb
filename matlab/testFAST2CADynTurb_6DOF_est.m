%% prepare paths
set_path

model_name= 'turbine_T2B2cG_aero_est';
model_dir= '../sim/gen_est';

dn= fileparts(model_dir);
if ~exist(dn, 'dir')
    mkdir(dn);
end
dn= model_dir;
if ~exist(dn, 'dir')
    mkdir(dn);
end
    
%% make model
clc
param= prepareModel('../5MW_Baseline/5MW_Land_IMP_6.fst', ['../model/' model_name '.mac'], model_dir);

%%
old_dir= pwd;
cleanupObj = onCleanup(@()cd(old_dir));
cd(model_dir)

%%
clc
makeMex('turbine_T2B2cG_aero_est', '.')

%% simulate mex model
d_in= collectBlades(loadFAST('/home/jgeisler/Temp/CADynTurb/sim/generated/sim_no_inflow/impulse_URef-12_maininput.outb'));

d_out= sim_turbine_T2B2cG_aero_est(d_in, param);

%% plot results
plot_timeseries_cmp(d_in, d_out, {'RtVAvgxh', 'PtchPMzc', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'});

%%
cd(old_dir)