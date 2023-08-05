% for the next command you need the AMPoWS repo in your path
openFAST_preprocessor(fullfile(base_dir, '../openFAST_config_dyn_inflow.xlsx'));

cd(fullfile(base_dir, '../ref_sim'))
system('make -j -i 1p1')
dd= dir(fullfile(base_dir, '../ref_sim/wind/NTM_URef-*_turbsim.bts'));
makeCoherentBTS(fullfile('../ref_sim/wind', {dd.name}), 63, 1)
