function makeCADynEKFMex(model_name, model_dir, gen_dir, options)
if ~exist('options', 'var')
    options= '-O2 -march=native';
end

CADynTurb_dir= fileparts(fileparts(fileparts(mfilename('fullpath'))));

cd(gen_dir)
copyfile(fullfile(model_dir, [model_name '_ekf_config.m']), gen_dir)
if endsWith(model_name, '_RK1')
    fprintf('Compiling CADynEKF_RK1_mex with options "%s"\n', options)
    makeMex([model_name '_ekf_mex'], ...                                                            % mex name
        {'.', fullfile(CADynTurb_dir, '../CADyn/src'), fullfile(CADynTurb_dir, 'simulator')}, ...   % includes
        '', ...                                                                                     % options
        ['$CXXFLAGS -std=c++17 -Wall -fdiagnostics-show-option ' options], ...                      % CXXFLAGS
        ['MBSystem=' model_name(1:end-4)], ...                                                      % define
        fullfile(CADynTurb_dir, '../CADyn/src/CADynEKF_RK1_mex.cpp'));                              % source
else
    makeEKFMexSource(model_name)
    
    fprintf('Compiling CADynEKF_mex with options "%s"\n', options)
    makeMex(fullfile(gen_dir, [model_name '_ekf_mex.cpp']), ...
        {'.', fullfile(CADynTurb_dir, '../CADyn/src'), fullfile(CADynTurb_dir, 'simulator')}, ...
        '', ...
        ['$CXXFLAGS -std=c++17 -Wall -fdiagnostics-show-option ' options]);
end