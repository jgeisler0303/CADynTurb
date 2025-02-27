function d1= sim_standalone(model_path, fast_config, out_file, options, win_on_linux)
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

if exist('win_on_linux', 'var') && win_on_linux
    sim_command= ['wineconsole ' model_path '.exe ' options ' -o ' out_file ' ' fast_config];
    system(sim_command);
else
    sim_command= [model_path ' ' options ' -o ' out_file ' ' fast_config];
    if isunix
        res= system(['LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 ' sim_command]);
    else
        res= system(['set path=' getenv('PATH') ' & ' sim_command]);
    end
end
if res~=0
    error('A simulation error occured')
end

if nargout>0
    d1= loadFAST(out_file);
end
