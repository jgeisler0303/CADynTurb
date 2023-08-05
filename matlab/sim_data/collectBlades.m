function d= collectBlades(d)


d= processData(d, '(_B)1');
d= processData(d, '(b)1$');
d= processData(d, '(c)1$');
d= processData(d, '(Pitch)1$');
d= processData(d, '(BlPitchC)1$');

if ~ismember('RootMxb', d.gettimeseriesnames) && ismember('RootMxc', d.gettimeseriesnames) && ismember('RootMyc', d.gettimeseriesnames) && ismember('BlPitchC', d.gettimeseriesnames)
    ts= timeseries('RootMxb');
    ts.Time= d.get('RootMxc').Time;
    ts.Data= d.RootMxc.Data.*cosd(d.BlPitchC.Data) - d.RootMyc.Data.*sind(d.BlPitchC.Data);
    ts.DataInfo.Units= d.get('RootMxc').DataInfo.Units;
    ts.TimeInfo.Units= 's';
    
    d= d.addts(ts);
end
if ~ismember('RootMyb', d.gettimeseriesnames) && ismember('RootMxc', d.gettimeseriesnames) && ismember('RootMyc', d.gettimeseriesnames) && ismember('BlPitchC', d.gettimeseriesnames)
    ts= timeseries('RootMyb');
    ts.Time= d.get('RootMxc').Time;
    ts.Data= d.RootMxc.Data.*sind(d.BlPitchC.Data) + d.RootMyc.Data.*cosd(d.BlPitchC.Data);
    ts.DataInfo.Units= d.get('RootMxc').DataInfo.Units;
    ts.TimeInfo.Units= 's';
    
    d= d.addts(ts);
end
    

function d= processData(d, pattern)
all_names= d.gettimeseriesnames;
idx= cellfun(@(s)~isempty(s), regexp(all_names, pattern, 'once', 'match'), 'UniformOutput', true);
names= all_names(idx);

for i= 1:length(names)
    b1_name= names{i};
    b2_name= regexprep(b1_name, pattern, '$12');
    b3_name= regexprep(b1_name, pattern, '$13');
    b_name= regexprep(b1_name, pattern, '$1');
    
    if ~strcmp(all_names, b2_name)
        warning('Data for blade 2 not found ("%s").', b2_name);
        continue;
    end
    if ~strcmp(all_names, b3_name)
        warning('Data for blade 3 not found ("%s").', b3_name);
        continue;
    end
    
    ts= timeseries(b_name);
    ts.Time= d.get(b1_name).Time;
    ts.Data= (d.get(b1_name).Data+d.get(b2_name).Data+d.get(b3_name).Data)/3;
    ts.DataInfo.Units= d.get(b1_name).DataInfo.Units;
    ts.TimeInfo.Units= 's';
    
    d= d.addts(ts);
end

