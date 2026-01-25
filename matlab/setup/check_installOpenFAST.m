function openfast_path = check_installOpenFAST(CADynTurb_dir)
if ~isempty(getenv('OPENFAST'))
    openfast_path = getenv('OPENFAST');
    if ~verifyOpenFAST(openfast_path)
        fprintf('The environment variable "OPENFAST" but doesn''t seem to point to a valid OpenFAST v3.3.0 executable.\n')
        openfast_path = '';
        % TODO: remove the faulty setenv
        setenv('OPENFAST', '')
    end
end
if isempty(getenv('OPENFAST'))
    if ispc
        tf_install = askYesNo('You need to have OpenFAST v3.3.0 on your system. Do you want to download that automatically?', true);
    else
        tf_install = askYesNo('You need to have OpenFAST v3.3.0 on your system. Do you want to clone the repository and build it automatically?', true);
    end
    if ~tf_install
        tf_choose = askYesNo('Do you want to choose the path to the OpenFAST version 3.3.0 executable?', true);
    end
    if tf_install
        if ispc
            fprintf('Downloading OpenFAST v3.3.0 ... ')
            openfast_path = fullfile(CADynTurb_dir, 'ref_sim', 'openfast_x64.exe');
            websave(openfast_path, 'https://github.com/OpenFAST/openfast/releases/download/v3.3.0/openfast_x64.exe');
            fprintf('Done.\n')
        else
            fprintf('Installing prerequisits for building OpenFAST... ')
            system('sudo apt install git cmake libblas-dev liblapack-dev gfortran-10 g++');
            fprintf('Done.\n')
            fprintf('Cloning openfast repository ... ')
            repo = gitclone('https://github.com/OpenFAST/OpenFAST.git', fullfile(CADynTurb_dir, '..', 'OpenFAST'));
            repo.switchBranch("v3.3.0");
            fprintf('Done.\n')
            fprintf('Starting build process ... ')
            build_dir = fullfile(CADynTurb_dir, '..', 'OpenFAST', 'build_330');
            [~, ~] = mkdir(build_dir);
            old_dir = pwd;
            cd(build_dir);
            system('cmake ..')
            system('make openfast turbsim aerodyn_driver -j4')
            openfast_path = fullfile(build_dir, 'glue-codes', 'openfast', 'openfast');

            build_dir = fullfile(CADynTurb_dir, '..', 'OpenFAST', 'share', 'discon', 'build_330');
            [~, ~] = mkdir(build_dir);
            cd(build_dir);
            system('cmake ..')
            system('make')
            cd(old_dir)
            fprintf('Done.\n')
        end
    end
    if tf_install || tf_choose
        while true
            if ~isempty(openfast_path)
                if verifyOpenFAST(openfast_path)
                    writelines("setenv('OPENFAST', '" + strrep(openfast_path, '\', '/') + "')", fullfile(CADynTurb_dir, 'matlab', 'my_configCADynTurb.m'), 'WriteMode', 'append');
                    break
                else
                    fprintf('The path "%s" doesn''t seem to be a valid OpenFAST v3.3.0 executable.\n', openfast_path)
                end
            end
            if ispc
                [filename, pathname] = uigetfile('*.exe', 'Please choose the location of the "openfast_x64.exe" file.');
            else
                [filename, pathname] = uigetfile('', 'Please choose the location of the openfast v3.3.0 executable file.');
            end
            if isequal(filename, 0) || isequal(pathname, 0)
                tf_install = false;
                tf_choose = false;
                break
            else
                openfast_path = fullfile(pathname, filename);
            end
        end
    end
    if ~tf_install && ~tf_choose
        if ispc
            error(['Please download OpenFAST v3.3.0 from <a href = "matlab:web(''https://github.com/OpenFAST/openfast/releases/download/v3.3.0/openfast_x64.exe'')">here</a>. ' newline ...
                % 'Additionally, you need to install the Intel Fortran redistributable package version 2023.2.4/2021.10.0 which you can download from <a href = "matlab:web(''https://www.intel.com/content/www/us/en/developer/articles/tool/compilers-redistributable-libraries-by-version.html'')">here</a>.' newline ...
                'Finally set the environment variable "OPENFAST" to the full path of the OpenFAST executable. Do this by editing the script my_configCADynTurb accordingly.' newline ...
                'Use of CADynTurb cannot continue before this requirement is met.'])
        else
            error(['Please build the openfast v3.3.0 program by following <a href = "matlab:web(''https://openfast.readthedocs.io/en/main/source/install/index.html#cmake-unix'')">these</a> instructions. ' newline ...
                'Make sure you checkout the v3.3.0 version from the repo ("git checkout v3.3.0").' newline ...
                'Finally set the environment variable "OPENFAST" to the full path of the OpenFAST executable. Do this by editing the script my_configCADynTurb accordingly.' newline ...
                'Use of CADynTurb cannot continue before this requirement is met.'])
        end
    end
end
