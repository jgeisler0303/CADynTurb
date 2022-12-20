%% prepare paths
set_path

model_name= 'turbine_T2B1i1cG_aero_est';
model_dir= fullfile(base_dir, '../sim/gen_T2B1i1cG_est');

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
cd(base_dir)
param= prepareModel('../5MW_Baseline/5MW_Land_IMP_6.fst', ['../model/' model_name '.mac'], model_dir, {[1 2]}, [1 2]);

%% compile mex simulator
clc
cd(model_dir)
makeMex(model_name, '.')

%% setup reference simulations
% fo the next commnd you nedd the AMPoWS repo in your path
openFAST_preprocessor('../openFAST_config_dyn_inflow.xlsx');
system('make -j -i 1p1')
dd= dir('../FAST/wind/NTM_URef-*_turbsim.bts');
makeCoherentBTS(fullfile('../FAST/wind', {dd.name}), 63)


%%
sim_dir= '../sim/FAST/sim_no_inflow';
% sim_dir= '../sim/FAST/sim_no_inflow_no3p';
% sim_dir= '../sim/FAST/sim_dyn_inflow';
wind_dir= '../sim/FAST/wind';
file_pattern= '1p1*_maininput.outb';
% file_pattern= 'impuls*_maininput.outb';
% file_pattern= 'coh*_maininput.outb';

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
cd(model_dir)
% for i= 1:length(files)
v= 11;
% for  i= find(vv==v & yaw==0)
for  i= find(vv==v)
    d_in= loadData(files{i}, fullfile(base_dir, sim_dir), fullfile(base_dir, wind_dir));

    d_out= sim_turbine_T2B1i1cG_aero_est(d_in, param);

    plot_timeseries_cmp(d_in, d_out, {'RtVAvgxh', 'BlPitchC1', 'LSSTipVxa', 'YawBrTDxp', 'RootMxb1', 'RootMyb1'});
end

%% run Kalman filter
cd(model_dir)
load('params.mat')
param.Tm_avg= 0;
% for i= 1:length(files)
v= 14;  % 5 7 9 15:22
for i= [15 17 19 6:13]
% for  i= find(vv==v & yaw==0)
% for  i= find(vv==v)
% for  i= find(~isnan(yaw))'
    if yaw(i)<0
        neg_str= 'neg';
    else
        neg_str= '';
    end
    try
        d_in= loadData(files{i}, fullfile(base_dir, sim_dir), fullfile(base_dir, wind_dir));
        Tadapt= 30;
%         adjust_adapt= [1.05 1.1 1 1.2 1.1 1.2 1.1 1.2 1.1];
        adjust_adapt= [];
        [d_est, ~, ~, ~, ~, ~, Q, R]= sim_turbine_T2B1i1cG_aero_est(d_in, param, 0, 1, [], [], [], Tadapt, adjust_adapt);
    
        out_name= fullfile(base_dir, sim_dir, strrep(files{i}, 'maininput.outb', 'est_a_T2B1i1cG.mat'));
        save(out_name, 'd_est', 'Q', 'R', 'Tadapt', 'adjust_adapt');
        plot_timeseries_cmp(d_in, d_est, {'RtVAvgxh', 'RtHSAvg', 'RtVSAvg', 'LSSTipVxa', 'Q_DrTr' 'YawBrTDxp', 'YawBrTDyp', 'Q_B1F1', 'Q_BE1'}, {}, {}, {}, 200);
%         plot_timeseries_cmp(d_in, d_est, {'RtVAvgxh', 'RtHSAvg', 'RtVSAvg', 'LSSTipVxa', 'YawBrTDxp', 'YawBrTAxp', 'RootMxb1', 'RootMyb1'});
        set(gcf, 'PaperType', 'A4')
        set(gcf, 'PaperPosition', [0 0 get(gcf, 'PaperSize')])
        print(strrep(out_name, '.mat', '.pdf'), '-dpdf', '-r300', '-painters')

        
        d_est= sim_turbine_T2B1i1cG_aero_est(d_in, param, 0, 1, Q, R, []);
    
        out_name= fullfile(base_dir, sim_dir, strrep(files{i}, 'maininput.outb', 'est_T2B1i1cG.mat'));
        save(out_name, 'd_est');
        plot_timeseries_cmp(d_in, d_est, {'RtVAvgxh', 'RtHSAvg', 'RtVSAvg', 'LSSTipVxa', 'Q_DrTr' 'YawBrTDxp', 'YawBrTDyp', 'Q_B1F1', 'Q_BE1'}, {}, {}, {}, 200);
        set(gcf, 'PaperType', 'A4')
        set(gcf, 'PaperPosition', [0 0 get(gcf, 'PaperSize')])
        print(strrep(out_name, '.mat', '.pdf'), '-dpdf', '-r300', '-painters')
    catch e
        disp(e)
    end
end

%%
function d_in= loadData(file, sim_dir, wind_dir)
d_in= collectBlades(loadFAST(fullfile(sim_dir, file)));

if strncmp(file, 'impuls', 6)
    RtHSAvg= timeseries('RtHSAvg');
    RtHSAvg.Time= d_in.Time;
    RtHSAvg.Data= zeros(size(d_in.Time));
    RtHSAvg.DataInfo.Units= 'm/s/m';
    RtHSAvg.TimeInfo.Units= 's';
    d_in= d_in.addts(RtHSAvg);
    RtVSAvg= timeseries('RtVSAvg');
    RtVSAvg.Time= d_in.Time;
    RtVSAvg.Data= zeros(size(d_in.Time));
    RtVSAvg.DataInfo.Units= 'm/s/m';
    RtVSAvg.TimeInfo.Units= 's';
    d_in= d_in.addts(RtVSAvg);
else
    % load rotor average wind speed
    bst_file= regexprep(file, 'NacYaw-(neg)?(\d+)_', '');
    bst_file= strrep(bst_file, 'coh', 'NTM');
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

% f3p= mean(d_in.LSSTipVxa.Data)/60*3;
% F= tf([1/1.333 0], [1/(2*pi*f3p)^2 2*sqrt(2)/(2*pi*f3p), 1]);
% My3p= lsim(F, d_in.RootMyb.Data, d_in.Time);
% d_in.RootMyb.Data= d_in.RootMyb.Data-My3p;
% d_in.RootMyb1.Data= d_in.RootMyb1.Data-My3p;
% d_in.RootMyb2.Data= d_in.RootMyb2.Data-My3p;
% d_in.RootMyb3.Data= d_in.RootMyb3.Data-My3p;
% Mx3p= lsim(F, d_in.RootMxb.Data, d_in.Time);
% d_in.RootMxb.Data= d_in.RootMxb.Data-Mx3p;
% d_in.RootMxb1.Data= d_in.RootMxb1.Data-Mx3p;
% d_in.RootMxb2.Data= d_in.RootMxb2.Data-Mx3p;
% d_in.RootMxb3.Data= d_in.RootMxb3.Data-Mx3p;

end
