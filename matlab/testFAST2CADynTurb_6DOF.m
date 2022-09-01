set_path

model_name= 'turbine_T2B2cG_aero';
model_dir= '../sim/gen';

testFAST2CADynTurb(model_name, model_dir, [1 2], [1 2])

%%
cd(model_dir)
d2= sim_turbine_T2B2cG_aero(d1, param);
cd(old_dir)

%% plot results
plot_timeseries_cmp(d1, d2, {'RtVAvgxh', 'PtchPMzc', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'});