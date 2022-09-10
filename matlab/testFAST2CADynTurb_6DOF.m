set_path

model_name= 'turbine_T2B2cG_aero';
model_dir= '../sim/gen6';

[d1, param, tw_sid, bd_sid]= testFAST2CADynTurb(model_name, model_dir, {[1 2]}, [1 2]);

%%
cd(model_dir)
load('params.mat')
d2= sim_turbine_T2B2cG_aero(d1, param);
cd(old_dir)

%% plot results
plot_timeseries_cmp(d1, d2, {'RtVAvgxh', 'PtchPMzc', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'});