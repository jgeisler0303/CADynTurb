%%
clc
set_path

% base dir doesn't work when run assection, but is returne by set_path
% base_dir= fileparts(mfilename('fullpath'));

model_name= 'turbine_T2B2cG_aero';
model_dir= fullfile(base_dir, '../sim/gen6');

%% calculate parameters and generate and compile all source code
[param, tw_sid, bd_sid]= make_model(model_name, model_dir, {[1 2]}, [1 2]);

%% run stand-alone simulator with simple test
d1= sim_standalone(fullfile(model_dir, [model_name '_sim']), '../../5MW_Baseline/5MW_Land_IMP_12.fst', 'simp_12_6DOF.outb', '-a 0.965');
plot_timeseries(d1, {'RtVAvgxh', 'PtchPMzc', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'});
% plot_timeseries(d1, {'RtVAvgxh', 'PtchPMzc', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'RootMxb', 'RootMyb'});

%% sim mex model (feedforward)
cd(model_dir)
d2= sim_turbine_T2B2cG_aero(d1, param);
cd(old_dir)

%% plot comparison
plot_timeseries_cmp(d1, d2, {'RtVAvgxh', 'PtchPMzc', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'});

%% compare stand-alone simulator with OpenFAST
fast_file= fullfile(base_dir, '../sim/FAST/sim/1p1_NacYaw-0_URef-12_maininput.fst');
[base_path, base_file]= fileparts(fast_file);
wind_dir= fullfile(base_path, '..', 'wind');
sim_file= [strrep(base_file, 'maininput', model_name) '.outb'];
d_sim= sim_standalone(fullfile(model_dir, [model_name '_sim']), fast_file, fullfile(base_path, sim_file));
d_sim= add_timeseries(d_sim, 'RootMxc', 'kNm', d_sim.RootMxb.Data.*cosd(d_sim.BlPitchC.Data) + d_sim.RootMyb.Data.*sind(d_sim.BlPitchC.Data));
d_sim= add_timeseries(d_sim, 'RootMyc', 'kNm', -d_sim.RootMxb.Data.*sind(d_sim.BlPitchC.Data) + d_sim.RootMyb.Data.*cosd(d_sim.BlPitchC.Data));

d_FAST= collectBlades(loadFAST(strrep(fast_file, '.fst', '.outb')));
d_FAST= add_average_wind(d_FAST, wind_dir, base_file);

% plot_timeseries_cmp(d_sim, d_FAST, {'RtVAvgxh', 'BlPitchC', 'HSShftV', 'GenTq', 'Q_TFA1', 'Q_TSS1', 'RootMxc', 'RootMyc'}, {}, {}, {}, 30);
plot_timeseries_cmp(d_sim, d_FAST, {'RtVAvgxh', 'BlPitchC', 'HSShftV', 'GenTq', 'Q_TFA1', 'Q_TSS1', 'Q_BF1', 'Q_BE1'}, {}, {}, {}, 30);

%% compare python
sim_file= fullfile(base_dir, '../sim/FAST/sim/1p1_NacYaw-0_URef-12_maininput.outb');
d_sim= loadFAST(sim_file);
d_py= loadFAST(strrep(sim_file, '.outb', '_py.outb'));
plot_timeseries_cmp(d_sim, d_py, {'RtVAvgxh', 'Q_TFA1', 'Q_TSS1', 'Q_BF1', 'Q_BE1', 'LSSTipVxa', 'HSShftV'}, {}, {}, {}, 30);


%%
function d= add_timeseries(d, name, units, data)
    ts= timeseries(name);
    ts.Time= d.Time;
    ts.TimeInfo.Units= 's';
    ts.Data= data;
    ts.DataInfo.Units= units;
    if ismember(name, d.fieldnames)
        d.(name)= ts;
    else
        d= d.addts(ts);
    end
end

function d= add_average_wind(d, wind_dir, fst_file)
    bst_file= regexprep(fst_file, 'NacYaw-(neg)?(\d+)_', '');
    bst_file= strrep(bst_file, 'coh', 'NTM');
    bst_file= strrep(strrep(bst_file, '1p1', 'NTM'), 'maininput', 'turbsim_shear.bts');
    [velocity, ~, ~, ~, ~, ~, ny, dz, dy, dt,~, ~, u_hub]= readfile_BTS(fullfile(wind_dir, bst_file));
    tv= (0:(size(velocity, 1)-1))*dt;
    time= d.Time + ((ny-1)*dy/2)/u_hub;
    d.RtVAvgxh.Data= interp1(tv, (velocity(:, 1, 1, 1)+velocity(:, 1, 2, 1)+velocity(:, 1, 1, 2)+velocity(:, 1, 2, 2))/4, time);
end