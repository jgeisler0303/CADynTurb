# Video Tutorial
You can watch a tutorial showing you all of the following steps here: https://youtu.be/QwgTmSUtoPY

And here is a tutorial that explains the model definition file, the external forces file and the stand alone simulation program by showing what needs to be done to create a more simplified four degrees of freedom model from the already existing six degrees of freedom model:  https://youtu.be/_flxpCukBiI

# Getting Started
You need to install Maxima from here: https://sourceforge.net/projects/maxima/files/ . Windows you may choose to install the GUI wxMaxima from here: https://sourceforge.net/projects/wxmaxima/files/ this will install the commandline verion as well.

On Windows you will also need to install the MinGW compiler for MATLAB following these instructions: https://de.mathworks.com/help/matlab/matlab_external/install-mingw-support-package.html .

Then you need to install the eigen3 library from here: https://eigen.tuxfamily.org/index.php?title=Main_Page . Basically you can just copy everything from the zip file to your gcc (MinGW) compilers include directory. But there are also cmake based installations scripts.

In order to run the turbine simulation, you will need the controller DISCON.dll shared library from the OpenFAST project. If you don't have it already, you will have to compile it yourself. Download or clone the OpenFAST code from this repo: https://github.com/OpenFAST/openfast . Go to the `OpenFAST/share/discon` folder and run `mkdir build`, then `cd build`, `cmake ..`, `make` and finally copy the compiled file `DISCON.dll` to the `5MW_Baseline` subfolder of the CADynTurb package.

With all these programs setup, you can clone all of the following repositiries into the same parent directory:
``` bash
git clone https://github.com/jgeisler0303/CADynTurb.git
git clone https://github.com/jgeisler0303/CCBlade-M.git
git clone https://github.com/jgeisler0303/CADyn.git
git clone https://github.com/OpenFAST/matlab-toolbox.git
git clone https://github.com/jgeisler0303/FEMBeam.git
```

Then start MATLAB, go to the `CCBlade-M` directory and run `makeCCBlade_mex`.
Then go to the `CADynTurb/matlab` directory. Open `set_path` and edit the line `setenv('maxima_path', '/usr/bin/maxima')` according to your installation of Maxima. Then run the `testFAST2CADynTurb`.

It will:
* Setup the search path to all required repositories,
* Calculate the mechanical and aerodynamic parameters for the CADyn model from the supplied 5MW OpenFAST configuration,
* Generate CADyn representations of the elastic bodies, i.e. the tower and the blades,
* Generate the CADyn model and compile it into a standalone simulator,
* Run a simulation and plot the result

Note: in linux there is a problem with running programs from within matlab. If you get an error message about `/usr/local/MATLAB/R2020b/sys/os/glnxa64/libstdc++.so.6: version 'GLIBCXX_3.4.26' not found`, you should comment line 23, uncomment line 24 and edit the `LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6` part to your `libstdc++` path.
