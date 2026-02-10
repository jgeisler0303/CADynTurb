function model = genCodeM(model_path, target_path, files_to_generate, param, tw_sid, bd_sid, skip_gen)
% make target_path directories up to two levels
dn= fileparts(target_path);
if ~exist(dn, 'dir')
    mkdir(dn);
end
dn= target_path;
if ~exist(dn, 'dir')
    mkdir(dn);
end

if ~exist('skip_gen', 'var')
    skip_gen= [];
end

param.tw_sid= tw_sid;
param.bd_sid= bd_sid;

[model_dir, model_file]= fileparts(model_path);
model_name = model_file;
if startsWith(model_name, 'model')
    model_name = model_name(6:end);
end

model_file_gen = fullfile(target_path, [model_file '.m']);
copyfile(model_path, model_file_gen)

ext_file_src= fullfile(model_dir, [model_name, '_Externals.hpp']);
ext_file_gen= fullfile(target_path, [model_name '_Externals.hpp']);
if any(strcmp(files_to_generate, '_direct.hpp'))
    if exist(ext_file_src, 'file')
        if recompile(ext_file_gen, {ext_file_src})
            copyfile(ext_file_src, ext_file_gen)
        end
    else
        files_to_generate{end+1} = '_Externals.hpp';
    end
end

acados_ext_file_src= fullfile(model_dir, [model_name '_acados_external.m']);
acados_ext_file_gen= fullfile(target_path, [model_name '_acados_external.m']);
if any(strcmp(files_to_generate, '_acados.m')) && recompile(acados_ext_file_gen, {acados_ext_file_src})
    copyfile(acados_ext_file_src, acados_ext_file_gen)
end

model = makeCADynM(model_file_gen, target_path, param, skip_gen, files_to_generate);