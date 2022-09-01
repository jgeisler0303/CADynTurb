function d= loadFAST(file_name)
[~, ~, ext]= fileparts(file_name);
if strcmp(ext, '.out')
    [Channels, ChanName, ChanUnit, DescStr] = ReadFASTtext(file_name);
else
    [Channels, ChanName, ChanUnit, FileID, DescStr] = ReadFASTbinary(file_name);
end
d= tscollection(Channels(:, 1));
[~, d.Name]= fileparts(file_name);
% d.Description= DescStr;

exclude_idx= false(size(ChanName));
for i= 2:length(ChanName)
    if exclude_idx(i)
        continue
    end
    
    res= regexp(ChanName{i}, '(A?)B(\d)N\d{2,3}(.*)', 'tokens', 'once');
    if ~isempty(res)
        idx= regexp(ChanName, sprintf('%sB%sN\\d{2,3}%s', res{1}, res{2}, res{3}), 'once');
        idx= cellfun(@(c)~isempty(c), idx);
            
        name= sprintf('B%s%s', res{2}, res{3});
        unit= ChanUnit{find(idx, 1)};
        exclude_idx= exclude_idx | idx;
    else
        idx= i;
        name= ChanName{i};
        unit= ChanUnit{i};
    end
    
    ts= timeseries(name);
    ts.Time= Channels(:, 1);
    ts.Data= Channels(:, idx);
    ts.DataInfo.Units= unit;
    ts.TimeInfo.Units= 's';
    
    d= d.addts(ts);
end