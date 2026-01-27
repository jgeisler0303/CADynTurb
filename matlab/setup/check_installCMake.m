function check_installCMake(CADynTurb_dir)
[res, ~] = system('cmake --version');
if res~=0
    tf_install = askYesNo('You need to install cmake. Do you want to do that automatically?', true);
    if tf_install
        fprintf('Installing cmake ...')
        if ispc
            download_dir = fullfile(CADynTurb_dir, 'downloads');
            [~, ~] = mkdir(download_dir);
            cmake_file = fullfile(download_dir, 'cmake-4.2.2-windows-x86_64.msi');    
            websave(cmake_file, 'https://github.com/Kitware/CMake/releases/download/v4.2.2/cmake-4.2.2-windows-x86_64.msi');
            system(cmake_file);
            % Try to set cmake path temporarily
            setenv('PATH', ['C:\Program Files\CMake\bin;' getenv('PATH')]);
            [res, ~] = system('cmake --version');
            if res~=0
                error('The Installation of CMake was probably successful but the cmake program is not on your path yet. Please restart MATLAB and rerun the setup process.')
            end
        else
            system([
                'env -u LD_LIBRARY_PATH x-terminal-emulator -e ', ...
                'bash -lc "sudo apt update && sudo apt install cmake"'
            ]);
        end
        fprintf('Done.\n')
    else
        if ispc
            error(['Please manually download and install CMake from here: https://github.com/Kitware/CMake/releases/download' newline ...
                'and make sure the path to CMake is added to the system search path (default option).' newline ...
                'Use of CADynTurb with acados cannot continue before this requirement is met.'])
        else
            error(['Please manually install CMake by running "sudo apt update && sudo apt install cmake".' newline ...
                'Use of CADynTurb with acados cannot continue before this requirement is met.'])            
        end
    end    
end
