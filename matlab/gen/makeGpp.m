function makeGpp(src, includes, options, defines, sources, linker_options, lib_dirs, libs)
% TODO: double of compileProg?
if ~exist('includes', 'var')
    includes= {};
end
if ~iscell(includes)
    includes= {includes};
end
if ~exist('options', 'var') || isempty(options)
    options= {};
end
if ~iscell(options)
    options= {options};
end
if ~exist('defines', 'var')
    defines= {};
end
if ~iscell(defines)
    defines= {defines};
end
if ~exist('sources', 'var')
    sources= {};
end
if ~iscell(sources)
    sources= {sources};
end
if ~exist('linker_options', 'var')
    linker_options= {};
end
if ~iscell(linker_options)
    linker_options= {linker_options};
end
if ~exist('lib_dirs', 'var')
    lib_dirs= {};
end
if ~iscell(lib_dirs)
    lib_dirs= {lib_dirs};
end
if ~exist('libs', 'var')
    libs= {};
end
if ~iscell(libs)
    libs= {libs};
end

[~, src_file]= fileparts(src);

v= ver;
is_matlab= ~strcmp(v(1).Name, 'Octave');

if ispc
    defines{end+1}= '_USE_MATH_DEFINES';
end

defines= strcat('-D', defines);
includes= strcat('-I', includes);
lib_dirs= strcat('-L', lib_dirs);
libs= strcat('-l', libs);

args= {};
if ~isempty(options)
    args= [args options];
end
if ~isempty(defines)
    args= [args defines];
end
if ~isempty(includes)
    args= [args includes];
end
if ~isempty(sources)
    args= [args sources];
end
args= [args {src}];
if ~isempty(linker_options)
    args= [args linker_options];
end
if ~isempty(lib_dirs)
    args= [args lib_dirs];
end
if ~isempty(libs)
    args= [args libs];
end
args= strcat(args, {' '});
args= [args{:}];
[res, msg]= system([getenv('CPP') ' ' args ' -o ', src_file]);

if res
    error('Program was not properly compiled: %s', msg);
end