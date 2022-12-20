%%
clc
set_path

% base dir doesn't work when run assection, but is returne by set_path
% base_dir= fileparts(mfilename('fullpath'));

model_name= 'turbine_T1B1cG_aero';
model_dir= fullfile(base_dir, '../sim/T1B1cG');

%%
[param, tw_sid, bd_sid]= make_model(model_name, model_dir, {[1 -2 ]}, 1);

%%
d1= sim_standalone(fullfile(model_dir, [model_name '_sim']), '../../5MW_Baseline/5MW_Land_IMP_12.fst', 'simp_12_4DOF.outb', '-a 0.965');
plot_timeseries(d1, {'RtVAvgxh', 'PtchPMzc', 'HSShftV', 'GenTq', 'YawBrTDxp', 'Q_BF1'});
