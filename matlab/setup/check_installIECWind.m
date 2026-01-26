function check_installIECWind(CADynTurb_dir)
if ispc
    iecwind_file = 'iecwind.exe';
else
    iecwind_file = 'iecwind';
end
iecwind_path = fullfile(CADynTurb_dir, '..', 'AMPoWS', 'Matlab', 'pre_processing', iecwind_file);
[res, msg] = system(iecwind_path);
if res~=0
    tf_install = askYesNo('You need to download and compile the iecwind program. Do you want to do that automatically?', true);
    if tf_install
        iecwind_repo = fullfile(CADynTurb_dir, '..', 'IECWind');
        if ~exist(iecwind_repo, 'dir')
            fprintf('Cloning IECWind ... ')
            gitclone('https://github.com/BecMax/IECWind.git', iecwind_repo);
            fprintf('Done.\n')
        end        
        fprintf('Compiling IECWind ... ')
        mc = mex.getCompilerConfigurations('C', 'Selected');
        compiler = strrep(mc.Details.CompilerExecutable, 'gcc', 'gfortran');
        old_dir = pwd;
        cd(fullfile(iecwind_repo, 'Source'))
        cmd = sprintf('"%s"  -static-libgfortran -static-libgcc IECwind.f90 -o "%s"', compiler, iecwind_file);
        system(cmd)
        movefile(iecwind_file, fullfile(CADynTurb_dir, '..', 'AMPoWS', 'Matlab', 'pre_processing', iecwind_file))
        cd(old_dir)
        if ispc
            libquadmath_path = fullfile(fileparts(mc.Details.CompilerExecutable), 'libquadmath-0.dll');
            copyfile(libquadmath_path, fileparts(iecwind_path))
        end
        fprintf('Done.\n')        
    else
        error('Please manually clone the repo https://github.com/BecMax/IECWind.git, build the source file and move it to the AMPoWS/Matlab/pre_processing folder. Use of CADynTurb cannot continue before this requirement is met.')
    end
end