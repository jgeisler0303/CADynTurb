%% prepare paths
set_path

model_name= 'turbine_T2B2cG_aero_est_bld_mom';
model_dir= '../sim/gen_est_bld_mom';

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

%% compile mex simulator
clc
makeMex(model_name, '.')

%% simulate mex model
d_in= collectBlades(loadFAST('/home/jgeisler/Temp/CADynTurb/sim/generated/sim_no_inflow/impulse_URef-12_maininput.outb'));

d_out= sim_turbine_T2B2cG_aero_est_bld_mom(d_in, param);

%% plot results
plot_timeseries_cmp(d_in, d_out, {'RtVAvgxh', 'PtchPMzc', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'RootMxb', 'RootMyb'});

%% setup reference simulations
% fo the next commnd you nedd the AMPoWS repo in your path
openFAST_preprocessor('../openFAST_config_dyn_inflow.xlsx');
system('make -j -i 1p1')
dd= dir('../generated/wind/NTM_URef-*_turbsim.bts');
makeCoherentBTS(fullfile('../generated/wind', {dd.name}), 63)

%%
load('params.mat')

%%
sim_dir= '../generated/sim_no_inflow';
wind_dir= '../generated/wind';
file_pattern= '1p1*_maininput.outb';

dd= dir(fullfile(sim_dir, file_pattern));
files= {dd.name};

vv= zeros(length(files), 1);
for i= 1:length(files)
    v_str= regexp(files{i}, 'URef-(\d+)_', 'tokens', 'once');
    vv(i)= str2double(v_str{1});
end

%% run Kalman filter
for i= 1:length(files)
% v= 16;
% for  i= find(vv==v)
    d_in= collectBlades(loadFAST(fullfile(sim_dir, files{i})));
    % load rotor average wind speed
    [velocity, ~, ~, ~, ~, ~, ny, ~, dy, dt,~, ~, u_hub]= readfile_BTS(fullfile(wind_dir, strrep(strrep(files{i}, '1p1', 'NTM'), 'maininput.outb', 'turbsim_coh.bts')));
    tv= (0:(size(velocity, 1)-1))*dt;
    time= d_in.Time + ((ny-1)*dy/2)/u_hub;
    d_in.RtVAvgxh.Data= interp1(tv, velocity(:, 1, 1, 1), time);

    d_est= sim_turbine_T2B2cG_aero_est_bld_mom(d_in, param, 0, 1, [], [], [], 30);

    out_name= fullfile(sim_dir, strrep(files{i}, 'maininput.outb', 'est_bld_mom_adapt30.mat'));
    save(out_name, 'd_est');
    plot_timeseries_cmp(d_in, d_est, {'Q_TFA1' 'Q_TSS1' 'Q_BF1' 'Q_BE1' 'LSSTipVxa', 'Q_DrTr', 'RtVAvgxh'})
end

%% plot results
e2= zeros(length(files), 14);
for i= 1:length(files)
% v= 12;
% for  i= find(vv==v)
    est_name= fullfile(sim_dir, strrep(files{i}, 'maininput.outb', 'est_adapt30.mat'));
    load(est_name);

    e2(i, :)= calcEstError(d_in, d_est, param, 200);
end

state_names= {'tow_fa_idx', 'tow_ss_idx', 'bld_flp_idx', 'bld_edg_idx', 'phi_rot_idx', 'Dphi_gen_idx', 'vwind_idx', 'dtow_fa_idx', 'dtow_ss_idx', 'dbld_flp_idx', 'dbld_edg_idx', 'dphi_rot_idx', 'dDphi_gen_idx', 'dvwind_idx'};
idx= [1, 3, 6, 7];
bar(vv, sqrt(e2(:, idx)))
legend(state_names(idx))

%%
cd(old_dir)