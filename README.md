# Getting Started
Clone this and the following repositiries into the same parent directory:
``` bash
git clone https://github.com/jgeisler0303/CADynTurb.git
git clone https://github.com/jgeisler0303/CCBlade-M.git
git clone https://github.com/jgeisler0303/CADyn.git
git clone https://github.com/OpenFAST/matlab-toolbox.git
git clone https://github.com/jgeisler0303/FEMBeam.git
```

Open `set_path` and edit the `setenv('maxima_path', '/usr/bin/maxima')` according to your installation of Maxima. Then run the `testFAST2CADynTurb`.

It will:
* Setup the search path to all required repositories,
* Calculate the mechanical and aerodynamic parameters for the CADyn model from the supplied 5MW OpenFAST configuration,
* Generate CADyn representations of the elastic bodies, i.e. the tower and the blades,
* Generate the CADyn model and compile it into a standalone simulator,
* Run a simulation and plot the result
