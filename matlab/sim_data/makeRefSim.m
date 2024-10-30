CADynTurb_dir= fileparts(fileparts(fileparts(mfilename('fullpath'))));


%% check for AMPoWS
if ~exist(fullfile(top_dir, 'AMPoWS'), 'dir')
    error('Please download AMPoWS to the folder %s. Go to the folder %s and do: "git clone https://github.com/jgeisler0303/AMPoWS.git"', fullfile(top_dir, 'AMPoWS'), top_dir)
end

%% check for OpenFAST and turbsim executable
openfast_exe= getenv('OPENFAST');
if isempty(openfast_exe)
    error(['Please download OpenFAST v3.3.0. For Windows you can download it from <a href = "matlab:web(''https://github.com/OpenFAST/openfast/releases/download/v3.3.0/openfast_x64.exe'')">here</a>. ' ...
        'Additionally, you need to install the Intel Fortran redistributable package version 2023.2.4/2021.10.0 which you can download from <a href = "matlab:web(''https://www.intel.com/content/www/us/en/developer/articles/tool/compilers-redistributable-libraries-by-version.html'')">here</a>.' newline ...
        'For Ubuntu you will have to build it yourself by following <a href = "matlab:web(''https://openfast.readthedocs.io/en/main/source/install/index.html#compile-from-source'')">these</a> instructions. ' ...
        'Make sure you checkout the v3.3.0 version from the repo ("git checkout v3.3.0")' newline ...
        'Finally set the environment variable "OPENFAST" to the full path of the OpenFAST executable. Do this by editing the script configCADynTurb accordingly.'])
end
[res, msg]= system([openfast_exe ' -h']);
msg_lines = splitlines(msg);
if res~=0 || ~contains(msg_lines{12}, 'OpenFAST-v3.3.0')
    error('The path "%s" does not point to a valid OpenFAST v3.3.0 executable', openfast_exe)
end

turbsim_exe= getenv('TURBSIM');
if isempty(turbsim_exe)
    error(['Please download turbsim v3.3.0. For Windows you can download it from <a href = "matlab:web(''https://github.com/OpenFAST/openfast/releases/download/v3.3.0/TurbSim_x64.exe'')">here</a>. ' ...
        'Additionally, you need to install the Intel Fortran redistributable package which you can download from <a href = "matlab:web(''https://software.intel.com/content/www/us/en/develop/articles/redistributable-libraries-for-intel-c-and-fortran-2020-compilers-for-windows.html'')">here</a>.' newline ...
        'For Ubuntu you will have to build it yourself by following <a href = "matlab:web(''https://openfast.readthedocs.io/en/main/source/install/index.html#compile-from-source'')">these</a> instructions. ' ...
        'Make sure you checkout the v3.3.0 version from the repo ("git checkout v3.3.0")' newline ...
        'Finally set the environment variable "TURBSIM" to the full path of the OpenFAST executable. Do this by editing the script configCADynTurb accordingly.'])
end
[res, msg]= system([turbsim_exe ' -h']);
msg_lines = splitlines(msg);
if res~=0 || ~contains(msg_lines{12}, 'TurbSim-v3.3.0')
    error('The path "%s" does not point to a valid TurbSim v3.3.0 executable', turbsim_exe)
end

if ~exist(fullfile(CADynTurb_dir, '5MW_Baseline/DISCON.dll'), 'file')
    error(['The download or compile the file DISCON.dll and copied it to the `5MW_Baseline` subfolder of CADynTurb. ' ...
        'For Windows you can download it from <a href = "matlab:web(''https://github.com/OpenFAST/openfast/releases/download/v3.3.0/Discon.dll'')">here</a>. ' ...
        'For Ubuntu you will have to build it yourself by following <a href = "matlab:web(''https://openfast.readthedocs.io/en/main/source/install/index.html#compile-from-source'')">these</a> instructions. '])
end

%% generate simulation configurations
if ~exist(fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow'), 'dir')
    openFAST_preprocessor(fullfile(CADynTurb_dir, 'ref_sim/openFAST_config_dyn_inflow.xlsx'), openfast_exe, turbsim_exe);
end
if ~exist(fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow'), 'dir')
    openFAST_preprocessor(fullfile(CADynTurb_dir, 'ref_sim/openFAST_config_no_inflow.xlsx'), openfast_exe, turbsim_exe);
end

%% run turbsim for 12m/s
old_dir= cd(fullfile(CADynTurb_dir, 'ref_sim/wind'));
cleanupObj = onCleanup(@()cd(old_dir));

if ~exist(fullfile(CADynTurb_dir, 'ref_sim/wind/NTM_URef-12_turbsim.bts'), 'file')
    system([turbsim_exe ' NTM_URef-12_turbsim.inp'])
end

%% make additional wind file for rotor average and shear
if ~exist(fullfile(CADynTurb_dir, 'ref_sim/wind/NTM_URef-12_turbsim_shear.bts'), 'file')
    dd= dir(fullfile(CADynTurb_dir, 'ref_sim/wind/NTM_URef-*_turbsim.bts'));
    makeCoherentBTS(fullfile(CADynTurb_dir, 'ref_sim/wind', {dd.name}), 63, 1);
end

%% run openfast for 12m/s with dynamic inflow
if ~exist(fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow/impulse_URef-12_maininput.outb'), 'file')
    cd(fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow'))
    system([openfast_exe ' impulse_URef-12_maininput.fst'])
end
if ~exist(fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow/1p1_NacYaw-0_URef-12_maininput.outb'), 'file')
    cd(fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow'))
    system([openfast_exe ' 1p1_NacYaw-0_URef-12_maininput.fst'])
end

%% run openfast for 12m/s without dynamic inflow
if ~exist(fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow/impulse_URef-12_maininput.outb'), 'file')
    cd(fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow'))
    system([openfast_exe ' impulse_URef-12_maininput.fst'])
end
if ~exist(fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow/1p1_NacYaw-0_URef-12_maininput.outb'), 'file')
    cd(fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow'))
    system([openfast_exe ' 1p1_NacYaw-0_URef-12_maininput.fst'])
end