function tf = askYesNo(prompt, default)
% askYesNo  Prompt user for a yes/no answer on the command line.
%   tf = askYesNo(prompt)           % no default; repeats until valid
%   tf = askYesNo(prompt, default)  % default: true (yes) or false (no)
%
%   Returns true for yes, false for no.

if nargin < 2
    useDefault = false;
else
    useDefault = true;
    if ~islogical(default)
        error('Default must be true or false.');
    end
end

validYes  = {'y','yes'};
validNo   = {'n','no'};

while true
    if useDefault
        if default
            suffix = ' [Y/n]: ';
        else
            suffix = ' [y/N]: ';
        end
    else
        suffix = ' [y/n]: ';
    end

    resp = strtrim(lower(input([prompt, suffix], 's')));

    if isempty(resp) && useDefault
        tf = default;
        return
    end

    if any(strcmp(resp, validYes))
        tf = true;
        return
    end
    if any(strcmp(resp, validNo))
        tf = false;
        return
    end

    fprintf('Please answer ''y'' or ''n'' (or ''yes''/''no'').\n');
end