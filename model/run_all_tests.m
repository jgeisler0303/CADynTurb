tests= dir(fullfile(fileparts(mfilename('fullpath')), '*/test*.m'));

for i= 1:length(tests)
    if contains(tests(i).folder, 'untested'), continue, end

    clear all
    diary(['test_log_' strrep(tests(i).name, '.m', '.txt')])
    run(fullfile(tests(i).folder, tests(i).name))
    diary off
    savefig(['test_fig_' strrep(tests(i).name, '.m', '.fig')])
end
