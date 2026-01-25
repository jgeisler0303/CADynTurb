function check_installDISCON(CADynTurb_dir)
discon_path = fullfile(CADynTurb_dir, '5MW_Baseline/DISCON.dll');
if ~exist(discon_path, 'file')
    if ispc
        tf_install = askYesNo('You need to have a DISCON.dll controller in your CADynTurb/5MW_Baseline directory. Do you want to download that automatically?', true);
    else
        % We rely on check_installOpenFAST being called first and turbsim
        % already being built
        discon_built = fullfile(CADynTurb_dir, '..', 'OpenFAST', 'share', 'discon' , 'build_330', 'DISCON.dll');
        tf_install = exist(discon_built, 'file');
    end
    if ~tf_install
        tf_choose = askYesNo('Do you want to choose the path to the DISCON.dll?', true);
    end
    if tf_install
        if ispc
            fprintf('Downloading DISCON.dll ... ')
            websave(discon_path, 'https://github.com/OpenFAST/openfast/releases/download/v3.3.0/Discon.dll');
            fprintf('Done.\n')
        else
            copyfile(discon_built, discon_path)
        end
    end
    if ~tf_install && ~tf_choose
        if ispc
            error(['The download or compile the file DISCON.dll and copied it to the `5MW_Baseline` subfolder of CADynTurb. ' ...
                'You can download it from <a href = "matlab:web(''https://github.com/OpenFAST/openfast/releases/download/v3.3.0/Discon.dll'')">here</a>.']);
        else
            error(['Compile the file DISCON.dll and copied it to the `5MW_Baseline` subfolder of CADynTurb. ' ...
                'Do this by following <a href = "matlab:web(''https://openfast.readthedocs.io/en/main/source/install/index.html#compile-from-source'')">these</a> instructions.'])
        end            
    end
end



end

% TODO_ maybe make this more sofisticated
