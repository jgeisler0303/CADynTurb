function d_acados= run_acados_simulation(acados_model, d_in, param)

model_parameters
% [param, precalcNames]= model_name  _pre_calc(param);
ap= acados_params(parameter_names, param);
acados_model.set('p', ap);
has_wind_param= any(strcmp('vwind', parameter_names));

% TODO: fix setting simstep
% acados_model.set('T', d_in.Time(2)-d_in.Time(1));

%% simulate system in loop
clc
[x_ref, u_ref]= convertFAST_CADyn(d_in, param, 0);

N_sim= length(d_in.Time);
x_sim= x_ref;

for ii= 2:N_sim
	acados_model.set('x', x_sim(:, ii-1));
	acados_model.set('u', u_ref(:, ii-1));
    if has_wind_param
        param.vwind= d_in.RtVAvgxh.Data(ii-1);
        ap= acados_params(parameter_names, param);
        acados_model.set('p', ap);
    end

    acados_model.set('xdot', zeros(size(x_ref, 1), 1));
	acados_model.solve();

	% get simulated state
	x_sim(:, ii) = acados_model.get('xn');
    
    % forward sensitivities ( dxn_d[x0,u] )
    % S_forw = sim.get('S_forw');
end

q= x_sim(1:size(x_sim, 1)/2, :);
dq= x_sim(size(x_sim, 1)/2+1:end, :);
ddq= [];
y_sim= [];
d_acados= convertFAST_CADyn(d_in.Time, q, dq, ddq, u_ref, y_sim, param);