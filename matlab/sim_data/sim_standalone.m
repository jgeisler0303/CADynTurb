function d1= sim_standalone(model_path, fast_config, out_file, options)
if ~exist('options', 'var')
    options= '';
end
if isunix && isempty(fileparts(model_path))
    model_path= fullfile('.', model_path);
end

if ~exist('out_file', 'var') || isempty(out_file)
    [~, config_name]= fileparts(fast_config);
    out_file= [config_name '.outb'];
end

model_dir= fileparts(model_path);
old_dir= pwd;
cleanupObj = onCleanup(@()cd(old_dir));
cd(model_dir)

sim_command= [model_path ' ' options ' -o ' out_file ' ' fast_config];
if isunix
    system(['LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 ' sim_command]);
else
    system(['set path=' getenv('PATH') ' & ' sim_command]);
end

if nargout>0
    d1= loadFAST(out_file);
end
