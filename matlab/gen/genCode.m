function genCode(mac_file, target_path, files_to_generate, param, tw_sid, bd_sid)

% make target_path directories up to two levels
dn= fileparts(target_path);
if ~exist(dn, 'dir')
    mkdir(dn);
end
dn= target_path;
if ~exist(dn, 'dir')
    mkdir(dn);
end

write_sid_maxima(tw_sid, fullfile(target_path, 'tw_sid'), 'tower', 'last', 1e-5, 1);
write_sid_maxima(bd_sid, fullfile(target_path, 'bd_sid'), 'blade', 'all', 1e-5, 1);

[~, model_name]= fileparts(mac_file);
mac_file_gen= fullfile(target_path, [model_name '.mac']);
copyfile(mac_file, mac_file_gen)

ext_file_src= strrep(mac_file, '.mac', '_Externals.hpp');
ext_file_gen= fullfile(target_path, [model_name '_Externals.hpp']);
if any(strcmp(files_to_generate, 'cpp_direct')) && recompile(ext_file_gen, {ext_file_src})
    copyfile(ext_file_src, ext_file_gen)
end

acados_ext_file_gen= fullfile(target_path, [model_name '_acados_external.m']);
acados_ext_file_src= strrep(mac_file, '.mac', '_acados_external.m');
if any(strcmp(files_to_generate, 'acados')) && recompile(acados_ext_file_gen, {acados_ext_file_src})
    copyfile(acados_ext_file_src, acados_ext_file_gen)
end

makeCAGEM(mac_file_gen, target_path, [], files_to_generate)