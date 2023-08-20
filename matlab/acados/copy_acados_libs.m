function copy_acados_libs(target)
if ~isunix, return, end

copy_lib('libacados.so', target)
copy_lib('libblasfeo.so', target)
copy_lib('libhpipm.so', target)

function copy_lib(lib, target)
if ~exist(fullfile(target, lib), 'file')
    copyfile(fullfile(getenv("ACADOS_INSTALL_DIR"), 'lib', lib), target)
end