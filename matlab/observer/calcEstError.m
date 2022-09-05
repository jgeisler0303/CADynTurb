function e2= calcEstError(d_ref, d_est, param, t_start)

if ~exist('t_start', 'var')
    t_start= 200;
end

[x_ref]= turbine_T2B2cG_aero_est_state_out(d_ref, param);
[x_est]= turbine_T2B2cG_aero_est_state_out(d_est, param);

idx= d_est.Time>t_start;
e= x_ref(:, idx)-x_est(:, idx);

e2= sqrt(mean(e.*e, 2));
