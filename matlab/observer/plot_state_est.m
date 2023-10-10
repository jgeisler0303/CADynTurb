function plot_state_est(d_in, d_est, sensors, state_idx, fact)

ha= plot_timeseries_cmp(d_in, d_est, sensors, {}, {}, {}, 30);
idx= d_est.Time>30;

for i= 1:length(sensors)
    axes(ha(i))
    hold on
    h= plot(d_est.Time(idx), d_est.(sensors{i}).Data(idx)+2*sqrt(d_est.p_xx.Data(idx, state_idx(i)))*fact(i), 'k');
    uistack(h, 'bottom')
    h= plot(d_est.Time(idx), d_est.(sensors{i}).Data(idx)-2*sqrt(d_est.p_xx.Data(idx, state_idx(i)))*fact(i), 'k');
    uistack(h, 'bottom')
    hold off
end