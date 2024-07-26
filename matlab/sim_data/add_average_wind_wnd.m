function d= add_average_wind_wnd(d, wind_dir, outb_file, R)
tok= regexp(outb_file, 'URef-(\d+)_RandSeed1-(\d+)_', 'tokens', 'once');
URef= str2double(tok{1});
RandSeed1= str2double(tok{2});

wnd_file= fullfile(wind_dir, sprintf('URef_%1$02d_Seed_%1$02d%2$02d.wnd', URef, RandSeed1));

[velocity, y, z, nz, ny, dz, dy, dt, zHub, z1, SummVars]= readBLgrid(wnd_file);

nt= size(velocity, 1);

% get points in rotor disc
[Y, Z]= meshgrid(y, z-zHub);

DistanceFromHub= (Z(:).^2+Y(:).^2).^0.5;
PointsInRotorDisc= DistanceFromHub <= R;

% calculate REWS = mean of all u components in rotor disc
U3D= squeeze(velocity(:, 1, :, :));       % [nt,ny,nz]
U2D= reshape(U3D, nt, []);               % [nt,ny*nz]

tv= (0:(size(velocity, 1)-1))*dt;
d.RtVAvgxh.Data= interp1(tv, mean(U2D(:, PointsInRotorDisc), 2), d.Time);

% RtHSAvg= timeseries('RtHSAvg');
% RtHSAvg.Time= d.Time;
% shear= 0.5*((velocity(:, 1, 2, 1)-velocity(:, 1, 1, 1))/dy + (velocity(:, 1, 2, 2)-velocity(:, 1, 1, 2))/dy);
% RtHSAvg.Data=interp1(tv, shear, time);
% RtHSAvg.DataInfo.Units= 'm/s/m';
% RtHSAvg.TimeInfo.Units= 's';
% d= d.addts(RtHSAvg);
% 
% RtVSAvg= timeseries('RtVSAvg');
% RtVSAvg.Time= d.Time;
% shear= 0.5*((velocity(:, 1, 1, 2)-velocity(:, 1, 1, 1))/dz + (velocity(:, 1, 2, 2)-velocity(:, 1, 2, 1))/dz);
% RtVSAvg.Data=interp1(tv, shear, time);
% RtVSAvg.DataInfo.Units= 'm/s/m';
% RtVSAvg.TimeInfo.Units= 's';
% d= d.addts(RtVSAvg);  