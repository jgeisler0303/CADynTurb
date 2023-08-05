function writeModelParams(param, target_dir)

run(fullfile(target_dir, 'model_parameters.m'))

fid= fopen(fullfile(target_dir, 'params.txt'), 'w');
for i= 1:length(parameter_names)
    if ~isnumeric(param.(parameter_names{i})), continue; end
    fprintf(fid, '%s ', parameter_names{i});
    for row= 1:size(param.(parameter_names{i}), 1)
        for col= 1:size(param.(parameter_names{i}), 2)
            fprintf(fid, '%.16e ', param.(parameter_names{i})(row, col));
        end
        fprintf(fid, '\n');
    end
    p_.(parameter_names{i})= param.(parameter_names{i});
end
fclose(fid);

save(fullfile(target_dir, 'params_config.mat'), 'p_');