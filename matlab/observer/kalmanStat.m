function t= kalmanStat(ref, est, param, t_start)    
if ~exist('t_start', 'var') || isempty(t_start)
    t_start= -inf;
end

idx= ref.Time>=t_start;

stats= {'val'};
sens= {'r_xx' 's_xx' 'p_xx' 'd_norm' 'acorr_rms' 'cc_vw_real' 'cc_vw_meas'};
t= table('Size', [length(sens) length(stats)], 'VariableTypes', repmat("double", 1, length(stats)), 'VariableNames', stats, 'RowNames', sens);


t('r_xx', 1)= {sqrt(mean(est.r_xx.Data(idx, :), 'all'))};
t('s_xx', 1)= {sqrt(mean(est.s_xx.Data(idx, :), 'all'))};
t('p_xx', 1)= {sqrt(mean(est.p_xx.Data(idx, :), 'all'))};
t('d_norm', 1)= {mean(est.d_norm.Data(idx), 'all')};

wind_cc= corrcoef(ref.RtVAvgxh.Data(idx), est.RtVAvgxh.Data(idx));
t('cc_vw_real', 1)= {wind_cc(1, 2)};

if ismember('Wind1VelX', ref.gettimeseriesnames)
    vw_meas= ref.Wind1VelX.Data(idx);
end
if ismember('WindMeas1', ref.gettimeseriesnames)
    vw_meas= ref.WindMeas1.Data(idx);
end
wind_cc= corrcoef(vw_meas, est.RtVAvgxh.Data(idx));
t('cc_vw_meas', 1)= {wind_cc(1, 2)};

[~, ~, y_meas]= convertFAST_CADyn(ref, param, 1);

d= y_meas' - est.y.Data;
maxlag= sum(ref.Time<20); % 20s

acorr_rms= [];
for i= 1:size(d, 2)
    acorr= xcorr(d(idx, i), maxlag, 'normalized');
    acorr= acorr(ceil((length(acorr)+1)/2):end);
    acorr_rms(i)= rms(acorr(2:end));
end
t('acorr_rms', 1)= {mean(acorr_rms)};


