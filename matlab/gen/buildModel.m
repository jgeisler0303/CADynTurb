function param = buildModel(model_name, model_dir, gen_dir, files_to_generate, fst_file, compile)
if ~exist('compile', 'var')
    compile = true;
end

old_dir = pwd;

%% calculate parameters
cd(model_dir)
if exist('./params.mat', 'file')
    load('./params.mat')
else
    [param, ~, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, {[1 -2]}, 1);
    save('params', 'param', 'tw_sid', 'bd_sid')
end

%% generate and compile all source code
genCode([model_name '.mac'], gen_dir, files_to_generate, param, tw_sid, bd_sid, [0 1]);
writeModelParams(param, gen_dir);
if compile
    compileModel(model_name, model_dir, gen_dir, files_to_generate)
end

cd(old_dir)
