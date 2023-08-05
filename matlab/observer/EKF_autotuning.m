function [q_est, dq_est, Sigma_est, Q, R]= EKF_autotuning(q, dq, y_pred, y_meas, param, ekf_config, Sigma, AB, CD, Q, R, N, t)

model_indices

if isempty(Q)
    Q= 1e-6*eye(length(ekf_config.estimated_states));
elseif length(Q)==nx
    Q= Q(ekf_config.estimated_states, ekf_config.estimated_states);
end
if isempty(R)
    R= eye(length(ekf_config.out_idx));
elseif length(R)==ny
    R= R(ekf_config.out_idx, ekf_config.out_idx);
end
if isempty(N)
    N= zeros(length(Q), length(R));
elseif size(N, 1)==nx
    N= N(ekf_config.estimated_states, ekf_config.out_idx);
end

if isempty(Sigma)
    Sigma= eye(length(ekf_config.estimated_states));
end


xx= [q; dq];
xx_est= xx(ekf_config.estimated_states)./ekf_config.x_scaling;

A= AB(ekf_config.estimated_states, ekf_config.estimated_states);
% A= diag(ekf_config.x_scaling)^-1*A*diag(ekf_config.x_scaling);
C= CD(ekf_config.out_idx, ekf_config.estimated_states);
% C= C*diag(ekf_config.x_scaling);
% D= CD(:, 15:end);

if rank(obsv(A, C))~=length(xx_est)
    warning('system not observable at t= %fs', t);
end

% Dan Simon eq (7.14)
Sigma__= A*Sigma*A' + Q;
K= (Sigma__*C' + N)*(C*Sigma__*C' + C*N + N'*C' + R)^-1;
Sigma_est= Sigma__ - K*(C*Sigma__ + N');

Sigma_est= 0.5*(Sigma_est+Sigma_est');

d= y_meas(ekf_config.out_idx) - y_pred(ekf_config.out_idx);
dx= K*d;
dx_= dx;
if isfield(param, 'adaptUpdate')
    dx_= dx_.*param.adaptUpdate;
end
xx_est= xx_est + dx_; % should only be output in next iteration but input should be from current time step

% xx_est= xx_est.*ekf_config.x_scaling;

xx_est= min(max(xx_est, ekf_config.x_ll), ekf_config.x_ul);

q_est= q;
q_est(ekf_config.estimated_states(1:ekf_config.n_estimated_dofs))= xx_est(1:ekf_config.n_estimated_dofs);
dq_est= dq;
dq_est(ekf_config.estimated_states((ekf_config.n_estimated_dofs+1):end)-nq)= xx_est((ekf_config.n_estimated_dofs+1):end);

if param.Tadapt>0
    alpha_adapt= exp(-param.ts/param.Tadapt);

% y_+C*dx should be real h(x_est):
% y_corr= model(x_est, dx_est, u, param);
% ep= y_meas(out_idx) - y_corr(out_idx);
    ep= d-C*K*d; 
    ep= ep.*param.adaptScale(:);
    R= alpha_adapt*R + (1-alpha_adapt)*(ep*ep' + C*Sigma__*C');

    Q= alpha_adapt*Q + (1-alpha_adapt)*(dx*dx');
end
