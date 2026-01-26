function setupCADynTurb(acados_wanted)
arguments
    acados_wanted = false;
end

if strcmp(getenv('CADYNTURB_SETUP'), 'SUCCESS'), return, end

%% check path
CADynTurb_dir= fileparts(fileparts(mfilename('fullpath')));
assignin('base', 'CADynTurb_dir', CADynTurb_dir)

if any(CADynTurb_dir>127) || any(CADynTurb_dir==' ')
    error('The path of your CADynTurb installation contains ASCII characters >127 or spaces. This is currently not supported.')
end

addpath(fullfile(CADynTurb_dir, 'matlab', 'setup'))

%% Try to load the environment variables to determine which ones are missing
try
    my_configCADynTurb
catch e
end

check_installRepositories(CADynTurb_dir)
check_installMaxima(CADynTurb_dir)
check_installAeroDyn_Driver(CADynTurb_dir)
check_installCompiler(CADynTurb_dir)
check_installEigen3(CADynTurb_dir)
check_installIECWind(CADynTurb_dir)
if acados_wanted
    check_installGit(CADynTurb_dir)
    check_installAcados(CADynTurb_dir)
end

%% Paths must be set before we can use AMPoWS
set_path

%% Install OpenFast and make reference simulations
if ~strcmp(getenv('NO_REF_SIM'), 'true')
    if ~exist(fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow'), 'dir') || ~exist(fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow'), 'dir')
        fprintf(['To get started, it is suggested to provide some reference simulations.' newline ...
            'For these you will also need the OpenFAST turbine simulation program.' newline ...
            'In the following you will have the opportunity to download or install this program.' newline ...
            'If you don''t ever want use reference simulations, please set the environment variable "NO_REF_SIM" to "true" in the file "my_configCADynTurb".'])
        if askYesNo('Do you want to proceed with the process to generate reference simulations.', true)
            openfast_path = check_installOpenFAST(CADynTurb_dir);
            turbsim_path = check_installTurbSim(CADynTurb_dir);
            check_installDISCON(CADynTurb_dir)

            makeRefSim(CADynTurb_dir, openfast_path, turbsim_path)
        end
    end
end

%% reload the now hopefully complete environment variables
try
    my_configCADynTurb
catch e
end

setenv('cagem_path', fullfile(CADynTurb_dir, '../CADyn/gen/cagem.mac'))

if ~isempty(getenv('ACADOS_INSTALL_DIR'))
    if ~ispc
        % the following is necessary to make the dynamic linker search for libs in the
        % current directory because MATLAB doesn't pass the LD_LIBRARY_PATH
        % correctly
        Rpath= ['-Wl,--disable-new-dtags,-rpath,\$ORIGIN,-rpath,' getenv('ACADOS_INSTALL_DIR') '/lib'];
        if ~contains(getenv('LDFLAGS'), Rpath)
            setenv('ACADOS_MEX_FLAGS', ['LDFLAGS=$LDFLAGS ' Rpath])
            % this doesn't seem to work:
            setenv('LDFLAGS', [getenv('LDFLAGS') ' ' Rpath])
            % apparently, this gets copied into new mex-files, but it doesnt
            % take immediate effect
            % it makes the libraries in the current folder findable
            setenv('LD_RUN_PATH', ['.:' getenv('ACADOS_INSTALL_DIR') '/lib'])
        end

        % We don't need to run env.sh, its purpose is already fulfilled by the
        % previous setups
        setenv('ENV_RUN', 'true')
    else
        acados_env_variables_windows
    end
end

setenv('CADYNTURB_SETUP', 'SUCCESS')
