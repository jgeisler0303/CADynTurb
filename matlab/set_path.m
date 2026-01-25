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

if ~isempty(getenv('ACADOS_INSTALL_DIR'))
    addpath(fullfile(getenv('ACADOS_INSTALL_DIR'), 'examples', 'acados_matlab_octave', 'getting_started'))
    addpath(fullfile(getenv('ACADOS_INSTALL_DIR'), 'interfaces/acados_matlab_octave'));
    addpath(fullfile(getenv('ACADOS_INSTALL_DIR'), 'external/casadi-matlab'))
    
    % depricated in new acados
    % addpath(fullfile(getenv('ACADOS_INSTALL_DIR'), 'interfaces/acados_matlab_octave/acados_template_mex'));
end


if exist(fullfile(CADynTurb_dir, '..', 'CADynM'), 'dir')
    addpath(fullfile(CADynTurb_dir, '..', 'CADynM', 'toolbox'))
    addpath(fullfile(CADynTurb_dir, '..', 'CADynM', 'toolbox', 'utils'))
end

