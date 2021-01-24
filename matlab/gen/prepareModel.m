function param= prepareModel(fst_file, mac_file, target_path)

[~, model_name]= fileparts(mac_file);
if ~exist('target_path', 'var')
    target_path= fullfile(pwd, model_name);
end

[param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file);
param.tw_sid= tw_sid;
param.bd_sid= bd_sid;

write_sid_maxima(tw_sid, fullfile(target_path, 'tw_sid'), 'tower', length(tw_sid.frame), 1e-5, 1);
write_sid_maxima(bd_sid, fullfile(target_path, 'bd_sid'), 'blade', 'last', 1e-5, 1);

mac_file_gen= fullfile(target_path, [model_name '.mac']);
copyfile(mac_file, mac_file_gen)

ext_file_gen= fullfile(target_path, [model_name 'System_Externals.hpp']);
if ~exist(ext_file_gen, 'file')
    copyfile(strrep(mac_file, '.mac', 'System_Externals.hpp'), ext_file_gen)
end

genModel(mac_file_gen, target_path)


writeModelParams(param, target_path)

