function d= loadFAST(file_name)
[Channels, ChanName, ChanUnit, FileID, DescStr] = ReadFASTbinary(file_name);

d= tscollection(Channels(:, 1));
[~, d.Name]= fileparts(file_name);
% d.Description= DescStr;

for i= 2:length(ChanName)
    ts= timeseries(ChanName{i});
    ts.Time= Channels(:, 1);
    ts.Data= Channels(:, i);
    ts.DataInfo.Units= ChanUnit{i};
    ts.TimeInfo.Units= 's';
    
    d= d.addts(ts);
end