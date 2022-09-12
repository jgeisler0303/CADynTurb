base_dir= fileparts(mfilename('fullpath'));

addpath(base_dir)
addpath(fullfile(base_dir, 'gen'))
addpath(fullfile(base_dir, 'plot'))
addpath(fullfile(base_dir, 'sim_data'))
addpath(fullfile(base_dir, 'lin_model'))
addpath(fullfile(base_dir, 'acados'))
addpath(fullfile(base_dir, 'observer'))
addpath(fullfile(base_dir, '../simulator'))

addpath(fullfile(base_dir, '../../matlab-toolbox/FAST2MATLAB'))
addpath(fullfile(base_dir, '../../matlab-toolbox/Utilities'))
addpath(fullfile(base_dir, '../../FEMBeam'))
addpath(fullfile(base_dir, '../../CCBlade-M'))
addpath(fullfile(base_dir, '../../CADyn/gen'))

%%
setenv('maxima_path', '/usr/bin/maxima')
setenv('cagem_path', fullfile(base_dir, '../../CADyn/gen/cagem.mac'))

