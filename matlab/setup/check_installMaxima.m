function check_installMaxima(CADynTurb_dir)
maxima_path = getenv('maxima_path');
if isempty(maxima_path)
    if ~verifyMaxima(maxima_path)
        fprintf('The environment variable "maxima_path" but doesn''t seem to point to a valid Maxima version 5.44 executable.\n')
        maxima_path = '';
        % TODO: remove the faulty setenv
        setenv('maxima_path', '')
    end
end
if isempty(maxima_path)
    tf_install = askYesNo('You need to install Maxima 5.44. Do you want to download it automatically and start the installation process?', true);
    if ~tf_install
        tf_choose = askYesNo('Do you want to choose the path to the maxima executable?', true);
    end
    if tf_install
        fprintf('Downloading Maxima ... ')
        download_dir = fullfile(CADynTurb_dir, 'downloads');
        [~, ~] = mkdir(download_dir);
        if ispc
            maxima_install_file = fullfile(download_dir, 'maxima-clisp-sbcl-5.44.0-win64.exe');    
            if ~exist(maxima_install_file, 'file')
                websave(maxima_install_file, 'https://sourceforge.net/projects/maxima/files/Maxima-Windows/5.44.0-Windows/maxima-clisp-sbcl-5.44.0-win64.exe/download')
            end
        else
            maxima_package1 = fullfile(download_dir, 'maxima-sbcl_5.44.0-1_amd64.deb');
            if ~exist(maxima_package1, 'file')
                websave(maxima_package1, 'https://sourceforge.net/projects/maxima/files/Maxima-Linux/5.44.0-Linux/maxima-sbcl_5.44.0-1_amd64.deb/download');
            end
            maxima_package2 = fullfile(download_dir, 'maxima-common_5.44.0-1_all.deb');
            if ~exist(maxima_package2, 'file')
                websave(maxima_package2, 'https://sourceforge.net/projects/maxima/files/Maxima-Linux/5.44.0-Linux/maxima-common_5.44.0-1_all.deb/download');
            end
        end
        fprintf('Done.\n')
        fprintf('Starting installation of Maxima ...');
        if ispc
            system(maxima_install_file);
        else
            system(['env -u LD_LIBRARY_PATH x-terminal-emulator -e "sudo dpkg -i ' maxima_package1 ' ' maxima_package2 '"']);
        end
        fprintf('Done.\n')

        if ispc
            maxima_path = 'C:/maxima-5.44.0/bin/maxima.bat';
        else
            maxima_path = '/usr/bin/maxima';
        end
    else
        maxima_path = '';
    end
    if tf_install || tf_choose
        while true
            if ~isempty(maxima_path)
                if verifyMaxima(maxima_path)
                    writelines("setenv('maxima_path', '" + strrep(maxima_path, '\', '/') + "')", fullfile(CADynTurb_dir, 'matlab', 'my_configCADynTurb.m'), 'WriteMode', 'append');
                    break
                else
                    fprintf('The path "%s" doesn''t seem to be a valid maxima executable.\n', maxima_path)
                end
            end
            if ispc
                [filename, pathname] = uigetfile('*.bat', 'Please choose the location of the "maxima.bat" file.');
            else
                [filename, pathname] = uigetfile('', 'Please choose the location of the "maxima" executable file.');
            end
            if isequal(filename, 0) || isequal(pathname, 0)
                tf_install = false;
                tf_choose = false;
                break
            else
                maxima_path = fullfile(pathname, filename);
            end
        end
    end
    if ~tf_install && ~tf_choose
        if ispc
            error(['Please install Maxima 5.44 manually.' newline ...
                'Use of CADynTurb cannot continue before this requirement is met.' newline ...
                'You can download it from <a href = "matlab:web(''https://sourceforge.net/projects/maxima/files/Maxima-Windows/'')">here</a>.' newline 'Then set the environment variable "maxima_path" to the full path of the maxima batch file (this will be something like "C:/maxima-5.44.0/bin/maxima.bat"). Do this by editing the script my_configCADynTurb accordingly.'])
        else
            error(['Please install Maxima version 5.44 in the sbcl flavor.' newline ...
                'Use of CADynTurb cannot continue before this requirement is met.' newline ...
                'You can download it from <a href = "matlab:web(''https://sourceforge.net/projects/maxima/files/Maxima-Linux/5.44.0-Linux/'')">here</a>. You have to download and install the files "maxima-sbcl_5.44.0-1_{arch}.{deb|rpm}" and "maxima-common_5.44.0-1_all.{deb|rpm}". After download, on Ubuntu install via "dpkg -i {debname}". Do not install the official Ubuntu package ("sudo apt install maxima")!.' newline 'Then set the environment variable "maxima_path" to the full path of the maxima executable ("/usr/bin/maxima"). Do this by editing the script my_configCADynTurb accordingly.'])
        end
    end
end
