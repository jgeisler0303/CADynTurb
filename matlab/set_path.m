addpath(pwd)
addpath(fullfile(pwd, 'gen'))
addpath(fullfile(pwd, 'observer'))
addpath(fullfile(pwd, 'plot'))
addpath(fullfile(pwd, 'sim_data'))

old_dir= pwd;
cd('../../matlab-toolbox/FAST2MATLAB')
addpath(pwd)
cd('../Utilities')
addpath(pwd)
cd(old_dir)
cd('../../FEMBeam')
addpath(pwd)
cd(old_dir)
cd('../../CCBlade-M')
addpath(pwd)
cd(old_dir)
cd('../../CADyn/gen')
addpath(pwd)
cd(old_dir)

%%
setenv('maxima_path', '/usr/bin/maxima')
setenv('cagem_path', fullfile(pwd, '../../CADyn/gen/cagem.mac'))

