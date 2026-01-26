function check_installCompiler(CADynTurb_dir)
if ispc
    addons = matlab.addons.installedAddons;
    if ~ismember("ML_MINGW", addons.Identifier)
        tf_install = askYesNo('You need to install the MinGW64 Compiler MATLAB Add-On. Do you want to do that automatically?', true);
        if tf_install
            fprintf('Please follow the instructions in the dialog.')
            matlab.internal.addons.installAddonFromSidePanel('', [], 'ML_MINGW', 'support_package', '')
        else
            error(['Please install the MinGW64 Compiler via MATLAB Add-Ons manually.' newline ...
                'Use of CADynTurb cannot continue before this requirement is met.'])
        end
    end
else
    [res, msg] = system('g++ -v');
    if res~=0
        tf_install = askYesNo('You need to install the gcc compiler. Do you want to do that automatically?', true);
        if tf_install
            system('sudo apt update && sudo apt install build-essential gcc-fortran')
        else
            error(['Please setup up the gcc/g++ compiler manually.' newline ...
                'Use of CADynTurb cannot continue before this requirement is met.'])
        end
    end
end

if isempty(mex.getCompilerConfigurations('C++', 'Selected')) || isempty(mex.getCompilerConfigurations('C', 'Selected'))
    try
        mex -setup C
        mex -setup C++
    catch ME
        error(['mex -setup failed: %s. Please resolve this issue manually.' newline ...
            'Use of CADynTurb cannot continue before this requirement is met.'], ME.message);
    end
end

if ispc
    mc = mex.getCompilerConfigurations('C', 'Selected');
    mingwBin = fileparts(mc.Details.CompilerExecutable);

    curPath = getenv('PATH');
    isPresent = contains(lower(curPath), lower(mingwBin), 'IgnoreCase', true);
    if ~isPresent
        % Add to PATH for current MATLAB session (prepend)
        newPath = [mingwBin ';' curPath];
        setenv('PATH', newPath);
    end
end