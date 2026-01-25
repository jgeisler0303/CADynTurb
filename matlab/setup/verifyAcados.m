function correct = verifyAcados(acadso_dir)
if isunix
    acadoslib= fullfile(acadso_dir, 'lib/libacados.so');
else
    acadoslib= fullfile(acadso_dir, 'lib/acados.lib');
end
casadi_mex= fullfile(getenv('ACADOS_INSTALL_DIR'), ['external/casadi-matlab/casadiMEX.' mexext]);

correct = exist(acadoslib, 'file') && exist(casadi_mex, 'file');
% TODO: perform some version check!!!