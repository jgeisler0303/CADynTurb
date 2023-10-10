function [d_mean, d_std, acorr_rms]= evalEKFPerform(model, d_in, d_est, param, for_print)
if ~exist('print', 'var')
    for_print= false;
end

[~, ~, y_meas]= convertFAST_CADyn(d_in, param, 1);
model_indices
get_ekf_config= str2func([model '_ekf_config']);
ekf_config= get_ekf_config();

d= y_meas' - d_est.y.Data;
maxlag= sum(d_in.Time<20); % 20s
idx= d_in.Time>30;

acorr_rms= zeros(size(y_meas, 1), 1);
d_mean=  zeros(size(y_meas, 1), 1);
d_std=  zeros(size(y_meas, 1), 1);

if for_print
    tiledlayout((size(y_meas, 1)+1)*2, 1)
else
    tiledlayout(size(y_meas, 1)+1, 2)
end
nexttile
wind_cc= corrcoef(d_in.RtVAvgxh.Data(idx), d_est.RtVAvgxh.Data(idx));
wind_cc= wind_cc(1, 2);

plot(d_in.Time(idx), d_in.RtVAvgxh.Data(idx), d_est.Time(idx), d_est.RtVAvgxh.Data(idx))
hold on
plot(d_est.Time(idx), d_est.RtVAvgxh.Data(idx)+2*sqrt(d_est.p_xx.Data(idx, find(ekf_config.estimated_states==vwind_idx))), 'k')
plot(d_est.Time(idx), d_est.RtVAvgxh.Data(idx)-2*sqrt(d_est.p_xx.Data(idx, find(ekf_config.estimated_states==vwind_idx))), 'k')
try
    h= plot(d_in.Time(idx), d_in.WindMeas1.Data(idx));
    uistack(h, 'bottom')
catch e
end
hold off
grid on
title(sprintf('corrcoeff: %f', wind_cc))

nexttile
d_norm_mean= mean(d_est.d_norm.Data(idx));
plot(d_est.Time(idx), d_est.d_norm.Data(idx), [d_est.Time(1) d_est.Time(end)], d_norm_mean*[1 1])
grid on
title(sprintf('mean: %f', d_norm_mean))


for i= 1:size(y_meas, 1)
    nexttile
    acorr= xcorr(d(idx, i), maxlag, 'normalized');
    acorr= acorr(ceil((length(acorr)+1)/2):end);
    plot(acorr)

    acorr_rms(i)= rms(acorr(2:end));
    title(sprintf('mean: %f, std: %f, rms: %f', mean(acorr(2:end)), std(acorr(2:end)), acorr_rms(i)))
    grid on

    nexttile
    plot(d_in.Time(idx), d(idx, i))
    hold on
    plot(d_est.Time(idx), 2*sqrt(d_est.s_xx.Data(idx, i)), 'k')
    plot(d_est.Time(idx), -2*sqrt(d_est.s_xx.Data(idx, i)), 'k')    
    hold off
    grid on
    d_mean(i)= mean(d(idx, i));
    d_std(i)= std(d(idx, i));
    title(sprintf('mean: %f, std: %f', d_mean(i), d_std(i)))
end