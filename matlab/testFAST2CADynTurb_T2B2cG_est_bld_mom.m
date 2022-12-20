%% prepare paths
set_path

model_name= 'turbine_T2B2cG_aero_est_bld_mom';
model_dir= fullfile(base_dir, '../sim/T2B2cG_est_bld_mom');

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

%% compile mex simulator
clc
cd(model_dir)
makeMex(model_name, '.')

%% simulate mex model
cd(model_dir)
d_in= collectBlades(loadFAST(fullfile(base_dir, '../sim/FAST/sim_no_inflow/impulse_URef-6_maininput.outb')));

d_out= sim_turbine_T2B2cG_aero_est_bld_mom(d_in, param);

%% plot results
plot_timeseries_cmp(d_in, d_out, {'RtVAvgxh', 'PtchPMzc', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'RootMxb', 'RootMyb'});

%% setup reference simulations
% for the next commnd you need the AMPoWS repo in your path
cd(model_dir)
openFAST_preprocessor('../openFAST_config_dyn_inflow.xlsx');
system('make -j -i 1p1')
dd= dir('../FAST/wind/NTM_URef-*_turbsim.bts');
makeCoherentBTS(fullfile('../FAST/wind', {dd.name}), 63)

%%
sim_dir= '../sim/FAST/sim_no_inflow';
% sim_dir= '../sim/FAST/sim_no_inflow_no3p';
% sim_dir= '../sim/FAST/sim_no_inflow_lin_shear';
wind_dir= '../sim/FAST/wind';
file_pattern= '1p1*_maininput.outb';
% file_pattern= 'coh*_maininput.outb';
% file_pattern= 'shear*_maininput.outb';

dd= dir(fullfile(base_dir, sim_dir, file_pattern));
files= {dd.name};

vv= zeros(length(files), 1);
for i= 1:length(files)
    v_str= regexp(files{i}, 'URef-(\d+)_', 'tokens', 'once');
    vv(i)= str2double(v_str{1});
end

%% run Kalman filter
cd(model_dir)
load('params')
% for i= 1:length(files)
param.Tm_avg= 0;
v= 12;
for  i= find(vv==v)
    d_in= collectBlades(loadFAST(fullfile(base_dir, sim_dir, files{i})));
    % load rotor average wind speed
    bts_file= strrep(files{i}, '1p1', 'NTM');
    bts_file= strrep(bts_file, 'coh', 'NTM');
    bts_file= strrep(bts_file, 'shear', 'NTM');
    bts_file= fullfile(base_dir, wind_dir, strrep(bts_file, 'maininput.outb', 'turbsim_coh.bts'));
    [velocity, ~, ~, ~, ~, ~, ny, ~, dy, dt,~, ~, u_hub]= readfile_BTS(bts_file);
    tv= (0:(size(velocity, 1)-1))*dt;
    time= d_in.Time + ((ny-1)*dy/2)/u_hub;
    d_in.RtVAvgxh.Data= interp1(tv, velocity(:, 1, 1, 1), time);

    Tadapt= 30;
    [d_est, ~, ~, ~, ~, ~, Q, R]= sim_turbine_T2B2cG_aero_est_bld_mom(d_in, param, 0, 1, [], [], [], Tadapt);

    out_name= fullfile(base_dir, sim_dir, strrep(files{i}, 'maininput.outb', 'est_a_T2B2cG_bld_mom_3p.mat'));
    save(out_name, 'd_est', 'Q', 'R', 'Tadapt');
%     plot_timeseries_cmp(d_in, d_est, {'Q_TFA1' 'Q_TSS1' 'Q_BF1' 'Q_BE1' 'LSSTipVxa', 'Q_DrTr', 'RtVAvgxh'})
    plot_timeseries_cmp(d_in, d_est, {'Q_TFA1' 'Q_TSS1' 'RootMxb' 'RootMyb' 'LSSTipVxa', 'Q_DrTr', 'RtVAvgxh'})
%     set(gcf, 'PaperType', 'A4')
%     set(gcf, 'PaperPosition', [0 0 get(gcf, 'PaperSize')])
%     print(strrep(out_name, '.mat', '.pdf'), '-dpdf', '-r300')
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