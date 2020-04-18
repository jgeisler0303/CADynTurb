function TF= contains(str, pattern)
if ~iscell(str)
    str= {str};
end
if ~iscell(pattern)
    pattern= {pattern};
end

TF= false(size(str));
for i= 1:length(str)
    for j= 1:length(pattern)
        if ~isempty(strfind(str{i}, pattern{j}))
            TF(i)= true;
            continue;
        end
    end
end