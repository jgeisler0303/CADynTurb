function d= add_average_wind(d, wind_dir, fst_file, R)
% TODO: does not consider OverHang
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
    d= addBTS(bts_path, d, R);
else
    if ~exist('wnd_path', 'var') || ~exist(wnd_path, 'file')
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

function d= addBTS(bts_path, d, R)
    [velocity, ~, y, z, ~, ~, ny, ~, dy, dt, zHub, ~, u_hub]= readfile_BTS(bts_path);

    % assume the wind file is not periodic, otherwise the offset should be 0
    t_offset= ((ny-1)*dy/2)/u_hub;
    d= addWind(d, velocity, y, z-zHub, dt, t_offset, R);
end

function d= addWND(wnd_path, d, R)
    [velocity, y, z, ~, ~, ~, ~, dt, zHub, ~, ~]= readfile_WND(wnd_path);
    
    % assume the wind file is periodic, otherwise the offset should be ((ny-1)*dy/2)/u_hub
    t_offset= 0;
    d= addWind(d, velocity, y, z-zHub, dt, t_offset, R);
end

function d= addWind(d, velocity, y, z, dt, t_offset, R)
    % get points in rotor disc
    [Z, Y]= meshgrid(z, y);
    
    if length(y)<=5 || length(z)<=5 || isempty(R)
        PointsInRotorDisc= true(size(Z(:)));
    else
        DistanceFromHub= (Z(:).^2+Y(:).^2).^0.5;
        PointsInRotorDisc= DistanceFromHub <= R;
    end

    nt= size(velocity, 1);
    U3D= squeeze(velocity(:, 1, :, :));       % [nt,ny,nz]
    U2D= reshape(U3D, nt, []);               % [nt,ny*nz]

    % make Y and Z zero mean
    Y= Y-mean(Y(:));
    Z= Z-mean(Z(:));
    vel_shear= [ones(sum(PointsInRotorDisc), 1) Y(PointsInRotorDisc) Z(PointsInRotorDisc)]\U2D(:, PointsInRotorDisc)';
    
    wind= vel_shear(1, :)'; % mean(U2D(:, PointsInRotorDisc), 2);
    hshear= vel_shear(2, :)';
    vshear= vel_shear(3, :)';

    tv= (0:nt-1)*dt;
    
    time= d.Time + t_offset;
    % TODO: extend periodic wind
    d.RtVAvgxh.Data= interp1(tv, wind, time);

    RtHSAvg= timeseries('RtHSAvg');
    RtHSAvg.Time= d.Time;
    RtHSAvg.Data=interp1(tv, hshear, time);
    RtHSAvg.DataInfo.Units= 'm/s/m';
    RtHSAvg.TimeInfo.Units= 's';
    d= d.addts(RtHSAvg);
    
    RtVSAvg= timeseries('RtVSAvg');
    RtVSAvg.Time= d.Time;
    RtVSAvg.Data=interp1(tv, vshear, time);
    RtVSAvg.DataInfo.Units= 'm/s/m';
    RtVSAvg.TimeInfo.Units= 's';

    d= d.addts(RtVSAvg);    
end
