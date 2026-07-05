function d = add_uniform_wind(d, uni_wind_file)

wind_tab = readUniformWind(uni_wind_file);
[wind_time, idx] = unique(wind_tab.Time);

time= d.Time;

RtHSAvg= timeseries('RAWS');
RtHSAvg.Time= d.Time;
RtHSAvg.Data= interp1(wind_time, wind_tab.WindSpeed(idx), time);
RtHSAvg.DataInfo.Units= 'm/s';
RtHSAvg.TimeInfo.Units= 's';
d= d.addts(RtHSAvg);

RtHSAvg= timeseries('RtHSAvg');
RtHSAvg.Time= d.Time;
RtHSAvg.Data= interp1(wind_time, wind_tab.HorizShear(idx), time);
RtHSAvg.DataInfo.Units= 'm/s/m';
RtHSAvg.TimeInfo.Units= 's';
d= d.addts(RtHSAvg);

RtVSAvg= timeseries('VertShear');
RtVSAvg.Time= d.Time;
RtVSAvg.Data= interp1(wind_time, wind_tab.VertShear(idx), time);
RtVSAvg.DataInfo.Units= 'm/s/m';
RtVSAvg.TimeInfo.Units= 's';
d= d.addts(RtVSAvg);      
