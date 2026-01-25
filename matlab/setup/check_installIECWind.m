function check_installIECWind(CADynTurb_dir)
iecwind_file = fullfile(CADynTurb_dir, '..', 'AMPoWS', 'Matlab', 'pre_processing', 'iecwind');
[res, msg] = system(iecwind_file);
if res~=0
    tf_install = askYesNo('You need to download and compile the iecwind program. Do you want to do that automatically?', true);
    if tf_install
        iecwind_repo = fullfile(CADynTurb_dir, '..', 'IECWind');
        fprintf('Cloning IECWind ... ')
        gitclone('https://github.com/BecMax/IECWind.git', iecwind_repo);
        fprintf('Done.\n')
        
        fprintf('Compiling IECWind ... ')
        mc = mex.getCompilerConfigurations('C', 'Selected');
        compiler = strrep(mc.Details.CompilerExecutable, 'gcc', 'gfortran');
        old_dir = pwd;
        cd(fullfile(iecwind_repo, 'Source'))
        if ispc
            iecwind_file = 'iecwind.exe';
        else
            iecwind_file = 'iecwind';
        end
        system([compiler ' -static-libgfortran -static-libgcc IECwind.f90 -o ' iecwind_file])
        movefile(iecwind_file, fullfile(CADynTurb_dir, '..', 'AMPoWS', 'Matlab', 'pre_processing', iecwind_file))
        cd(old_dir)
        fprintf('Done.\n')        
    else
        error('Please manually clone the repo https://github.com/BecMax/IECWind.git, build the source file and move it to the AMPoWS/Matlab/pre_processing folder. Use of CADynTurb cannot continue before this requirement is met.')
    end
end