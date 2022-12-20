%% prepare paths
set_path

model_name= 'turbine_T1B1i_aero_est';
model_dir= fullfile(base_dir, '../sim/gen_T1B1i_est');

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
param= prepareModel('../5MW_Baseline/5MW_Land_IMP_6.fst', ['../model/' model_name '.mac'], model_dir, {[1 -2]}, 1);

%%
old_dir= pwd;
cleanupObj = onCleanup(@()cd(old_dir));
cd(model_dir)

%% compile mex simulator
clc
makeMex(model_name, '.')

%% setup reference simulations
% fo the next commnd you nedd the AMPoWS repo in your path
openFAST_preprocessor('../openFAST_config_dyn_inflow.xlsx');
system('make -j -i 1p1')
dd= dir('../FAST/wind/NTM_URef-*_turbsim.bts');
makeCoherentBTS(fullfile('../FAST/wind', {dd.name}), 63)


%%
sim_dir= '../sim/FAST/sim_no_inflow';
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

%%
for i= 1:length(files)
    makeCoherentBTS(fullfile(wind_dir, strrep(strrep(files{i}, '1p1', 'NTM'), 'maininput.outb', 'turbsim.bts')), 63, 1)
end

%% simulate mex model
% for i= 1:length(files)
v= 12;
for  i= find(vv==v && yaw==0)
    d_in= loadData(files{i}, sim_dir, wind_dir);

    d_out= sim_turbine_T1B1i_aero_est(d_in, param);

    plot_timeseries_cmp(d_in, d_out, {'RtVAvgxh', 'PtchPMzc1', 'LSSTipVxa', 'YawBrTDxp', 'RootMxb1', 'RootMyb1'});
end

%% run Kalman filter
cd(model_dir)
% for i= 1:length(files)
v= 12;
% for  i= find(vv==v & yaw==-8)
for  i= find(vv==v)
% for  i= find(~isnan(yaw))'
    if yaw(i)<0
        neg_str= 'neg';
    else
        neg_str= '';
    end
    try
        d_in= loadData(files{i}, fullfile(base_dir, sim_dir), fullfile(base_dir, wind_dir));
        Tadapt= 30;
        adjust_adapt= [1.05 1 1.1 1.1 1.1 1.1 1.1 1.1];
    %     adjust_adapt= [];
        [d_est, ~, ~, ~, ~, ~, Q, R]= sim_turbine_T1B1i_aero_est(d_in, param, 0, 1, [], [], [], Tadapt, adjust_adapt);
    %     [d_est, ~, ~, ~, ~, ~, Q, R]= sim_turbine_T1B1i_aero_est(d_in, param, 0, 1, Q, R, []);
    
        out_name= fullfile(base_dir, sim_dir, strrep(files{i}, 'maininput.outb', 'est_a_T1B1i.mat'));
        save(out_name, 'd_est', 'Q', 'R', 'Tadapt', 'adjust_adapt');
        plot_timeseries_cmp(d_in, d_est, {'RtVAvgxh', 'RtHSAvg', 'RtVSAvg', 'LSSTipVxa', 'YawBrTDxp', 'YawBrTAxp', 'RootMxb1', 'RootMyb1'}, {}, {}, {}, 200);
        set(gcf, 'PaperType', 'A4')
        set(gcf, 'PaperPosition', [0 0 get(gcf, 'PaperSize')])
        print(strrep(out_name, '.mat', '.pdf'), '-dpdf', '-r300')
    %     plot_timeseries_cmp(d_in, d_est, {'RtVAvgxh', 'RtHSAvg', 'RtVSAvg', 'LSSTipVxa', 'YawBrTDxp', 'Q_B1F1', 'Q_B2F1', 'Q_B3F1'}, {}, {}, {}, 200);
    catch e
        disp(e)
    end
end

%%
function d_in= loadData(file, sim_dir, wind_dir)
d_in= collectBlades(loadFAST(fullfile(sim_dir, file)));
% load rotor average wind speed
bst_file= regexprep(file, 'NacYaw-(neg)?(\d+)_', '');
bst_file= strrep(strrep(bst_file, '1p1', 'NTM'), 'maininput.outb', 'turbsim_shear.bts');
[velocity, ~, ~, ~, ~, ~, ny, dz, dy, dt,~, ~, u_hub]= readfile_BTS(fullfile(wind_dir, bst_file));
tv= (0:(size(velocity, 1)-1))*dt;
time= d_in.Time + ((ny-1)*dy/2)/u_hub;
d_in.RtVAvgxh.Data= interp1(tv, (velocity(:, 1, 1, 1)+velocity(:, 1, 2, 1)+velocity(:, 1, 1, 2)+velocity(:, 1, 2, 2))/4, time);
RtHSAvg= timeseries('RtHSAvg');
RtHSAvg.Time= d_in.Time;
shear= 0.5*((velocity(:, 1, 2, 1)-velocity(:, 1, 1, 1))/dy + (velocity(:, 1, 2, 2)-velocity(:, 1, 1, 2))/dy);
RtHSAvg.Data=interp1(tv, shear, time);
RtHSAvg.DataInfo.Units= 'm/s/m';
RtHSAvg.TimeInfo.Units= 's';
d_in= d_in.addts(RtHSAvg);
RtVSAvg= timeseries('RtVSAvg');
RtVSAvg.Time= d_in.Time;
shear= 0.5*((velocity(:, 1, 1, 2)-velocity(:, 1, 1, 1))/dz + (velocity(:, 1, 2, 2)-velocity(:, 1, 2, 1))/dz);
RtVSAvg.Data=interp1(tv, shear, time);
RtVSAvg.DataInfo.Units= 'm/s/m';
RtVSAvg.TimeInfo.Units= 's';
d_in= d_in.addts(RtVSAvg);
end
