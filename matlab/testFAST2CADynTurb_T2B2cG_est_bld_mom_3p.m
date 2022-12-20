%% prepare paths
set_path

model_name= 'turbine_T2B2cG_aero_est_bld_mom_3p';
model_dir= fullfile(base_dir, '../sim/T2B2cG_est_bld_mom_3p');

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
makeMex(model_name, '.')

%% simulate mex model
d_in= collectBlades(loadFAST(fullfile(base_dir, '../sim/FAST/sim_no_inflow/impulse_URef-6_maininput.outb'));

d_out= sim_turbine_T2B2cG_aero_est_bld_mom_3p(d_in, param);
plot_timeseries_cmp(d_in, d_out, {'RtVAvgxh', 'PtchPMzc', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'RootMxb', 'RootMyb'});

%% setup reference simulations
% fo the next commnd you nedd the AMPoWS repo in your path
openFAST_preprocessor('../openFAST_config_dyn_inflow.xlsx');
system('make -j -i 1p1')
dd= dir('../FAST/wind/NTM_URef-*_turbsim.bts');
makeCoherentBTS(fullfile('../FAST/wind', {dd.name}), 63)

%%
sim_dir= '../sim/FAST/sim_no_inflow';
wind_dir= '../sim/FAST/wind';
file_pattern= '1p1*_maininput.outb';

dd= dir(fullfile(base_dir, sim_dir, file_pattern));
files= {dd.name};

vv= zeros(length(files), 1);
for i= 1:length(files)
    v_str= regexp(files{i}, 'URef-(\d+)_', 'tokens', 'once');
    vv(i)= str2double(v_str{1});
end

%% run Kalman filter
cd(model_dir)
load('params.mat')

% for i= 1:length(files)
param.Tm_avg= 0;
v= 12;
for  i= find(vv==v)
    d_in= collectBlades(loadFAST(fullfile(base_dir, sim_dir, files{i})));
    % load rotor average wind speed
    [velocity, ~, ~, ~, ~, ~, ny, ~, dy, dt,~, ~, u_hub]= readfile_BTS(fullfile(base_dir, wind_dir, strrep(strrep(files{i}, '1p1', 'NTM'), 'maininput.outb', 'turbsim_coh.bts')));
    tv= (0:(size(velocity, 1)-1))*dt;
    time= d_in.Time + ((ny-1)*dy/2)/u_hub;
    d_in.RtVAvgxh.Data= interp1(tv, velocity(:, 1, 1, 1), time);

    d_est= sim_turbine_T2B2cG_aero_est_bld_mom_3p(d_in, param, 0, 1, [], [], [], 30);

    out_name= fullfile(base_dir, sim_dir, strrep(files{i}, 'maininput.outb', 'est_bld_mom_3p_adapt30.mat'));
    save(out_name, 'd_est');
    plot_timeseries_cmp(d_in, d_est, {'Q_TFA1' 'Q_TSS1' 'Q_BF1' 'Q_BE1' 'LSSTipVxa', 'Q_DrTr', 'RtVAvgxh'})
%     plot_timeseries_cmp(d_in, d_est, {'Q_TFA1' 'Q_TSS1' 'RootMxb' 'RootMyb' 'LSSTipVxa', 'Q_DrTr', 'RtVAvgxh'})
end

%%
cd(old_dir)