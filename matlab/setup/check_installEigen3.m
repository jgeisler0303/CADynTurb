function check_installEigen3(CADynTurb_dir)
if ~isempty(getenv('EIGEN3'))
    eigen3_dir = getenv('EIGEN3');
    if ~verifyEigen3(eigen3_dir)
        fprintf('The environment variable "EIGEN3" but doesn''t seem to point to a valid Eigen3 veroin 3.3.9 library folder.\n')
        eigen3_dir = '';
        % TODO: remove the faulty setenv
        setenv('EIGEN3', '')
    end
end
if isempty(getenv('EIGEN3'))
    tf_install = askYesNo('You need to install the eigen3 library. Do you want to do that automatically?', true);
    if ~tf_install
        tf_choose = askYesNo('Do you want to choose the path to the Eigen3 library?', true);
    end
    if tf_install
        fprintf('Downloading eigen3 ... ')
        download_dir = fullfile(CADynTurb_dir, 'downloads');
        [~, ~] = mkdir(download_dir);
        eigen_zip = fullfile(download_dir, 'eigen3.zip');
        websave(eigen_zip, "https://gitlab.com/libeigen/eigen/-/archive/3.3.9/eigen-3.3.9.zip");
        fprintf('Done.\n')

        fprintf('Unzipping and copying files ... ')
        eigen3_dir = fullfile(CADynTurb_dir, '..', 'eigen-3.3.9');
        unzip(eigen_zip, fullfile(CADynTurb_dir, '..'));
        fprintf('Done.\n')
    end
    if tf_install || tf_choose
        while true
            if ~isempty(eigen3_dir)
                if verifyEigen3(eigen3_dir)
                    writelines("setenv('EIGEN3', '" + strrep(eigen3_dir, '\', '/') + "')", fullfile(CADynTurb_dir, 'matlab', 'my_configCADynTurb.m'), 'WriteMode', 'append');
                    break
                else
                    fprintf('The path "%s" doesn''t seem to be a eigen3 version 3.3.9 library.\n', eigen3_dir)
                end
            end
            pathname = uigetfile('', 'Please choose the location of the eigen3 library.');
            if isequal(pathname, 0)
                tf_install = false;
                tf_choose = false;
                break
            else
                eigen3_dir = pathname;
            end
        end
    end
    if ~tf_install && ~tf_choose
        error('Please download version 3.3.9 (!) of the eigen3 library from here: https://gitlab.com/libeigen/eigen/-/archive/3.3.9/eigen-3.3.9.zip and copy the "Eigen" and the "unsupported" folder from the zip file to your gcc (MinGW) compilers include directory. Use of CADynTurb cannot continue before this requirement is met.')
    end
end