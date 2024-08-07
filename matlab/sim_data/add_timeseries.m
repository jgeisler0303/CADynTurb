function d= add_timeseries(d, name, units, data)
    ts= timeseries(name);
    ts.Time= d.Time;
    ts.TimeInfo.Units= 's';
    if length(data)==1
        ts.Data= data*ones(size(ts.Time));
    elseif size(data, 1)<size(data, 2)
        ts.Data= data';
    else
        ts.Data= data;
    end
    ts.DataInfo.Units= units;
    if ismember(name, d.fieldnames)
        d.(name)= ts;
    else
        d= d.addts(ts);
    end
end