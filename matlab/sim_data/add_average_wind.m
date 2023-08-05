function d= add_average_wind(d, wind_dir, fst_file)
    bts_file= regexprep(fst_file, 'NacYaw-(neg)?(\d+)_', '');
    bts_file= strrep(bts_file, '1p1', 'NTM');
    bts_file= strrep(bts_file, 'coh', 'NTM');
    bts_file= strrep(bts_file, 'shear', 'NTM');
    bts_file= strrep(bts_file, 'maininput', 'turbsim_shear.bts');
    [velocity, ~, ~, ~, ~, ~, ny, dz, dy, dt,~, ~, u_hub]= readfile_BTS(fullfile(wind_dir, bts_file));
    tv= (0:(size(velocity, 1)-1))*dt;
    time= d.Time + ((ny-1)*dy/2)/u_hub;
    d.RtVAvgxh.Data= interp1(tv, (velocity(:, 1, 1, 1)+velocity(:, 1, 2, 1)+velocity(:, 1, 1, 2)+velocity(:, 1, 2, 2))/4, time);

    RtHSAvg= timeseries('RtHSAvg');
    RtHSAvg.Time= d.Time;
    shear= 0.5*((velocity(:, 1, 2, 1)-velocity(:, 1, 1, 1))/dy + (velocity(:, 1, 2, 2)-velocity(:, 1, 1, 2))/dy);
    RtHSAvg.Data=interp1(tv, shear, time);
    RtHSAvg.DataInfo.Units= 'm/s/m';
    RtHSAvg.TimeInfo.Units= 's';
    d= d.addts(RtHSAvg);
    
    RtVSAvg= timeseries('RtVSAvg');
    RtVSAvg.Time= d.Time;
    shear= 0.5*((velocity(:, 1, 1, 2)-velocity(:, 1, 1, 1))/dz + (velocity(:, 1, 2, 2)-velocity(:, 1, 2, 1))/dz);
    RtVSAvg.Data=interp1(tv, shear, time);
    RtVSAvg.DataInfo.Units= 'm/s/m';
    RtVSAvg.TimeInfo.Units= 's';
    d= d.addts(RtVSAvg);  
end