function compileProg(sources, out_name, dependencies, defines, includes, lib_dirs, libs, flags, win_on_linux)

if ~iscell(sources)
    sources= {sources};
end

if ~exist('dependencies', 'var') || isempty(dependencies)
    dependencies= {};
end

if ~exist('defines', 'var') || isempty(defines)
    defines= '';
end

if ~exist('includes', 'var') || isempty(includes)
    includes= '';
end

if ~exist('lib_dirs', 'var') || isempty(lib_dirs)
    lib_dirs= '';
end

if ~exist('lib_dirs', 'var') || isempty(lib_dirs)
    lib_dirs= '';
end

if ~exist('lib_dirs', 'var') || isempty(lib_dirs)
    lib_dirs= '';
end

if ~exist('libs', 'var') || isempty(libs)
    libs= '';
end

if ~exist('flags', 'var') || isempty(flags)
    flags= '';
end
if ~exist('win_on_linux', 'var')
    win_on_linux= false;
end

out_name_ext= out_name;
if ispc
    [~, ~, ext]= fileparts(out_name);
    if isempty(ext)
        out_name_ext= [out_name '.exe'];
    end
end

dependencies= [dependencies(:); sources(:)];
if ~recompile(out_name_ext, dependencies)
    fprintf('Skipping compilation of standalone simulator "%s"\n', out_name)
    return;
end

sources= strcat({' '}, sources);
sources= strcat(sources{:});

if ~isempty(defines) && iscell(defines)
    defines= strcat(' -D', defines);
    defines= strcat(defines{:});
end
if ispc || win_on_linux
    defines= [defines ' -D_USE_MATH_DEFINES'];
end

if ~isempty(includes) && iscell(includes)
    includes= strcat(' -I', includes);
    includes= strcat(includes{:});
end

if ~isempty(lib_dirs) && iscell(lib_dirs)
    lib_dirs= strcat(' -L', lib_dirs);
    lib_dirs= strcat(lib_dirs{:});
end

if ~isempty(libs) && iscell(libs)
    libs= strcat(' -l', libs);
    libs= strcat(libs{:});
end
if isunix && ~(exist('win_on_linux', 'var') && win_on_linux)
    libs= [libs ' -ldl'];
end

if isempty(flags)
    flags= '-g -std=c++17';
end


fprintf('Compiling standalone simulator "%s"\n', out_name)

if exist('win_on_linux', 'var') && win_on_linux
    compiler= 'i686-w64-mingw32-g++';
else
    compiler= 'g++';
end

command_str= [compiler ' ' flags ' ' defines ' ' includes ' ' sources ' ' lib_dirs ' ' libs ' -o ' out_name];
[res, msg]= system(command_str);
if res~=0
    error('Compilation error: %s', msg)
end