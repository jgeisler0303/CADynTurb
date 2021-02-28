# Getting Started
Clone this and the following repositiries into the same parent directory:
``` bash
git clone https://github.com/jgeisler0303/CADynTurb.git
git clone https://github.com/jgeisler0303/CCBlade-M.git
git clone https://github.com/jgeisler0303/CADyn.git
git clone https://github.com/OpenFAST/matlab-toolbox.git
git clone https://github.com/jgeisler0303/FEMBeam.git
```

Go to `CCBlade-M` directory and run `makeCCBlade_mex`.
Got to  `CADynTurb/matlab` directory. Open `set_path` and edit the `setenv('maxima_path', '/usr/bin/maxima')` according to your installation of Maxima. Then run the `testFAST2CADynTurb`.

It will:
* Setup the search path to all required repositories,
* Calculate the mechanical and aerodynamic parameters for the CADyn model from the supplied 5MW OpenFAST configuration,
* Generate CADyn representations of the elastic bodies, i.e. the tower and the blades,
* Generate the CADyn model and compile it into a standalone simulator,
* Run a simulation and plot the result

Note: in linux there is a problem with running programs from within matlab. If you get an error message about `/usr/local/MATLAB/R2020b/sys/os/glnxa64/libstdc++.so.6: version 'GLIBCXX_3.4.26' not found`, you should comment line 23, uncomment line 24 and edit the `LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6` part to your `libstdc++` path.
