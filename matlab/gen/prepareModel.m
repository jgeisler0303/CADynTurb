function [param, tw_sid, bd_sid]= prepareModel(fst_file, mac_file, target_path, tower_modes, blade_modes)

[~, model_name]= fileparts(mac_file);
if ~exist('target_path', 'var')
    target_path= fullfile(pwd, model_name);
end
if ~exist('tower_modes', 'var')
    tower_modes= {[1 2]};
end
if ~exist('blade_modes', 'var')
    blade_modes= [1 2];
end

old= 1;
if old
    [param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, tower_modes, blade_modes);
    write_sid_maxima(tw_sid, fullfile(target_path, 'tw_sid'), 'tower', 'last', 1e-5, 1);
    write_sid_maxima(bd_sid, fullfile(target_path, 'bd_sid'), 'blade', 'all', 1e-5, 1);
else
    [param, ~]= FAST2CADynTurb2(fst_file, tower_modes, blade_modes);
end
% TODO: replace write_sid_maxima(tw_sid, fullfile(target_path, 'tw_sid'), 'tower', 'last', 1e-5, 1);
% TODO: replace write_sid_maxima(bd_sid, fullfile(target_path, 'bd_sid'), 'blade', 'all', 1e-5, 1);

mac_file_gen= fullfile(target_path, [model_name '.mac']);
copyfile(mac_file, mac_file_gen)

ext_file_gen= fullfile(target_path, [model_name 'System_Externals.hpp']);
if ~exist(ext_file_gen, 'file')
    copyfile(strrep(mac_file, '.mac', 'System_Externals.hpp'), ext_file_gen)
end

acados_ext_file_gen= fullfile(target_path, [model_name '_acados_external.m']);
acados_ext_file_src= strrep(mac_file, '.mac', '_acados_external.m');
if ~exist(ext_file_gen, 'file') && exist(acados_ext_file_src, 'file')
    copyfile(acados_ext_file_src, acados_ext_file_gen)
end

makeCAGEM(mac_file_gen, target_path)


param= writeModelParams(param, target_path);

