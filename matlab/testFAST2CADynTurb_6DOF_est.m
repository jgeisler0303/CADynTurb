%%
clc
set_path

% base dir doesn't work when run as section, but is returned by set_path
% base_dir= fileparts(mfilename('fullpath'));

model_name= 'turbine_T2B2cG_aero_est';
model_dir= fullfile(base_dir, '../sim/gen_est');

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

%% compile mex simulator
clc
cd(model_dir)
makeMex('turbine_T2B2cG_aero_est', '.')

%% simulate mex model
cd(model_dir)
d_in= collectBlades(loadFAST(fullfile(base_dir, '../sim/FAST/sim_no_inflow/impulse_URef-12_maininput.outb')));

d_out= sim_turbine_T2B2cG_aero_est(d_in, param);

%% plot results
plot_timeseries_cmp(d_in, d_out, {'RtVAvgxh', 'PtchPMzc', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'});

%% compile ekf
cd(fullfile(base_dir, '..', 'simulator'))
mex('-g',  'CXXFLAGS="$CXXFLAGS -std=c++11 -Wall -fdiagnostics-show-option"', '-I../../CADyn/src', ['-I' model_dir], 'turbine_T2B2cG_aero_ekf_mex.cpp')

%% setup reference simulations
% for the next command you need the AMPoWS repo in your path
openFAST_preprocessor('../openFAST_config_dyn_inflow.xlsx');
system('make -j -i 1p1')
dd= dir('../FAST/wind/NTM_URef-*_turbsim.bts');
makeCoherentBTS(fullfile('../FAST/wind', {dd.name}), 63)

%%
sim_dir= '../sim/FAST/sim_no_inflow';
sim_dir_no= '../sim/FAST/sim_no_inflow';
% sim_dir= '../sim/FAST/sim_dyn_inflow';
wind_dir= '../sim/FAST/wind';
file_pattern= '1p1*_maininput.outb';

dd= dir(fullfile(base_dir, sim_dir, file_pattern));
files= {dd.name};

vv= zeros(length(files), 1);
yaw= zeros(length(files), 1);
for i= 1:length(files)
    v_str= regexp(files{i}, 'URef-(\d+)_', 'tokens', 'once');
    vv(i)= str2double(v_str{1});

    yaw_cell= regexp(files{i}, 'NacYaw-(neg)?(\d+)_', 'tokens', 'once');
    if isempty(yaw_cell)
        yaw(i)= nan;
    else
        yaw(i)= str2double(yaw_cell{2});
        if ~isempty(yaw_cell{1})
            yaw(i)= -yaw(i);
        end
    end
end

%% run Kalman filter
cd(model_dir)
load('params.mat')

% for i= 1:length(files)
v= 12;
% for  i= find(vv==12 & yaw==0)
for  i= find(vv==12)
% for  i= find(~isnan(yaw))'
    d_in= collectBlades(loadFAST(fullfile(base_dir, sim_dir, files{i})));
    % load rotor average wind speed
    bst_file= regexprep(files{i}, 'NacYaw-(neg)?(\d+)_', '');
    bst_file= strrep(strrep(bst_file, '1p1', 'NTM'), 'maininput.outb', 'turbsim_coh.bts');
    [velocity, ~, ~, ~, ~, ~, ny, ~, dy, dt,~, ~, u_hub]= readfile_BTS(fullfile(base_dir, wind_dir, bst_file));
    tv= (0:(size(velocity, 1)-1))*dt;
    time= d_in.Time + ((ny-1)*dy/2)/u_hub;
    d_in.RtVAvgxh.Data= interp1(tv, velocity(:, 1, 1, 1), time);

    Tadapt= 30;
    [d_est, ~, ~, ~, ~, ~, Q, R]= sim_turbine_T2B2cG_aero_est(d_in, param, 0, 1, [], [], [], Tadapt);

    out_name= fullfile(base_dir, sim_dir, strrep(files{i}, 'maininput.outb', 'est_a_T2B2cG.mat'));
    save(out_name, 'd_est', 'Q', 'R', 'Tadapt');

    plot_timeseries_cmp(d_in, d_est, {'RtVAvgxh', 'Q_TFA1' 'Q_TSS1' 'Q_BF1' 'Q_BE1' 'LSSTipVxa', 'Q_DrTr'}, {}, {}, {}, 200)
%     set(gcf, 'PaperType', 'A4')
%     set(gcf, 'PaperPosition', [0 0 get(gcf, 'PaperSize')])
%     print(strrep(out_name, '.mat', '.pdf'), '-dpdf', '-r300')
end

%% plot results
cd(model_dir)
load('params.mat')

e2= zeros(length(files), 14);
% for i= 1:length(files)
v= 12;
for  i= find(vv==v)
    d_in= collectBlades(loadFAST(fullfile(base_dir, sim_dir, files{i})));
    est_name= fullfile(base_dir, sim_dir, strrep(files{i}, 'maininput.outb', 'est_adapt30.mat'));
    load(est_name);

    e2(i, :)= calcEstError(d_in, d_est, param, 200);
end

state_names= {'tow_fa_idx', 'tow_ss_idx', 'bld_flp_idx', 'bld_edg_idx', 'phi_rot_idx', 'Dphi_gen_idx', 'vwind_idx', 'dtow_fa_idx', 'dtow_ss_idx', 'dbld_flp_idx', 'dbld_edg_idx', 'dphi_rot_idx', 'dDphi_gen_idx', 'dvwind_idx'};
idx= [1, 3, 6, 7];
bar(vv, sqrt(e2(:, idx)))
legend(state_names(idx), 'Interpreter', 'none')