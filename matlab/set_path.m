CADynTurb_dir= fileparts(mfilename('fullpath'));

addpath(CADynTurb_dir)
addpath(fullfile(CADynTurb_dir, 'gen'))
addpath(fullfile(CADynTurb_dir, 'plot'))
addpath(fullfile(CADynTurb_dir, 'sim_data'))
addpath(fullfile(CADynTurb_dir, 'lin_model'))
addpath(fullfile(CADynTurb_dir, 'acados'))
addpath(fullfile(CADynTurb_dir, 'observer'))

addpath(fullfile(CADynTurb_dir, '../../matlab-toolbox/FAST2MATLAB'))
addpath(fullfile(CADynTurb_dir, '../../matlab-toolbox/MATLAB2FAST'))
addpath(fullfile(CADynTurb_dir, '../../matlab-toolbox/Utilities'))
addpath(fullfile(CADynTurb_dir, '../../matlab-toolbox/Utilities/compatibility'))

addpath(fullfile(CADynTurb_dir, '../../AMPoWS/Matlab/pre_processing/'))

addpath(fullfile(CADynTurb_dir, '../../FEMBeam'))
addpath(fullfile(CADynTurb_dir, '../../CADyn/gen'))
addpath(fullfile(CADynTurb_dir, '../../SimpleDynInflow/AeroDynUtils'))

