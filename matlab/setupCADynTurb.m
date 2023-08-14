%% check path
CADynTurb_dir= fileparts(mfilename('fullpath'));
top_dir= fileparts(fileparts(CADynTurb_dir));

if ~exist(fullfile(top_dir, 'CADyn'), 'dir')
    error('Please download CADyn to the folder %s. Go to the folder %s and do: "git clone https:/github.com/jgeisler0303/CADyn.git"', fullfile(top_dir, 'CADyn'), top_dir)
end

if ~exist(fullfile(top_dir, 'FEMBeam'), 'dir')
    error('Please download FEMBeam to the folder %s. Go to the folder %s and do: "git clone https:/github.com/jgeisler0303/FEMBeam.git"', fullfile(top_dir, 'FEMBeam'), top_dir)
end

if ~exist(fullfile(top_dir, 'SimpleDynInflow'), 'dir')
    error('Please download SimpleDynInflow to the folder %s. Go to the folder %s and do: "git clone https:/github.com/jgeisler0303/SimpleDynInflow.git"', fullfile(top_dir, 'SimpleDynInflow'), top_dir)
end

if ~exist(fullfile(top_dir, 'matlab-toolbox'), 'dir')
    error('Please download matlab-toolbox to the folder %s. Go to the folder %s and do: "git clone https://github.com/OpenFAST/matlab-toolbox.git"', fullfile(top_dir, 'matlab-toolbox'), top_dir)
end

%% prepare path
set_path

%% load configuration
configCADynTurb

setenv('cagem_path', fullfile(CADynTurb_dir, '../../CADyn/gen/cagem.mac'))

%% check environment
maxima= getenv('maxima_path');
if isempty(maxima)
    error(['Please install Maxima. For Windows you can download it from <a href = "matlab:web(''https://sourceforge.net/projects/maxima/files/Maxima-Windows/'')">here</a>. For Ubuntu you should install "sudo apt install maxima-sbcl".' newline 'Then set the environment variable "maxima_path" to the full path of the maxima executable (batch file in windows). Do this by editing the script configCADynTurb accordingly.'])
end
[res, msg]= system([maxima ' --version']);
if res~=0 || ~contains(msg, 'Maxima')
    error('The path "%s" does not point to a valid maxima executable', maxima)
end

AD_driver= getenv('AD_DRIVER');
if isempty(AD_driver)
    error(['Please download the AeroDyn standalone driver v3.3.0. For Windows you can download it from <a href = "matlab:web(''https://github.com/jgeisler0303/SimpleDynInflow/releases/download/AeroDyn_v3.3.0/AeroDyn_Driver_x64_Double.exe'')">here</a>. And for Ubuntu from <a href = "matlab:web(''https://github.com/jgeisler0303/SimpleDynInflow/releases/download/AeroDyn_v3.3.0/aerodyn_driver'')">here</a>.' newline 'Then set the environment variable "AD_driver" to the full path of the AeroDyn driver executable. Do this by editing the script configCADynTurb accordingly.'])
end
[res, msg]= system([AD_driver ' -h']);
msg_lines = splitlines(msg);
if res~=0 || ~contains(msg_lines{12}, 'AeroDyn_driver-v3.3.0')
    error('The path "%s" does not point to a valid AeroDyn standalone driver executable', AD_driver)
end

%% check compiler
[res, msg]= system('g++ -v');
if res~=0
    error('Please install g++. On Windows you need to install the MinGW compiler for MATLAB following these instructions: https://de.mathworks.com/help/matlab/matlab_external/install-mingw-support-package.html . On Ubuntu you can run "sudo apt install build-essential".')
end

mc= mex.getCompilerConfigurations;
if ~any(strcmp({mc.Name}, 'g++'))
    error('Please setup up the g++ compiler for the MATLAB mex compiler by running <a href = "matlab:mex -setup)">mex -setup</a>')
end

[res, msg]= system('g++ ../simulator/test_eigen.cpp -o ../simulator/test_eigen');
if res~=0
    error('Please download the eigen3 library from here: https://eigen.tuxfamily.org/index.php?title=Main_Page and copy everything from the zip file to your gcc (MinGW) compilers include directory.')
end

%% check reference simulations
if ~exist(fullfile(CADynTurb_dir, '../ref_sim/sim_dyn_inflow'), 'dir') || ~exist(fullfile(CADynTurb_dir, '../ref_sim/sim_no_inflow'), 'dir')
    warning(['No reference simulations with dynamic inflow condition found. To create them please click <a href= "matlab:makeRefSim">here</a>.' newline ...
        'If you don''t want to see this warning again, just create empty directories "ref_sim/sim_dyn_inflow" and "ref_sim/sim_no_inflow" in the CADynTurb directory.'])
end