if strcmp(getenv('CADYNTURB_SETUP'), 'SUCCESS'), return, end

%% check path
CADynTurb_dir= fileparts(fileparts(mfilename('fullpath')));
top_dir= fileparts(CADynTurb_dir);

if any(CADynTurb_dir>127) || any(CADynTurb_dir==' ')
    error('The path of your CADynTurb installation contains ASCII characters >127 or spaces. This is currently not supported.')
end

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

if ~exist(fullfile(top_dir, 'AMPoWS'), 'dir')
    warning('If you want to generate the OpenFAST reference simulations, you need to download AMPoWS to the folder %s. Go to the folder %s and do: "git clone https://github.com/jgeisler0303/AMPoWS.git"', fullfile(top_dir, 'AMPoWS'), top_dir)
end

%% prepare path
set_path

%% load configuration
configCADynTurb
try
    my_configCADynTurb
catch e
end

setenv('cagem_path', fullfile(CADynTurb_dir, '../CADyn/gen/cagem.mac'))

%% check environment
maxima= getenv('maxima_path');
if isempty(maxima)
    if ispc
        error(['Please install Maxima. You can download it from <a href = "matlab:web(''https://sourceforge.net/projects/maxima/files/Maxima-Windows/'')">here</a>.' newline 'Then set the environment variable "maxima_path" to the full path of the maxima batch file (this will be something like ""). Do this by editing the script configCADynTurb accordingly.'])
    else
        error(['Please install Maxima version 5.44 in the sblc flavor. You can download it from <a href = "matlab:web(''https://sourceforge.net/projects/maxima/files/Maxima-Linux/5.44.0-Linux/'')">here</a>. You have to download and install the files "maxima-sbcl_5.44.0-1_{arch}.{deb|rpm}" and "maxima-common_5.44.0-1_all.{deb|rpm}". After download, on Ubuntu install via "dpkg -i {debname}". Do not install the official Ubuntu package ("sudo apt install maxima")!.' newline 'Then set the environment variable "maxima_path" to the full path of the maxima executable ("/usr/bin/maxima"). Do this by editing the script configCADynTurb accordingly.'])        
    end
end
[res, msg]= system([maxima ' --version']);
if res~=0 || ~contains(msg, 'Maxima')
    error('The path "%s" does not point to a valid maxima executable', maxima)
end

%% currently disabled because rducon seems to be broken
% check for maxima patch
% command_str= [maxima ' --batch-string="load(rducon)\$ declare(a, constant)\$ reduce_consts(a^2*x);"'];
% [status, res]= system(command_str);
% if contains(res, 'error')
%     if ispc
%         warning(['If you want to use pre-calculated constants (argument reduce_consts of function genCode) you have to edit the file "' fileparts(fileparts(maxima)) '\share\maxima\5.46.0\share\numeric\expense.lisp". Find the line "(defun multiplies-in-nth-power (nth)" and delete it and the following lines up to the line starting with ";;;". Then insert the follwing:' newline ...
%             '(defun multiplies-in-nth-power (n)' newline ...
%             '    "Calculate the number of multiplications required to compute a^n."' newline ...
%             '    (let ((multiplications 0)' newline ...
%             '    (power n))' newline ...
%             '        (while (> power 1)' newline ...
%             '        (if (evenp power)' newline ...
%             '            (progn' newline ...
%             '                (setq power (/ power 2))' newline ...
%             '                (incf multiplications)) ; Counting the squaring operation' newline ...
%             '            (progn' newline ...
%             '                (setq power (- power 1))' newline ...
%             '                (incf multiplications) ; Counting the multiplication to reduce the power' newline ...
%             '        )))' newline ...
%             '        (cond ((< multiplications $cost_float_power) multiplications)' newline ...
%             '            (t $cost_float_power))  ' newline ...   
%             '))'])
%     else
%         warning('If you want to use pre-calculated constants (argument reduce_consts of function genCode) you have to patch the file "/usr/share/maxima/5.44.0/share/numeric/expense.lisp" with the patch file in "matlab/gen" folder. (Run "sudo patch /usr/share/maxima/5.44.0/share/numeric/expense.lisp < %s/matlab/gen/expense.lisp.patch")', CADynTurb_dir)
%     end
% end

%% Check for Aerodyn driver
AD_driver= getenv('AD_DRIVER');
if isempty(AD_driver)
    error(['Please download the AeroDyn standalone driver v3.3.0. For Windows you can download it from <a href = "matlab:web(''https://github.com/jgeisler0303/SimpleDynInflow/releases/download/AeroDyn_v3.3.0/AeroDyn_Driver_x64_Double.exe'')">here</a>. Additionally you need to install the Intel Fortran Compiler Runtime for Windows version 2023.2.4/2021.10.0 from <a href = "matlab:web(''https://www.intel.com/content/www/us/en/developer/articles/tool/compilers-redistributable-libraries-by-version.html'')">here</a>. For Ubuntu you can download this program from <a href = "matlab:web(''https://github.com/jgeisler0303/SimpleDynInflow/releases/download/AeroDyn_v3.3.0/aerodyn_driver'')">here</a>.' newline 'Then set the environment variable "AD_driver" to the full path of the AeroDyn driver executable. Do this by editing the script configCADynTurb accordingly.'])
end
[res, msg]= system([AD_driver ' -h']);
msg_lines = splitlines(msg);
if ispc
    if res~=0
        error('There is a problem with the AeroDyn standalone driver executable. The cause is often that the libiomp5md.dll from the Intel Fortran compiler cannot be found. Try to copy the DLL into the directory of the AeroDyn program, it should be somewhere in the folders "C:\Program Files (x86)\Common Files\intel" or "C:\Program Files (x86)\Intel\oneAPI\compiler".')
    end
    if ~contains(msg_lines{12}, 'AeroDyn_driver-v3.3.0')
        error('The path "%s" does not point to a valid version 3.3.0 AeroDyn standalone driver executable', AD_driver)
    end
else
    if res~=0 || ~contains(msg_lines{12}, 'AeroDyn_driver-v3.3.0')
        error('The path "%s" does not point to a valid version 3.3.0 AeroDyn standalone driver executable', AD_driver)
    end
end

%% check compiler
mc= mex.getCompilerConfigurations;
if ispc
    idx_gpp= strcmp({mc.Name}, 'MinGW64 Compiler (C++)');
    if ~any(idx_gpp)
        error('Please install the MinGW64 Compiler via MATLAB Add-Ons and setup up the compiler for the MATLAB mex by running <a href = "matlab:mex -setup)">mex -setup</a>')
    end
    syspath= getenv('PATH');
    syspaths= split(syspath, ';');
    cpppath= fileparts(mc(find(idx_gpp)).Details.CompilerExecutable);
    if ~any(strcmp(cpppath, syspaths))
        setenv('PATH', [cpppath ';' syspath])
    end
else
    idx_gpp= strcmp({mc.Name}, 'g++');
    if ~any(idx_gpp)
        error('Please setup up the g++ compiler for the MATLAB mex compiler by running <a href = "matlab:mex -setup)">mex -setup</a>')
    end
end
setenv('CPP', mc(find(idx_gpp)).Details.CompilerExecutable)

[res, msg]= system([getenv('CPP') ' ' fullfile(CADynTurb_dir, 'simulator/test_eigen.cpp') ' -o ' fullfile(CADynTurb_dir, 'simulator/test_eigen')]);

if res~=0
    if ispc
        [res, msg]= system(['echo "" | ' getenv('CPP') ' -Wp,-v -x c++ - -fsyntax-only']);
        msg_lines = splitlines(msg);
        start_line= find(contains(msg_lines, '#include <...> search starts here:'));
        end_line= find(contains(msg_lines, 'End of search list.'));
        if ~isempty(start_line) && ~isempty(end_line)
            include_dirs= [10 'Possible include directories could be:' 10];
            for i= start_line+1:end_line-1
                include_dirs= [include_dirs msg_lines{i} 10];
            end
        else
            include_dirs= [];
        end
        error(['Please download version 3.3.9 (!) of the eigen3 library from here: https://eigen.tuxfamily.org/index.php?title=Main_Page and copy the "Eigen" and the "unsupported" folder from the zip file to your gcc (MinGW) compilers include directory.' include_dirs])
    else
        error('Please download version 3.3.9 (!) of the eigen3 library from here: https://eigen.tuxfamily.org/index.php?title=Main_Page and copy the "Eigen" and the "unsupported" from the zip file to your gcc include directory (on Ubuntu that would be /usr/local/include).')
    end
end

%% check reference simulations
if ~exist(fullfile(CADynTurb_dir, 'ref_sim/sim_dyn_inflow'), 'dir') || ~exist(fullfile(CADynTurb_dir, 'ref_sim/sim_no_inflow'), 'dir')
    warning(['No reference simulations with dynamic inflow condition found. To create them please click <a href= "matlab:makeRefSim">here</a>.' newline ...
        'If you don''t want to see this warning again, just create empty directories "ref_sim/sim_dyn_inflow" and "ref_sim/sim_no_inflow" in the CADynTurb directory.'])
end

%% check acados
if isempty(getenv('ACADOS_INSTALL_DIR')) && isempty(getenv('NO_ACADOS'))
    warning(['acados doesn''t seem to be installed. acados examples will not work. ' newline ...
        'To install acados, please follow <a href = "matlab:web(''https://docs.acados.org/installation/'')">these</a> instructions. ' newline ...
        'And then <a href = "matlab:web(''https://docs.acados.org/matlab_octave_interface/index.html#setup-casadi'')">these</a> instructions. ' newline ...
        'Then set the environment variable "ACADOS_INSTALL_DIR" to the path of the acados base directory. Do this by editing the script configCADynTurb accordingly. ' newline ...
        'If you don''t want to see this message again, set the environment variable "NO_ACADOS" in the configCADynTurb script to "yes".'])
end
if ~isempty(getenv('ACADOS_INSTALL_DIR'))
    if isunix
        acadoslib= fullfile(getenv('ACADOS_INSTALL_DIR'), 'lib/libacados.so');
    else
        acadoslib= fullfile(getenv('ACADOS_INSTALL_DIR'), 'lib/libacados.dll');
    end        
    if ~exist(acadoslib, 'file')
        error(['The environment variable "ACADOS_INSTALL_DIR" is set but acados doesn''t seem to be installed properly (libacados not found).' newline ...
        'To install acados, please follow <a href = "matlab:web(''https://docs.acados.org/installation/'')">these</a> instructions. ' newline ...
        'And then <a href = "matlab:web(''https://docs.acados.org/matlab_octave_interface/index.html#setup-casadi'')">these</a> instructions.'])
    end
    casadi_mex= fullfile(getenv('ACADOS_INSTALL_DIR'), ['external/casadi-matlab/casadiMEX.' mexext]);
    if ~exist(casadi_mex, 'file')
        error(['The environment variable "ACADOS_INSTALL_DIR" is set but acados doesn''t seem to be installed properly (CasADi mex function not found).' newline ...
        'To install CasADi, please follow  <a href = "matlab:web(''https://docs.acados.org/matlab_octave_interface/index.html#setup-casadi'')">these</a> instructions.'])
    end
    
    addpath(fullfile(getenv('ACADOS_INSTALL_DIR'), 'examples', 'acados_matlab_octave', 'getting_started'))
    addpath(fullfile(getenv('ACADOS_INSTALL_DIR'), 'interfaces/acados_matlab_octave'));
    addpath(fullfile(getenv('ACADOS_INSTALL_DIR'), 'interfaces/acados_matlab_octave/acados_template_mex'));
    addpath(fullfile(getenv('ACADOS_INSTALL_DIR'), 'external/casadi-matlab'))
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
end

%%
setenv('CADYNTURB_SETUP', 'SUCCESS')
