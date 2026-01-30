function correct = verifyAcados(acados_dir, only_repo)
arguments
    acados_dir
    only_repo = false;
end

if exist(acados_dir, 'dir')
    acados_fully_cloned = exist(fullfile(acados_dir, '.git'), 'dir');
    externals = {'blasfeo' 'catch'  'Clarabel.cpp' 'daqp'  'hpipm'  'hpmpc'  'jsonlab' 'osqp' 'qpdunes' 'qpoases'};
    for i = 1:length(externals)
        % Check if each external dependency exists
        if ~acados_fully_cloned || ~exist(fullfile(acados_dir, 'external', externals{i}, '.git'), 'file')
            error('It seems you already have acados cloned but not completely including the submodules. It would be best, you delete the folder "%s" completely and let the CADynTurb setup reinstall it automatically.', acados_dir)
        end
    end

    old_dir = pwd;
    cd(acados_dir)
    [res, msg] = system('git -c gpg.program= --no-pager tag --points-at HEAD');
    cd(old_dir)
    msg = strtrim(msg);
    if res ~= 0 || ~strcmp(msg, 'v0.5.3')
        warning('It seems you already have acados installed but not version/tag v0.5.3. It is strongly recommended to delete your acados and let this script automatically reinstall the correct version.')
    end
else
    correct = false;
    return
end

if only_repo
    correct = true;
    return
end

if isunix
    acadoslib= fullfile(acados_dir, 'lib/libacados.so');
else
    acadoslib= fullfile(acados_dir, 'lib/acados.lib');
end
acados_casadi= fullfile(getenv('ACADOS_INSTALL_DIR'), ['external/casadi-matlab/casadiMEX.' mexext]);

correct = acados_fully_cloned && exist(acadoslib, 'file') && (exist(acados_casadi, 'file') || is_casadi_available());

end

function got_casadi = is_casadi_available()
    got_casadi = 1;
    try
    % check CasADi availibility
        import casadi.*
        test = SX.sym('test');
    catch e
        got_casadi = 0;
    end
end
