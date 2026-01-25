function turbsim_path = check_installTurbSim(CADynTurb_dir)
if ~isempty(getenv('TURBSIM'))
    turbsim_path = getenv('TURBSIM');
    if ~verifyTurbSim(turbsim_path)
        fprintf('The environment variable "TURBSIM" but doesn''t seem to point to a valid TurbSim v3.3.0 executable.\n')
        turbsim_path = '';
        % TODO: remove the faulty setenv
        setenv('TURBSIM', '')
    end
end
if isempty(getenv('TURBSIM'))
    if ispc
        tf_install = askYesNo('You need to have TurbSim v3.3.0 on your system. Do you want to download that automatically?', true);
    else
        % We rely on check_installOpenFAST being called first and turbsim
        % already being built
        build_dir = fullfile(CADynTurb_dir, '..', 'OpenFAST', 'build_330');
        turbsim_path = fullfile(build_dir, 'modules', 'turbsim', 'turbsim');
        tf_install = exist(turbsim_path, 'file');
    end
    if ~tf_install
        tf_choose = askYesNo('Do you want to choose the path to the TurbSim version 3.3.0 executable?', true);
    end
    if tf_install
        if ispc
            fprintf('Downloading TurbSim v3.3.0 ... ')
            turbsim_path = fullfile(CADynTurb_dir, 'ref_sim', 'TurbSim_x64.exe');
            websave(turbsim_path, 'https://github.com/OpenFAST/openfast/releases/download/v3.3.0/TurbSim_x64.exe');
            fprintf('Done.\n')
        else
            % nothing to do, turbsim_path already set
        end
    end
    if tf_install || tf_choose
        while true
            if ~isempty(openfast_path)
                if verifyTurbSim(openfast_path)
                    writelines("setenv('TURBSIM', '" + strrep(turbsim_path, '\', '/') + "')", fullfile(CADynTurb_dir, 'matlab', 'my_configCADynTurb.m'), 'WriteMode', 'append');
                    break
                else
                    fprintf('The path "%s" doesn''t seem to be a valid TurbSim v3.3.0 executable.\n', openfast_path)
                end
            end
            if ispc
                [filename, pathname] = uigetfile('*.exe', 'Please choose the location of the "TurbSim_x64.exe" file.');
            else
                [filename, pathname] = uigetfile('', 'Please choose the location of the turbsim v3.3.0 executable file.');
            end
            if isequal(filename, 0) || isequal(pathname, 0)
                tf_install = false;
                tf_choose = false;
                break
            else
                turbsim_path = fullfile(pathname, filename);
            end
        end
    end
    if ~tf_install && ~tf_choose
        if ispc
            error(['Please download TurbSim v3.3.0 from <a href = "matlab:web(''https://github.com/OpenFAST/openfast/releases/download/v3.3.0/TurbSim_x64.exe'')">here</a>. ' newline ...
                % 'Additionally, you need to install the Intel Fortran redistributable package version 2023.2.4/2021.10.0 which you can download from <a href = "matlab:web(''https://www.intel.com/content/www/us/en/developer/articles/tool/compilers-redistributable-libraries-by-version.html'')">here</a>.' newline ...
                'Finally set the environment variable "TURBSIM" to the full path of the TurbSim executable. Do this by editing the script my_configCADynTurb accordingly.' newline ...
                'Use of CADynTurb cannot continue before this requirement is met.'])
        else
            error(['Please build the openfast and turbsim v3.3.0 program by following <a href = "matlab:web(''https://openfast.readthedocs.io/en/main/source/install/index.html#cmake-unix'')">these</a> instructions. ' newline ...
                'Make sure you checkout the v3.3.0 version from the repo ("git checkout v3.3.0").' newline ...
                'Finally set the environment variable "TURBSIM" to the full path of the TurbSim executable. Do this by editing the script my_configCADynTurb accordingly.' newline ...
                'Use of CADynTurb cannot continue before this requirement is met.'])
        end
    end
end
