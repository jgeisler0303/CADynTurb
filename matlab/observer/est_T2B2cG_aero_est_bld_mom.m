function [x_est, dx_est, Sigma_est, Q, R]= est_T2B2cG_aero_est_bld_mom(x, dx, u, y_pred, y_meas, param, Sigma, AB, CD, Q, R, N, t, alpha_adapt)

model_indices

estimated_states= [
    tow_fa_idx
    tow_ss_idx
    bld_flp_idx
    bld_edg_idx
    Dphi_gen_idx
    vwind_idx
    tow_fa_d_idx
    tow_ss_d_idx
    bld_flp_d_idx
    bld_edg_d_idx
    phi_rot_d_idx
    Dphi_gen_d_idx
    ];

out_idx= [out_tow_fa_acc_idx, out_tow_ss_acc_idx, out_gen_speed_idx, out_bld_flp_mom_idx, out_bld_edg_mom_idx];

x_scaling= ones(12, 1);

if isempty(Q)
    Q= 1e-6*eye(length(estimated_states));
elseif length(Q)==14
    Q= Q(estimated_states, estimated_states);
end
if isempty(R)
    R= eye(length(out_idx));
elseif length(R)==5
    R= R(out_idx, out_idx);
end
if isempty(N)
    N= zeros(length(Q), length(R));
elseif size(N, 1)==14
    N= N(estimated_states, out_idx);
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
x_ul= [  2;                  % tower FA deflection
                1;                  % tower SS deflection
                10;                  % blade flap defelction
                3;                  % blade edge defelction
                pi;                  % generator angle offset
                40; % wind speed
                inf;                  % tower FA deflection speed
                inf;                  % tower SS deflection speed
                inf;                  % blade flap defelction speed
                inf;                  % blade edge defelction speed
                50/30*pi; % rotor speed
                50/30*pi;                  % rotor generator speed difference
                ];                
x_ll= [  -2;                  % tower FA deflection
                -1;                  % tower SS deflection
                -10;                  % blade flap defelction
                -3;                  % blade edge defelction
                -pi;                  % generator angle offset
                2; % wind speed
                -inf;                  % tower FA deflection speed
                -inf;                  % tower SS deflection speed
                -inf;                  % blade flap defelction speed
                -inf;                  % blade edge defelction speed
                0; % rotor speed
                -500/30*pi;                  % rotor generator speed difference
                ];                 % filtered wind speed rate of change

xx_est= min(max(xx_est, x_ll), x_ul);

x_est= x;
x_est(estimated_states(1:6))= xx_est(1:6);
dx_est= dx;
dx_est(estimated_states(7:end)-7)= xx_est(7:end);


if exist('alpha_adapt', 'var') && ~isempty(alpha_adapt)
%     y_corr= turbine_T2B2cG_aero_est_bld_mom_mex(x_est, dx_est, u, param);
    ep= d-C*K*d; % y_+C*dx should be real h(x_est)
%     ep= y_meas(out_idx) - y_corr(out_idx);
    R= alpha_adapt*R + (1-alpha_adapt)*(ep*ep' + C*Sigma__*C');

    Q= alpha_adapt*Q + (1-alpha_adapt)*(K*(d*d')*K');
end
