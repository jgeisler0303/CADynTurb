function check_installAcados(CADynTurb_dir)
acados_dir = getenv('ACADOS_INSTALL_DIR');
if ~isempty(acados_dir)
    if ~verifyAcados(acados_dir)
        fprintf('The environment variable "ACADOS_INSTALL_DIR" is set but acados inlcuding CasADi doesn''t seem to be installed properly (libacados not found).\n')
        acados_dir = '';
        % TODO: remove the faulty setenv
        setenv('ACADOS_INSTALL_DIR', '')
    end    
end
if isempty(acados_dir)
    tf_install = askYesNo('You need to have acados on your system. Do you want to download and build it automatically (CMake will also be installed)?', true);
    if ~tf_install
        tf_choose = askYesNo('Do you want to choose the path to the acados directory?', true);
    end
    if tf_install
        check_installCMake

        fprintf('Cloning acados repository ... ')
        acados_dir = fullfile(CADynTurb_dir, '..', 'acados');
        gitclone('https://github.com/acados/acados.git', acados_dir, 'RecurseSubmodules', true);
        % repo.switchBranch("");
        setenv('ACADOS_INSTALL_DIR', acados_dir);
        fprintf('Done.\n')

        fprintf('Starting build process ... ')
        if ispc
            addpath(acados_dir, 'interfaces', 'acados_matlab_octave')
            acados_install_windows
        else
            build_dir = fullfile(acados_dir, 'build');
            [~, ~] = mkdir(build_dir);
            old_dir = pwd;
            cd(build_dir);
            system('cmake -DACADOS_WITH_QPOASES=ON ..')
            system('make install -j4')
            cd(old_dir)
            setenv('ENV_RUN', 'true')
            check_acados_requirements
        end
        fprintf('Done.\n')
    end
    if tf_install || tf_choose
        while true
            if ~isempty(acados_dir)
                if verifyAcados(acados_dir)
                    writelines("setenv('ACADOS_INSTALL_DIR', '" + strrep(acados_dir, '\', '/') + "')", fullfile(CADynTurb_dir, 'matlab', 'my_configCADynTurb.m'), 'WriteMode', 'append');
                    break
                else
                    fprintf('The path "%s" doesn''t seem to point to a valid acados library inluding CasADi.\n', acados_dir)
                end
            end
            pathname = uigetfile('', 'Please choose the location of the acados library.');
            if isequal(pathname, 0)
                tf_install = false;
                tf_choose = false;
                break
            else
                acados_dir = pathname;
            end
        end
    end
    if ~tf_install && ~tf_choose
        error(['Please manually install the acados library by following <a href = "matlab:web(''https://docs.acados.org/installation/'')">these</a> instructions. ' newline ...
            'And then <a href = "matlab:web(''https://docs.acados.org/matlab_octave_interface/index.html#setup-casadi'')">these</a> instructions.' newline ...
            'Then set the environment variable "ACADOS_INSTALL_DIR" to the path of the acados base directory. Do this by editing the script my_configCADynTurb accordingly.'])
    end
end

