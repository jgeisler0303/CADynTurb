function check_installRepositories(CADynTurb_dir)

requiredRepos = {
    'https://github.com/jgeisler0303/CADyn.git' 
    'https://github.com/jgeisler0303/FEMBeam.git'
    'https://github.com/jgeisler0303/SimpleDynInflow.git'
    'https://github.com/OpenFAST/matlab-toolbox.git'
    'https://github.com/jgeisler0303/AMPoWS.git'
    };
missingRepos = {};
for i = 1:length(requiredRepos)
    [~, repo_dir] = fileparts(requiredRepos{i});
    if ~exist(fullfile(CADynTurb_dir, '..', repo_dir), 'dir')
        missingRepos{end+1} = requiredRepos{i};
    end
end

if ~isempty(missingRepos)
    fprintf('The following repositories need to be cloned to the parent directory of CADynTurb:\n')
    for i= 1:length(missingRepos)
        fprintf('  %s\n', missingRepos{i});
    end
    tf_install = askYesNo('Do you want to have them cloned automatically?', true);
    if tf_install
        for i= 1:length(missingRepos)
            fprintf('Cloning "%s" ... ', missingRepos{i})
            [~, repo_dir] = fileparts(missingRepos{i});
            gitclone(missingRepos{i}, fullfile(CADynTurb_dir, '..', repo_dir));
            fprintf('Done.\n')
        end
    else
        error('Please install the repositoris manually. Use of CADynTurb cannot continue before this requirement is met.')
    end
end

