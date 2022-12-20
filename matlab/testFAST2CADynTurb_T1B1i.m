%%
clc
set_path

% base dir doesn't work when run assection, but is returne by set_path
% base_dir= fileparts(mfilename('fullpath'));

model_name= 'turbine_T1B1i_aero';
model_dir= fullfile(base_dir, '../sim/gen_T1B1i');

%%
[param, tw_sid, bd_sid]= make_model(model_name, model_dir, {[1 -2]}, 1);

%%
d1= sim_standalone(fullfile(model_dir, [model_name '_sim']), '../FAST/sim_no_inflow/1p1_URef-12_maininput.fst');
% d1= loadFAST(fullfile(model_dir, '1p1_URef-12_maininput.outb'));
plot_timeseries(d1, {'RtVAvgxh', {'PtchPMzc1' 'PtchPMzc2' 'PtchPMzc3'}, 'GenTq', 'LSSTipVxa', 'YawBrTDxp', {'Q_B1F1' 'Q_B2F1' 'Q_B3F1'}})

%%
for v= 10
    file= fullfile(base_dir, sprintf('../sim/FAST/sim_no_inflow/impulse_URef-%d_maininput.fst', v));
    d1= sim_standalone(fullfile(model_dir, [model_name '_sim']), file);
    d2= loadFAST(strrep(file, '.fst', '.outb'));
%     d3= loadFAST(strrep(strrep(file, '.fst', '.outb'), 'sim_no_inflow', 'sim_no_inflow_no_cone'));
%     d4= loadFAST(strrep(strrep(file, '.fst', '.outb'), 'sim_no_inflow', 'sim_no_inflow_stiff'));
%     d5= loadFAST(strrep(strrep(file, '.fst', '.outb'), 'sim_no_inflow', 'sim_no_inflow_stiff_no_cone'));
%     plot_timeseries_multi({d1, d2, d3,d4, d5}, {'RtVAvgxh', 'PtchPMzc1', 'LSSTipPxa', 'YawBrTDxp', 'RootMxb1', 'RootMyb1'}, {'sim', 'FAST', 'no cone', 'stiff', 'stiff no cone'})
%     plot_timeseries_multi({d1, d2, d3,d4, d5}, {'RtVAvgxh', 'PtchPMzc1', 'LSSTipPxa', 'RootMxb1', 'RootMyb1'}, {'sim', 'FAST', 'no cone', 'stiff', 'stiff no cone'})
    plot_timeseries_multi({d1, d2}, {'RtVAvgxh', 'PtchPMzc1', 'LSSTipVxa', 'YawBrTDxp', 'RootMxb1', 'RootMyb1'}, {'sim', 'FAST', 'no cone', 'stiff', 'stiff no cone'})
end

%%
d2= loadFAST(fullfile(base_dir, '../sim/FAST/sim_no_inflow/1p1_URef-12_maininput.outb'));
%%
plot_timeseries_cmp(d1, d2, {'RtVAvgxh', 'PtchPMzc1', 'RootMxb1', 'RootMyb1', 'RootMxb2', 'RootMyb2', 'RootMxb3', 'RootMyb3'})