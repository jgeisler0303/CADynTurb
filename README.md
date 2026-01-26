# Intro
CADynTurb is a collection of MATLAB functions, C++ source code and Maxima scripts to fully automatically generate simplified wind turbine models and the parameters to match the model behavior with a given OpenFAST model configuration. The models are generated as C++ code, linear and nonlinear MATLAB code and acados (https://docs.acados.org/) python code. The C++ code has its own Solver and can be compiled as a MATLAB mex function or a standalone executable that is able to run a co-simulation with a DISCON controller dll.

The Solver is also able to compute the sensitivity matrices (Jacobians) which makes it possible to integrate the models into optimizations procedures. One such application are state observers. CADynTurb includes special adapter code to directly compile an extended Kalman filter from a generated model. The Kalman filter is compiled as a mex function and includes a special auto-tunig procedure for optimal selection of the process and noise covariance matrices.

The simplified models are composed of a multi-body model with a modal representation of the elastic tower and blades and a modular aerodynamics model based on look-up-tables of the aerodynamic coefficients. The aerodynamics model can include many influences such as tower movement, modal blade excitation, aerodynamic damping of the blades and tower side-side excitation. For further details, please see

* [Multi-body modeling](https://wes.copernicus.org/articles/7/2351/2022/)
* [Multi-body modeling (presentation slides)](https://zenodo.org/record/5148442)
* [Simplified aerodynamics (presentation slides)](https://zenodo.org/record/5148448)

# Getting Started
CADynTurb has an automatic setup and installation process. You simply need to clone this repository or download and unpack the zip-file. Then start MATLAB and open one of the testFAST2CADynTurb_XYZ.m scripts in the models subdirectories. When you run these scripts a setup procedure is initiated that guides you through the download and installation of all required dependencies.

The whole process may take some time, maybe up to two hours, depending on the speed of your computer and internet connection. At each step you are asked if you want to continue. So you have to attend the entire process. If you quit at any time you will get instructions how to continue manually. But you cannot use CADynTurb or get results from the testFAST2CADynTurb_XYZ.m before all setup step have been finished.

The setup was tested with Windows 11, Ubuntu 24.04 and MATLAB 2025a.

It is recommended to start exploring with the ``model/T1/testFAST2CADynTurb_T1.m``.
