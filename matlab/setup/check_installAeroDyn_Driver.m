function check_installAeroDyn_Driver(CADynTurb_dir)

AD_driver= getenv('AD_DRIVER');
if isempty(AD_driver)
    if ~verifyAD_driver(AD_driver)
        fprintf('The environment variable "AD_DRIVER" but doesn''t seem to point to a valid AeroDyn standalone driver v3.3.0 executable.\n')
        AD_driver = '';
        % TODO: remove the faulty setenv
        setenv('AD_DRIVER', '')
    end
end
if isempty(AD_driver)
    tf_install = askYesNo('You need to have the AeroDyn standalone driver v3.3.0. Do you want to download it automatically?', true);
    if ~tf_install
        tf_choose = askYesNo('Do you want to choose the path to the AeroDyn standalone driver executable?', true);
    end
    if tf_install
        fprintf('Downloading AeroDyn standalone driver ... ')
        if ispc
            AD_Driver = fullfile(CADynTurb_dir, '..', 'SimpleDynInflow', 'AeroDyn_Driver_x64_Double.exe');
            websave(AD_Driver, 'https://github.com/jgeisler0303/SimpleDynInflow/releases/download/AeroDyn_v3.3.0/AeroDyn_Driver_x64_Double.exe');
        else
            AD_Driver = fullfile(CADynTurb_dir, '..', 'SimpleDynInflow', 'aerodyn_driver');
            websave(AD_Driver, 'https://github.com/jgeisler0303/SimpleDynInflow/releases/download/AeroDyn_v3.3.0/aerodyn_driver');
            system(['chmod a+x ' AD_Driver])
        end               
        fprintf('Done.\n')
    end
    if tf_install || tf_choose
        while true
            if ~isempty(AD_Driver)
                if verifyAD_driver(AD_driver)
                    writelines("setenv('AD_DRIVER', '" + strrep(AD_Driver, '\', '/') + "')", fullfile(CADynTurb_dir, 'matlab', 'my_configCADynTurb.m'), 'WriteMode', 'append');
                    break
                else
                    fprintf('The path "%s" doesn''t seem to be a valid AeroDyn driver executable.\n', AD_Driver)
                end
            end
            if ispc
                [filename, pathname] = uigetfile('*.exe', 'Please choose the location of the "AeroDyn_Driver.exe" file.');
            else
                [filename, pathname] = uigetfile('', 'Please choose the location of the "aerodyn_driver" executable file.');
            end
            if isequal(filename, 0) || isequal(pathname, 0)
                tf_install = false;
                tf_choose = false;
                break
            else
                AD_Driver = fullfile(pathname, filename);
            end
        end
    end
    if ~tf_install && ~tf_choose
        if ispc
            error(['Please download the AeroDyn standalone driver v3.3.0. Use of CADynTurb cannot continue before this requirement is met. For Windows you can download it from <a href = "matlab:web(''https://github.com/jgeisler0303/SimpleDynInflow/releases/download/AeroDyn_v3.3.0/AeroDyn_Driver_x64_Double.exe'')">here</a>. Additionally you need to install the Intel Fortran Compiler Runtime for Windows version 2023.2.4/2021.10.0 from <a href = "matlab:web(''https://www.intel.com/content/www/us/en/developer/articles/tool/compilers-redistributable-libraries-by-version.html'')">here</a>.' newline 'Then set the environment variable "AD_driver" to the full path of the AeroDyn driver executable. Do this by editing the script my_configCADynTurb accordingly.'])
        else
            error(['Please download the AeroDyn standalone driver v3.3.0. Use of CADynTurb cannot continue before this requirement is met. For Ubuntu you can download this program from <a href = "matlab:web(''https://github.com/jgeisler0303/SimpleDynInflow/releases/download/AeroDyn_v3.3.0/aerodyn_driver'')">here</a>.' newline 'Then set the environment variable "AD_driver" to the full path of the AeroDyn driver executable. Do this by editing the script my_configCADynTurb accordingly.'])                   
        end
    end
end
