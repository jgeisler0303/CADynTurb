%%
old_dir= pwd;
cd('../matlab-toolbox/FAST2MATLAB')
addpath(pwd)
cd('../Utilities')
addpath(pwd)
cd(old_dir)
cd('../FEMBeam')
addpath(pwd)
cd(old_dir)
cd('../CCBlade-M')
addpath(pwd)
cd(old_dir)
cd('../CADyn/gen')
addpath(pwd)
cd(old_dir)

%%
fst_file= '5MW_Baseline/5MW_Land_DLL_WTurb.fst';
[param, data, tw_sid, bd_sid]= FAST2CADynTurb(fst_file);
save('param.mat', 'param')

%%
base_path= '5MW_Land_DLL_WTurb';
write_sid_maxima(tw_sid, [base_path '_tw_sid'], 'tower', length(tw_sid.frame), 1e-5, 1)
write_sid_maxima(bd_sid, [base_path '_bd_sid'], 'blade', [], 1e-5, 1)

%%
setenv('maxima_path', '/usr/bin/maxima')
setenv('cagem_path', fullfile(pwd, '../CADyn/gen/cagem.mac'))
makeMex('turbine_coll_flap_edge_pitch_aero.mac')

%%
params_turbine
sim_turbine
plot_turbine
