function check_installDISCONmex(CADynTurb_dir)
old_dir = pwd;
cd(fullfile(CADynTurb_dir, 'simulator'))
if ~exist(['DISCON_sandbox_mex.' mexext], 'file')
    if ispc
        mex -D_USE_MATH_DEFINES LINKLIBS="$LINKLIBS -lws2_32" DISCON_sandbox_mex.cpp
    else
        mex DISCON_sandbox_mex.cpp
    end
end
if ispc
    exeext = '.exe';
else
    exeext = '';
end
prog_name = ['DISCON_sandbox_worker' exeext];
if ~exist(prog_name, 'file')
    if ispc
        compileProg('DISCON_sandbox_mex.cpp', prog_name, {}, {'DISCON_SANDBOX_WORKER_MAIN'}, {}, {}, {'ws2_32'})
    else
        compileProg('DISCON_sandbox_mex.cpp', prog_name, {}, {'DISCON_SANDBOX_WORKER_MAIN'})
    end
end

cd(old_dir)
