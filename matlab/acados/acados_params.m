function ap= acados_params(parameter_names, param)

tot_len= 0;
for i= 1:length(parameter_names)
    tot_len= tot_len + numel(param.(parameter_names{i}));
end

ap= zeros(tot_len, 1);

idx= 1;
for i= 1:length(parameter_names)
    n= numel(param.(parameter_names{i}));
    ap(idx:idx+n-1)= param.(parameter_names{i})(:);
    idx= idx+n;
end
