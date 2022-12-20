function [q_est, dq_est, Sigma_est, Q, R]= est_T2B1i1cG_aero_est(x, dx, u, y_pred, y_meas, param, Sigma, AB, CD, Q, R, N, t, alpha_adapt, adjust_adapt)

model_indices

estimated_states= [
    tow_fa_idx
    tow_ss_idx
    bld1_flp_idx
    bld2_flp_idx
    bld3_flp_idx
    bld_edg_idx
    phi_rot_idx
    Dphi_gen_idx
    vwind_idx
    h_shear_idx
    v_shear_idx
    m_bld_mom_idx
    
    tow_fa_d_idx
    tow_ss_d_idx
    bld1_flp_d_idx
    bld2_flp_d_idx
    bld3_flp_d_idx
    bld_edg_d_idx
    phi_rot_d_idx
    Dphi_gen_d_idx
    ];
n_estimated_dofs= 12;

out_idx= 1:ny;

x_scaling= ones(length(estimated_states), 1);

if isempty(Q)
    Q= 1e-6*eye(length(estimated_states));
end
if isempty(R)
    R= 1e3*eye(length(out_idx));
end
if isempty(N)
    N= zeros(length(Q), length(R));
end

if isempty(Sigma)
    Sigma= eye(length(estimated_states));
end


xx= [x; dx];
xx_est= xx(estimated_states)./x_scaling;

A= AB(estimated_states, estimated_states);
A= diag(x_scaling)^-1*A*diag(x_scaling);
C= CD(out_idx, estimated_states);
C= C*diag(x_scaling);
% D= CD(:, 15:end);

if any(isnan(xx_est)) || any(isnan(A(:))) || any(isnan(C(:)))
    error('x is nan at t= %fs', t);
end
if rank(obsv(A, C))~=length(xx_est)
    warning('system not observable at t= %fs', t);
end

% Dan Simon eq (7.14)
Sigma__= A*Sigma*A' + Q;
K= (Sigma__*C' + N)*(C*Sigma__*C' + C*N + N'*C' + R)^-1;
Sigma_est= Sigma__ - K*(C*Sigma__ + N');

Sigma_est= 0.5*(Sigma_est+Sigma_est');

d= y_meas(out_idx) - y_pred(out_idx);
xx_est= xx_est + K*d; % should only be output in next iteration but input should be from current time step

xx_est= xx_est.*x_scaling;

% 
x_ul= [         2;                  % tower FA deflection
                1;                  % tower SS deflection
                10;                  % blade flap defelction
                10;                  % blade flap defelction
                10;                  % blade flap defelction
                5;                  % blade edge defelction
                inf;                  % rotor angle
                pi;                  % generator angle offset
                40; % wind speed
                5;  %h_shear
                10; % v_shear
                5e6; % m_bld_flp_mom_idx
                100;                  % tower FA deflection speed
                100;                  % tower SS deflection speed
                100;                  % blade flap defelction speed
                100;                  % blade flap defelction speed
                100;                  % blade flap defelction speed
                100;                  % blade edge defelction speed
                50/30*pi; % rotor speed
                50/30*pi;                  % rotor generator speed difference
                ];                
x_ll= [         -2;                  % tower FA deflection
                -1;                  % tower SS deflection
                -5;                  % blade flap defelction
                -5;                  % blade flap defelction
                -5;                  % blade flap defelction
                -5;                  % blade edge defelction
                -inf;                % rotor angle
                -pi;                  % generator angle offset
                2; % wind speed
                -5;  %h_shear
                -5; % v_shear
                -5e6; % m_bld_flp_mom_idx
                -100;                  % tower FA deflection speed
                -100;                  % tower SS deflection speed
                -100;                  % blade flap defelction speed
                -100;                  % blade flap defelction speed
                -100;                  % blade flap defelction speed
                -100;                  % blade edge defelction speed
                0.01; % rotor speed
                -50/30*pi;                  % rotor generator speed difference
                ];                 

xx_est= min(max(xx_est, x_ll), x_ul);

q_est= x;
q_est(estimated_states(1:n_estimated_dofs))= xx_est(1:n_estimated_dofs);
dq_est= dx;
dq_est(estimated_states((n_estimated_dofs+1):end)-nq)= xx_est((n_estimated_dofs+1):end);

if exist('alpha_adapt', 'var') && ~isempty(alpha_adapt)
    ep= d-C*K*d; % should be real residual: y_meas-h(x_corr)
    if exist('adjust_adapt', 'var') && ~isempty(adjust_adapt)
        ep= ep.*adjust_adapt(:);
    end

    % but d= y_meas-y_pred
    % x_corr=x_pred+K*d
    % C*K*d=C*x_corr-C*x_pred=y_corr-y_pred
    % d-C*K*d=y_meas-y_pred-(y_corr-y_pred)=y_meas-y_corr

%     y_corr= turbine_T2B2cG_aero_est_bld_mom_mex(x_est, dx_est, u, param);
%     ep= y_meas(out_idx) - y_corr(out_idx);

    R= alpha_adapt*R + (1-alpha_adapt)*(ep*ep' + C*Sigma__*C');

    Q= alpha_adapt*Q + (1-alpha_adapt)*(K*(d*d')*K');
end
