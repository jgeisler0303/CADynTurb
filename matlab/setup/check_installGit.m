function check_installGit(CADynTurb_dir)
[res, ~] = system('git --version');
if res~=0
    tf_install = askYesNo('You need to install git. Do you want to do that automatically?', true);
    if tf_install
        fprintf('Installing git ...')
        if ispc
            download_dir = fullfile(CADynTurb_dir, 'downloads');
            [~, ~] = mkdir(download_dir);
            git_file = fullfile(download_dir, 'Git-2.52.0-64-bit.exe');    
            websave(git_file, 'https://github.com/git-for-windows/git/releases/download/v2.52.0.windows.1/Git-2.52.0-64-bit.exe');
            system(git_file);
            % Try to set PATH temporarily
            setenv('PATH', ['C:\Program Files\Git\bin' getenv('PATH')]);
            [res, ~] = system('git --version');
            if res~=0
                error('The Installation of git was probably successful but the git program is not on your path yet. Please restart MATLAB and rerun the setup process.')
            end
        else
            system([
                'env -u LD_LIBRARY_PATH x-terminal-emulator -e ', ...
                'bash -lc "sudo apt update && sudo apt install git"'
            ]);
        end
        fprintf('Done.\n')
    else
        if ispc
            error(['Please manually download and install Git from here: https://github.com/git-for-windows/git/releases/download/v2.52.0.windows.1/Git-2.52.0-64-bit.exe' newline ...
                'Use of CADynTurb with acados cannot continue before this requirement is met.'])
        else
            error(['Please manually install CMake by running "sudo apt update && sudo apt install git".' newline ...
                'Use of CADynTurb with acados cannot continue before this requirement is met.'])            
        end
    end    
end
