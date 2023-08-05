function d_in= loadData(file_path, wind_dir)
[~, file]= fileparts(file_path);

d_in= collectBlades(loadFAST(file_path));
% load rotor average wind speed
if ~strncmp(file, 'impuls', 6)
    d_in= add_average_wind(d_in, wind_dir, file);
else
    RtHSAvg= timeseries('RtHSAvg');
    RtHSAvg.Time= d_in.Time;
    RtHSAvg.Data= zeros(size(d_in.Time));
    RtHSAvg.DataInfo.Units= 'm/s/m';
    RtHSAvg.TimeInfo.Units= 's';
    d_in= d_in.addts(RtHSAvg);
    
    RtVSAvg= timeseries('RtVSAvg');
    RtVSAvg.Time= d_in.Time;
    RtVSAvg.Data= zeros(size(d_in.Time));
    RtVSAvg.DataInfo.Units= 'm/s/m';
    RtVSAvg.TimeInfo.Units= 's';
    d_in= d_in.addts(RtVSAvg);      
end

d_in.RootMyb.Data= notch_369p(d_in.RootMyb.Data, d_in.LSSTipVxa.Data/30*pi, d_in.Time(2)-d_in.Time(1));
d_in.RootMxb.Data= notch_369p(d_in.RootMxb.Data, d_in.LSSTipVxa.Data/30*pi, d_in.Time(2)-d_in.Time(1));
d_in.HSShftV.Data= notch_369p(d_in.HSShftV.Data, d_in.LSSTipVxa.Data/30*pi, d_in.Time(2)-d_in.Time(1));
d_in.YawBrTAxp.Data= notch_369p(d_in.YawBrTAxp.Data, d_in.LSSTipVxa.Data/30*pi, d_in.Time(2)-d_in.Time(1));
d_in.YawBrTAyp.Data= notch_369p(d_in.YawBrTAyp.Data, d_in.LSSTipVxa.Data/30*pi, d_in.Time(2)-d_in.Time(1));

% F= tf(1, [Tm_avg 1]);
% RootMyb_filt= timeseries('RootMyb_filt');
% RootMyb_filt.Time= d_in.Time;
% RootMyb_filt.Data= notch_369p(d_in.RootMyb.Data-lsim(F, d_in.RootMyb.Data, d_in.Time, 0), d_in.LSSTipVxa.Data/30*pi, d_in.Time(2)-d_in.Time(1));
% RootMyb_filt.DataInfo.Units= d_in.RootMyb.DataInfo.Units;
% RootMyb_filt.TimeInfo.Units= 's';
% d_in= d_in.addts(RootMyb_filt);    
% 
% RootMxb_filt= timeseries('RootMxb_filt');
% RootMxb_filt.Time= d_in.Time;
% RootMxb_filt.Data= notch_369p(d_in.RootMxb.Data-lsim(F, d_in.RootMxb.Data, d_in.Time, 0), d_in.LSSTipVxa.Data/30*pi, d_in.Time(2)-d_in.Time(1));;
% RootMxb_filt.DataInfo.Units= d_in.RootMxb.DataInfo.Units;
% RootMxb_filt.TimeInfo.Units= 's';
% d_in= d_in.addts(RootMxb_filt);    
end