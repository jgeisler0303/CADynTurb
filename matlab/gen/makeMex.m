function makeMex(mex_src, includes, options, cxxflags, defines, sources, linker_options, lib_dirs, libs)

if ~exist('includes', 'var')
    includes= {};
end
if ~iscell(includes)
    includes= {includes};
end
if ~exist('options', 'var') || isempty(options)
    options= {};
end
if ~exist('cxxflags', 'var')
    cxxflags= '-std=c++11 -Wall -fdiagnostics-show-option';
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

[~, mex_file]= fileparts(mex_src);
% mex_name= fullfile(mex_path, mex_file);

v= ver;
is_matlab= ~strcmp(v(1).Name, 'Octave');
if is_matlab
    clear mex
    output_str= '-output';
else
    clear(mex_file);
    output_str= '-o';
end

mex_name_ext= [mex_file '.' mexext];
if exist(mex_name_ext, 'file')
    delete(mex_name_ext);
end

if ispc
    defines{end+1}= '_USE_MATH_DEFINES';
end

defines= strcat('-D', defines);
includes= strcat('-I', includes);
lib_dirs= strcat('-L', lib_dirs);
libs= strcat('-l', libs);

if ~isempty(cxxflags)
    if ~is_matlab
        old_cxxflags= getenv('CXXFLAGS');
        [~, cxxflags_]= system('mkoctfile --print  CXXFLAGS');
        cxxflags= [cxxflags_ ' ' cxxflags];
        cxxflags= strrep(cxxflags, newline, ' ');
        setenv('CXXFLAGS', cxxflags);
    else
        options= [options {'CXXFLAGS="' cxxflags '"'}];
    end    
end

args= {};
if ~isempty(options)
    args= [args options output_str mex_file];
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
args= [args {mex_src}];
if ~isempty(linker_options)
    args= [args linker_options];
end
if ~isempty(lib_dirs)
    args= [args lib_dirs];
end
if ~isempty(libs)
    args= [args libs];
end
mex(args{:});

if ~isempty(cxxflags) && ~is_matlab
    setenv('CXXFLAGS', old_cxxflags);
end

compiled= false;
if exist(mex_name_ext, 'file') && exist(mex_src, 'file')
    dd_src= dir(mex_src);
    dd_dst= dir(mex_name_ext);
    if dd_src.datenum<dd_dst.datenum
        compiled= true;
    end
end
if ~compiled
    error('Mex was not properly compiled');
end
