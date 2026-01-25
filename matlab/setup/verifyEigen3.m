function correct = verifyEigen3(eigen3_dir)

version_file = fullfile(eigen3_dir, 'Eigen/src/Core/util/Macros.h');
v = parseEigenVersion(version_file);
correct = v.world==3 && v.major==3;
end

function v = parseEigenVersion(version_file)
txt = fileread(version_file);

% Safely convert (handle missing matches)
tok = regexp(txt, '#define\s+EIGEN_WORLD_VERSION\s+(\d+)', 'tokens', 'once');
if isempty(tok)
    v.world = NaN;
else
    v.world= str2double(tok{1});
end

tok = regexp(txt, '#define\s+EIGEN_MAJOR_VERSION\s+(\d+)', 'tokens', 'once');
if isempty(tok)
    v.major = NaN;
else
    v.major= str2double(tok{1});
end

tok = regexp(txt, '#define\s+EIGEN_MINOR_VERSION\s+(\d+)', 'tokens', 'once');
if isempty(tok)
    v.minor = NaN;
else
    v.minor= str2double(tok{1});
end

end