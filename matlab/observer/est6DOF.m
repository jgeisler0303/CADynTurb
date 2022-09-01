function [x_est, dx_est, Sigma_est]= est6DOF(x, dx, y_pred, y_meas, Sigma, AB, CD, Q, R, t)
tow_fa_idx= 1;
tow_ss_idx= 2;
bld_flp_idx= 3;
bld_edg_idx= 4;
phi_rot_idx= 5;
Dphi_gen_idx= 6;
vwind_idx= 7;
dtow_fa_idx= 8;
dtow_ss_idx= 9;
dbld_flp_idx= 10;
dbld_edg_idx= 11;
dphi_rot_idx= 12;
dDphi_gen_idx= 13;
dvwind_idx= 14;

out_tow_fa_dd= 1;
out_tow_ss_dd= 2;
out_phi_gen_d= 3;


estimated_states= [
    tow_fa_idx
    tow_ss_idx
    bld_flp_idx
    bld_edg_idx
    Dphi_gen_idx
    vwind_idx
    dtow_fa_idx
    dtow_ss_idx
    dbld_flp_idx
    dbld_edg_idx
    dphi_rot_idx
    dDphi_gen_idx
    ];

out_idx= [out_tow_fa_dd, out_tow_ss_dd, out_phi_gen_d];

x_scaling= [
    0.4
    0.1
    5
    0.05
    0.002
    12
    0.1
    0.05
    1
    0.1
    1
    0.1    
    ];
x_scaling= ones(12, 1);

if isempty(Q)
    Q= diag(([zeros(1, 5),...    % position states
                0.1, ...        % wind speed
                0.0024, ...     % tower FA deflection speed
                0.0024, ...     % tower SS deflection speed
                0.0024, ...     % blade flap defelction speed
                0.0024, ...     % blade edge defelction speed
                0.01/30*pi, ... % rotor speed
                1/30*pi  ...    % rotor generator speed difference
                ].*x_scaling).^2);          % filtered wind speed rate of change
    Q= diag(([zeros(1, 5),...    % position states
                0.1, ...        % wind speed
                0, ...     % tower FA deflection speed
                0, ...     % tower SS deflection speed
                0, ...     % blade flap defelction speed
                0, ...     % blade edge defelction speed
                0.01/30*pi, ... % rotor speed
                0  ...    % rotor generator speed difference
                ].*x_scaling).^2);          % filtered wind speed rate of change
elseif length(Q)==14
    Q= Q(estimated_states, estimated_states);
end
if isempty(R)
    R= diag([ ...
        0.1 ...                 % tower FA acc
        0.1 ...                 % tower SS acc
        1/30*pi ...             % rotor generator speed 
        ].^2);
    R= R*100000^2;
elseif length(R)==5
    R= R(out_idx, out_idx);
end

if isempty(Sigma)
    Sigma= eye(12);
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

Sigma__= A*Sigma*A' + Q;
K= Sigma__*C'*(C*Sigma__*C' + R)^-1;
d= y_meas(out_idx) - y_pred(out_idx);
xx_est= xx_est + K*d; % should only be output in next iteration but input should be from current time step
Sigma_est= (eye(length(xx_est))-K*C) * Sigma__;
Sigma_est= 0.5*(Sigma_est+Sigma_est');

xx_est= xx_est.*x_scaling;

x_est= x;
x_est(estimated_states(1:6))= xx_est(1:6);
dx_est= dx;
dx_est(estimated_states(7:end)-7)= xx_est(7:end);
