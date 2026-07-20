function setMexCompiler
if isunix
    compiler_name = {'gcc', 'g++'};
else
    compiler_name = {'MinGW', 'MinGW'};
end

langs = {'C','C++'};
for k = 1:numel(langs)
    ccSel = mex.getCompilerConfigurations(langs{k}, 'Selected');
    if isempty(ccSel) || ~startsWith(ccSel.Name, compiler_name{k})
        ccAll = mex.getCompilerConfigurations(langs{k}, 'Installed');
        if ~isempty(ccAll)
            names = {ccAll.Name};
            shorts = {ccAll.ShortName};
            isCompiler = contains(names,compiler_name,'IgnoreCase',true) | contains(shorts,compiler_name,'IgnoreCase',true);
        else
            isCompiler = false;
        end
        if any(isCompiler)
            mex(['-setup:', ccAll(find(isCompiler, 1)).MexOpt], langs{k})
        else
            error('No suitable installed compilers found. You need a mex compiler for CADynTurb.');
        end
    end
end
