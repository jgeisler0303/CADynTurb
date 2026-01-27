function checkMatlabLib

if isunix
    lib_file = fullfile(matlabroot, 'sys/os/glnxa64/libstdc++.so.6');
    if exist(lib_file, 'file')
        tf = askYesNo('MATLAB brings its own libstdc++ that often causes trouble. Do you want to remove this lib by renaming it to .bak?', true);
        if tf
            fprintf('Renaming %s to %s.bak ...', lib_file, lib_file)
            system([
                'env -u LD_LIBRARY_PATH x-terminal-emulator -e ', ...
                'bash -lc "sudo mv ' lib_file ' ' lib_file '.bak"'
            ]);

            fprintf('Done.\n')
        end
    end
end
