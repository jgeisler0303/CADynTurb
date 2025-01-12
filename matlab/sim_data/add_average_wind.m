function d= add_average_wind(d, wind_dir, fst_file, R)
if ~exist('R', 'var')
    R= 92/2;
end

if strcmp(wind_dir(end-3:end), '.bts')
    bts_path= wind_dir;
elseif strcmp(wind_dir(end-3:end), '.wnd')
    wnd_path= wind_dir;
    bts_path= strrep(wnd_path, '.wnd', '.bts');
else
    bts_file= regexprep(fst_file, 'NacYaw-(neg)?(\d+)_', '');
    bts_file= strrep(bts_file, '1p1', 'NTM');
    bts_file= strrep(bts_file, 'coh', 'NTM');
    bts_file= strrep(bts_file, 'shear', 'NTM');
    bts_file= strrep(bts_file, 'maininput', 'turbsim_shear.bts');
    
    bts_path= fullfile(wind_dir, bts_file);
end

if exist(bts_path, 'file')
    d= addBTS(bts_path, d);
else
    if ~exist(wnd_path, 'file')
        toks= regexp(bts_file, 'URef-(\d*)_RandSeed1-(\d*)_', 'tokens', 'once');
        if length(toks)~=2
            error ('Wind file name has no wind speed and randseed')
        end
        vw= str2double(toks{1});
        rs= str2double(toks{2});
        wnd_path= fullfile(wind_dir, sprintf('URef_%02d_Seed_%02d%02d.wnd', vw, vw, rs));
    end

    if exist(wnd_path, 'file')
        d= addWND(wnd_path, d, R);
    else
        error('Neither BTS nor WND file found')
    end
end
end

function d= addBTS(bts_path, d)
    [velocity, ~, ~, ~, ~, ~, ny, dz, dy, dt,~, ~, u_hub]= readfile_BTS(bts_path);
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

function d= addWND(wnd_path, d, R)
[velocity, y, z, nz, ny, dz, dy, dt, zHub, z1, SummVars]= readfile_WND(wnd_path);

nt= size(velocity, 1);

% get points in rotor disc
[Y, Z]= meshgrid(y, z-zHub);

DistanceFromHub= (Z(:).^2+Y(:).^2).^0.5;
PointsInRotorDisc= DistanceFromHub <= R;

% calculate REWS = mean of all u components in rotor disc
U3D= squeeze(velocity(:, 1, :, :));       % [nt,ny,nz]
U2D= reshape(U3D, nt, []);               % [nt,ny*nz]

wind= mean(U2D(:, PointsInRotorDisc), 2);
tv= (0:nt-1)*dt;

time= d.Time; % + ((ny-1)*dy/2)/u_hub;
d.RtVAvgxh.Data= interp1(tv, wind, time);
end
