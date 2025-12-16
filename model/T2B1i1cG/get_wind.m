%%
sim_dir= fullfile(model_dir, '../../ref_sim/sim_dyn_inflow');
wind_dir= fullfile(model_dir, '../../ref_sim/wind');

ref_sims= get_ref_sims(sim_dir, '1p1*_maininput.outb');

%%
j= 1;
for i= find(ref_sims.yaw==0)'
    [~, f]= fileparts(ref_sims.files{i});
    file_name{j}= f;
    
    d_FAST= loadData(ref_sims.files{i}, wind_dir);    
    
    v(j, :)= d_FAST.RtVAvgxh.Data;
    h_shear(j, :)= d_FAST.RtHSAvg.Data;
    v_shear(j, :)= d_FAST.RtVSAvg.Data;

    j= j+1;
end
time= d_FAST.Time;
