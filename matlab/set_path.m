addpath(CADynTurb_dir)
addpath(fullfile(CADynTurb_dir, 'matlab/gen'))
addpath(fullfile(CADynTurb_dir, 'matlab/plot'))
addpath(fullfile(CADynTurb_dir, 'matlab/sim_data'))
addpath(fullfile(CADynTurb_dir, 'matlab/lin_model'))
addpath(fullfile(CADynTurb_dir, 'matlab/acados'))
addpath(fullfile(CADynTurb_dir, 'matlab/observer'))

addpath(fullfile(CADynTurb_dir, '../matlab-toolbox/FAST2MATLAB'))
addpath(fullfile(CADynTurb_dir, '../matlab-toolbox/MATLAB2FAST'))
addpath(fullfile(CADynTurb_dir, '../matlab-toolbox/Utilities'))
addpath(fullfile(CADynTurb_dir, '../matlab-toolbox/Utilities/compatibility'))

try
    addpath(fullfile(CADynTurb_dir, '../AMPoWS/Matlab/pre_processing/'))
catch e
end

addpath(fullfile(CADynTurb_dir, '../FEMBeam'))
addpath(fullfile(CADynTurb_dir, '../CADyn/gen'))
addpath(fullfile(CADynTurb_dir, '../SimpleDynInflow/AeroDynUtils'))

