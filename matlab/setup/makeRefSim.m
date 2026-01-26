function makeRefSim(CADynTurb_dir, openfast_path, turbsim_path)
%% generate simulation configurations
if ~exist(fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow'), 'dir')
    openFAST_preprocessor(fullfile(CADynTurb_dir, 'ref_sim/openFAST_config_dyn_inflow.xlsx'), openfast_path, turbsim_path);
end
if ~exist(fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow'), 'dir')
    openFAST_preprocessor(fullfile(CADynTurb_dir, 'ref_sim/openFAST_config_no_inflow.xlsx'), openfast_path, turbsim_path);
end

fprintf('A seceltion of scenarios will now be simulated. If you want to use all available scenarios, please go to the ref_sim folders sub_folders and rund the simulation scripts.')

%% run turbsim for 12m/s
old_dir= cd(fullfile(CADynTurb_dir, 'ref_sim/wind'));
cleanupObj = onCleanup(@()cd(old_dir));

if ~exist(fullfile(CADynTurb_dir, 'ref_sim/wind/NTM_URef-12_turbsim.bts'), 'file')
    system([turbsim_path ' NTM_URef-12_turbsim.inp']);
end

%% make additional wind file for rotor average and shear
if ~exist(fullfile(CADynTurb_dir, 'ref_sim/wind/NTM_URef-12_turbsim_shear.bts'), 'file')
    dd= dir(fullfile(CADynTurb_dir, 'ref_sim/wind/NTM_URef-*_turbsim.bts'));
    makeCoherentBTS(fullfile(CADynTurb_dir, 'ref_sim/wind', {dd.name}), 63, 1);
end

%% run openfast for 12m/s with dynamic inflow
if ~exist(fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow/impulse_URef-12_maininput.outb'), 'file')
    cd(fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow'))
    system([openfast_path ' impulse_URef-12_maininput.fst']);
end
if ~exist(fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow/1p1_NacYaw-0_URef-12_maininput.outb'), 'file')
    cd(fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow'))
    system([openfast_path ' 1p1_NacYaw-0_URef-12_maininput.fst']);
end

%% run openfast for 12m/s without dynamic inflow
if ~exist(fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow/impulse_URef-12_maininput.outb'), 'file')
    cd(fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow'))
    system([openfast_path ' impulse_URef-12_maininput.fst']);
end
if ~exist(fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow/1p1_NacYaw-0_URef-12_maininput.outb'), 'file')
    cd(fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow'))
    system([openfast_path ' 1p1_NacYaw-0_URef-12_maininput.fst']);
end
