function [d_out, cpu_time]= sim_turbine_T2B2cG_aero_ekf_mex(d_in, param, Q, R, N)
if ~exist('N', 'var')
    N= [];
end

% TODO generate this automatically
tow_fa_idx= 1;
tow_ss_idx= 2;
bld_flp_idx= 3;
bld_edg_idx= 4;
phi_rot_idx= 5;
Dphi_gen_idx= 6;
vwind_idx= 7;

dvwind_idx= 1;
Tgen_idx= 2;
theta_idx= 3;


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

estimated_states= turbine_T2B2cG_aero_ekf_mex;
out_idx= 1:3;

Q= Q(estimated_states, estimated_states);
R= R(out_idx, out_idx);
if isempty(N)
    N= zeros(length(Q), length(R));
elseif size(N, 1)==14
    N= N(estimated_states, out_idx);
end


% standard
% opts= struct('StepTol', 1e-8, 'AbsTol', 1e-6, 'RelTol', 1e-6, 'hminmin', 1E-8, 'jac_recalc_step', 4, 'max_steps', 10);
% one step
opts= struct('StepTol', 1e6, 'AbsTol', 1e6, 'RelTol', 1e6, 'hminmin', 1E-8, 'jac_recalc_step', 10, 'max_steps', 1);

u(dvwind_idx)= 0;
u(Tgen_idx)= 10000;
u(theta_idx)= 0;

x= zeros(7, 1);
dx= zeros(7, 1);
x(phi_rot_idx)= 0.0;
dx(phi_rot_idx)= 1000.0/30.0*pi/param.GBRatio;
x(Dphi_gen_idx)= u(Tgen_idx)*param.GBRatio/param.DTTorSpr;
dx(Dphi_gen_idx)= 0;
x(vwind_idx)= d_in.RtVAvgxh.Data(1);

opts_init= opts;
opts_init.doflocked= zeros(6, 1);
opts_init.doflocked(Dphi_gen_idx)= 1;
opts_init.doflocked(phi_rot_idx)= 1;
opts_init.doflocked(vwind_idx)= 1;

[q0, qd0, ~, ~, ~, ~, res]= turbine_T2B2cG_aero_est_mex(x, dx, u, param, 0, opts_init);
if ~res
    error('Static equilibrium could not be found');
end
xx0= [q0, qd0];
x0= xx0(estimated_states);

t= d_in.Time;
dt= t(2)-t(1);
nt= length(t);

u= zeros(3, nt);
u(dvwind_idx, :)= 0;
u(Tgen_idx, :)= d_in.GenTq.Data*1000;
u(theta_idx, :)= -d_in.BlPitchC.Data/180*pi;

[x_ref, y_meas]= turbine_T2B2cG_aero_est_state_out(d_in, param);

[q, qd, qdd, y_pred, cpu_time]= turbine_T2B2cG_aero_ekf_mex(x0, u, y_meas, param, dt, x_ul, x_ll, Q, R, N, opts);

d_out= turbine_T2B2cG_aero_est_state_out(t, q, qd, qdd, u, y_pred, param);