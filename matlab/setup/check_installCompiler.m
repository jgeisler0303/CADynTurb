function check_installCompiler(CADynTurb_dir)
if ispc
    addons = matlab.addons.installedAddons;
    if ~ismember("ML_MINGW", addons.Identifier)
        error(['Please install the MinGW64 Compiler via MATLAB Add-Ons manually.' newline ...
            'Open the Add-On Manager, search for "MinGW", select the first item and install it.' newline ...
            'Once you have successfully installed MinGW. Rerun the setup.' newline ...
            'Use of CADynTurb cannot continue before this requirement is met.'])
    end
else
    [res, msg] = system('g++ -v');
    if res~=0
        tf_install = askYesNo('You need to install the gcc compiler. Do you want to do that automatically?', true);
        if tf_install
            system([
                'env -u LD_LIBRARY_PATH x-terminal-emulator -e ', ...
                'bash -lc "sudo apt update && sudo apt install build-essential gfortran-10"'
            ]);
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
