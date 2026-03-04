function d = add_uniform_wind(d, file_path)

uni_wind_file = strrep(file_path, '_maininput.outb', '_uni_wind.wnd');
wind_tab = readUniformWind(uni_wind_file);

time= d.Time;

RtHSAvg= timeseries('RAWS');
RtHSAvg.Time= d.Time;
RtHSAvg.Data= interp1(wind_tab.Time, wind_tab.WindSpeed, time);
RtHSAvg.DataInfo.Units= 'm/s';
RtHSAvg.TimeInfo.Units= 's';
d= d.addts(RtHSAvg);

RtHSAvg= timeseries('RtHSAvg');
RtHSAvg.Time= d.Time;
RtHSAvg.Data= interp1(wind_tab.Time, wind_tab.HorizShear, time);
RtHSAvg.DataInfo.Units= 'm/s/m';
RtHSAvg.TimeInfo.Units= 's';
d= d.addts(RtHSAvg);

RtVSAvg= timeseries('VertShear');
RtVSAvg.Time= d.Time;
RtVSAvg.Data= interp1(wind_tab.Time, wind_tab.WindSpeed, time);
RtVSAvg.DataInfo.Units= 'm/s/m';
RtVSAvg.TimeInfo.Units= 's';
d= d.addts(RtVSAvg);      
