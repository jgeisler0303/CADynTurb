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
    if tf_install
        if isunix
            [res, msg] = system('grep MemTotal /proc/meminfo');
            tokens = regexp(msg, '(\d+)', 'match');
            if res~=0 || isempty(tokens)
                warning('Could not determine our RAM. You could be in trouble compiling OpenFAST.');
            else
                kb = str2double(tokens{1});
                if kb < 15 * 1024^2
                    tf_continue = askYesNo('It seems you have less than 16GB of RAM. You will probably have trouble to compile OpenFAST, MATLAB may crash. Do you want to continue?', false);
                    if ~tf_continue
                        tf_install = false;
                    end
                end
            end
        end            
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
            [res, ~] = system('git --version');
            git_installed= res==0;
            [res, ~] = system('cmake --version');
            cmake_installed= res==0;
            [res, ~] = system('gfortran-10 --version');
            gfortran_installed= res==0;
            [res, ~] = system('g++ --version');
            gpp_installed= res==0;
            [res, ~] = system('dpkg -s libblas-dev');
            libblas_installed= res==0;
            [res, ~] = system('dpkg -s liblapack-dev');
            liblapack_installed= res==0;
            [res, ~] = system('dpkg -s libflame-dev');
            libflame_installed= res==0;
            if ~git_installed || ~cmake_installed || ~gfortran_installed || ~gpp_installed || ~libblas_installed || ~liblapack_installed || ~libflame_installed
                fprintf('Installing prerequisits for building OpenFAST... ')
                system([
                    'env -u LD_LIBRARY_PATH x-terminal-emulator -e ', ...
                    'bash -lc "sudo apt update && sudo apt install git cmake libblas-dev liblapack-dev libflame-dev gfortran-10 g++"'
                ]);
                fprintf('Done.\n')
            end
            if ~exist(fullfile(CADynTurb_dir, '..', 'OpenFAST', '.git'), 'dir')
                fprintf('Cloning openfast repository ... ')
                old_dir = pwd;
                cd(fullfile(CADynTurb_dir, '..'))
                system('git clone https://github.com/OpenFAST/OpenFAST.git');
                cd(fullfile(CADynTurb_dir, '..', 'OpenFAST'))
                system('git checkout v3.3.0');
                cd(old_dir)
                fprintf('Done.\n')
            end
            fprintf('Starting build process ... ')
            build_dir = fullfile(CADynTurb_dir, '..', 'OpenFAST', 'build_330');
            [~, ~] = mkdir(build_dir);
            old_dir = pwd;
            cd(build_dir);
            system('env -u LD_LIBRARY_PATH cmake ..');
            system('env -u LD_LIBRARY_PATH make openfast turbsim aerodyn_driver -j4');
            openfast_path = fullfile(build_dir, 'glue-codes', 'openfast', 'openfast');

            build_dir = fullfile(CADynTurb_dir, '..', 'OpenFAST', 'share', 'discon', 'build_330');
            [~, ~] = mkdir(build_dir);
            cd(build_dir);
            system('env -u LD_LIBRARY_PATH cmake ..');
            system('env -u LD_LIBRARY_PATH make');
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
