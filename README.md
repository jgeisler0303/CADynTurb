# Intro
CADynTurb is a collection of MATLAB functions, C++ source code and Maxima scripts to fully automatically generate simplified wind turbine models and the parameters to match the model behavior with a given OpenFAST model configuration. The models are generated as C++ code, linear and nonlinear MATLAB code and acados (https://docs.acados.org/) python code. The C++ code has its own Solver and can be compiled as a MATLAB mex function or a standalone executable that is able to run a co-simulation with a DISCON controller dll.

The Solver is also able to compute the sensitivity matrices (Jacobians) which makes it possible to integrate the models into optimizations procedures. One such application are state observers. CADynTurb includes special adapter code to directly compile an extended Kalman filter from a generated model. The Kalman filter is compiled as a mex function and includes a special auto-tunig procedure for optimal selection of the process and noise covariance matrices.

The simplified models are composed of a multi-body model with a modal representation of the elastic tower and blades and a modular aerodynamics model based on look-up-tables of the aerodynamic coefficients. The aerodynamics model can include many influences such as tower movement, modal blade excitation, aerodynamic damping of the blades and tower side-side excitation. For further details, please see
* https://wes.copernicus.org/articles/7/2351/2022/
* https://zenodo.org/record/5148442
* https://zenodo.org/record/5148448

# Getting Started
## Repos and programs to install
To use CADynTurb, you also need to download/clone the following repositories, preferably to the same common parent directory:
``` bash
git clone https://github.com/jgeisler0303/CADynTurb.git
git clone https://github.com/jgeisler0303/SimpleDynInflow.git
git clone https://github.com/jgeisler0303/CADyn.git
git clone https://github.com/OpenFAST/matlab-toolbox.git
git clone https://github.com/jgeisler0303/FEMBeam.git
```

To calculate the aerodynamic parameters, you need the OpenFAST AeroDyn standalone driver v3.3.0. For Windows you can download it from https://github.com/jgeisler0303/SimpleDynInflow/releases/download/AeroDyn_v3.3.0/AeroDyn_Driver_x64_Double.exe. And for Ubuntu from https://github.com/jgeisler0303/SimpleDynInflow/releases/download/AeroDyn_v3.3.0/aerodyn_driver. The full path of the AeroDyn driver executable must be supplied in the environment variable `AD_driver` e.g. by editing the script configCADynTurb accordingly.

To generate the model code, you need to install Maxima. For Windows you can download it from https://sourceforge.net/projects/maxima/files/Maxima-Windows. For Ubuntu you should install  `sudo apt install maxima-sbcl`. The full path of the maxima executable (batch file in windows) must be supplied in the environment variable `maxima_path` e.g. by editing the script configCADynTurb accordingly.

To compile the models, you need to install g++. On Windows you need to install the MinGW compiler for MATLAB following these instructions: https://de.mathworks.com/help/matlab/matlab_external/install-mingw-support-package.html . On Ubuntu you can run `sudo apt install build-essential`.

Further, you need to install the eigen3 library from here: https://eigen.tuxfamily.org/index.php?title=Main_Page . Basically you can just copy everything from the zip file to your gcc (MinGW) compilers include directory. But there are also cmake based installations scripts.

## Reference simulations
If you want to generate the reference data, you will also have to download/clone this repo:
``` bash
git clone https://github.com/jgeisler0303/AMPoWS.git
```

In order to run the reference simulations, you will need the version 3.3.0 of the OpenFAST executabel, TurbSim executable and the controller DISCON.dll shared library from the OpenFAST project. For Windows you can download it from these from: https://github.com/OpenFAST/openfast/releases/download/v3.3.0.

For Ubuntu you will have to build it yourself by following these instructions:  https://openfast.readthedocs.io/en/main/source/install/index.html#compile-from-source . Basically, you need to 
``` bash
sudo apt install git cmake libblas-dev liblapack-dev gfortran-10 g++
git clone https://github.com/OpenFAST/openfast.git
git checkout v3.3.0
cd OpenFAST
mkdir build
cd build
cmake ..
make
cd ..
cd share/discon
mkdir build
cd build
cmake ..
make
```

The downloaded or compiled file `DISCON.dll` must be copied to the `5MW_Baseline` subfolder of CADynTurb.
The full path of the OpenFAST executable must be supplied in the environment variable `OPENFAST`. The full path of the TurbSim executable must be supplied in the environment variable `TURBSIM`. Do this by editing the script configCADynTurb accordingly.

## Running examples
Now you can run any of the `testFAST2CADynTurb...` scripts in the `model` directories.

They will:
* Setup the search path to all required repositories,
* Calculate the mechanical and aerodynamic parameters for the CADyn model from the supplied 5MW OpenFAST configuration,
* Generate CADyn representations of the elastic bodies, i.e. the tower and the blades,
* Generate the CADyn model and compile it into a standalone simulator resp. state observer,
* Run a simulation and plot the result
