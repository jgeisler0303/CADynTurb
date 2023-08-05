function ref_sims= get_ref_sims(sim_dir, file_pattern)

dd= dir(fullfile(sim_dir, file_pattern));
files= {dd.name};

vv= zeros(length(files), 1);
yaw= zeros(length(files), 1);
for i= 1:length(files)
    v_str= regexp(files{i}, 'URef-(\d+)_', 'tokens', 'once');
    vv(i)= str2double(v_str{1});

    yaw_cell= regexp(files{i}, 'NacYaw-(neg)?(\d+)_', 'tokens', 'once');
    if isempty(yaw_cell)
        yaw(i)= nan;
    else
        yaw(i)= str2double(yaw_cell{2});
        if ~isempty(yaw_cell{1})
            yaw(i)= -yaw(i);
        end
    end
    files{i}= fullfile(sim_dir, files{i});
end

ref_sims.files= files;
ref_sims.vv= vv;
ref_sims.yaw= yaw;
