function makeCADynEKFMex(model_name, model_dir, gen_dir, options)
if ~exist('options', 'var')
    options= '-O2 -march=native';
end

CADynTurb_dir= fileparts(fileparts(fileparts(mfilename('fullpath'))));

cd(gen_dir)
copyfile(fullfile(model_dir, [model_name '_ekf_config.m']), gen_dir)
makeEKFMexSource(model_name)

fprintf('Compiling mex with options "%s"\n', options)
makeMex(fullfile(gen_dir, [model_name '_ekf_mex.cpp']), ...
    {'.', fullfile(CADynTurb_dir, '../CADyn/src'), fullfile(CADynTurb_dir, 'simulator')}, ...
    '', ...
    ['$CXXFLAGS -std=c++11 -Wall -fdiagnostics-show-option ' options]);