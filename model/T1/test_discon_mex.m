%%DISCON
DISCON_param.comm_interval= 0.01;
DISCON_param.Ptch_Min= 0;
DISCON_param.Ptch_Max= 90;
DISCON_param.PtchRate_Min= -15;
DISCON_param.PtchRate_Max= 15;
DISCON_param.pitch_actuator= 0;
DISCON_param.Gain_OM= 1;
DISCON_param.GenSpd_MinOM= 800;
DISCON_param.GenSpd_MaxOM= 1200;
DISCON_param.GenSpd_Dem= 1200;
DISCON_param.GenTrq_Dem= 40000;
DISCON_param.GenPwr_Dem= 0;
DISCON_param.Ptch_SetPnt= 0;
DISCON_param.yaw_ctrl_mode= 0;
DISCON_param.num_blades= 3;
DISCON_param.pitch_ctrl_mode= 0;
DISCON_param.gen_contractor= 1;
DISCON_param.controller_state= 0;
DISCON_param.time_to_output= 0;
DISCON_param.version= 0.0;


%%
addpath(fullfile(pwd, 'generated'))
addpath(fullfile(pwd, '../../simulator'))
model_indices
load('params_config')

%%
t_end= 150;
ts= 0.01;

nt= ceil(t_end/ts);
t= 0:ts:t_end-ts;

vwind= 11*ones(1, nt);
vwind(t>50 & t<100)= 12;
% vwind= vwind*0.99; % adjustment for better match with OpenFAST

q= zeros(nq, nt);
dq= zeros(nq, nt);
ddq= zeros(nq, nt);

q(tow_fa_idx, 1)= 0;
q(phi_rot_idx, 1)= 0;

dq(tow_fa_idx, 1)= 0;
dq(phi_rot_idx, 1)= 10/30*pi;

u= nan(nu, nt);

u(in_vwind_idx, 1)= vwind(1);
u(in_Tgen_idx, 1)= 0;
u(in_theta_idx, 1)= 0;

DISCON_mex() % terminate id necessary
DISCON_mex(fullfile(pwd, '../../5MW_Baseline/DISCON.dll'), DISCON_param) % initialize
[~, ~, ddq(:, 1)]= T1_mex(q(:, 1), dq(:, 1), ddq(:, 1), u(:, 1), p_, 0);

for i= 2:nt
    Tgen_meas= u(in_Tgen_idx, i-1); % last setpoint, maybe not used by controller
    om_rot= dq(phi_rot_idx, i-1);
    om_gen= dq(phi_rot_idx, i-1)*p_.GBRatio;
    theta_meas= -u(in_theta_idx, i-1); % last setpoint, maybe not used by controller
    tow_fa_acc= 0; % not used by controller
    tow_ss_acc= 0; % not used by controller
    phi_rot= q(phi_rot_idx, i-1); % probably not used by controller

    [theta_set, Tgen_set, status]= DISCON_mex(t(i), vwind(i), Tgen_meas, om_rot, om_gen, theta_meas, tow_fa_acc, tow_ss_acc, phi_rot);
    if status==-1
        error('DISCON finished')
    end

    u(in_vwind_idx, i)= vwind(i);
    u(in_Tgen_idx, i)= Tgen_set;
    u(in_theta_idx, i)= -theta_set; % sign of theta is reverse in controller and model
    [q(:, i), dq(:, i), ddq(:, i)]= T1_mex(q(:, i-1), dq(:, i-1), ddq(:, i-1), u(:, i), p_, ts);
%     [~, x]= ode23s(@(t, x)ode(x(1:2), x(3:4), u(:, i), p_), [0 ts], [q(:, i-1); dq(:, i-1)]);
%     q(:, i)= x(end, 1:2)';
%     dq(:, i)= x(end, 3:4)';
end
DISCON_mex()

%%
t_end= 150;
ts= 0.01;

nt= ceil(t_end/ts);
t= 0:ts:t_end-ts;

vwind= 11*ones(1, nt);
vwind(t>50 & t<100)= 12;
% vwind= vwind*0.99; % adjustment for better match with OpenFAST

q1= zeros(nq, nt);
dq1= zeros(nq, nt);
ddq1= zeros(nq, nt);

q1(tow_fa_idx, 1)= 0;
q1(phi_rot_idx, 1)= 0;

dq1(tow_fa_idx, 1)= 0;
dq1(phi_rot_idx, 1)= 10/30*pi;

u1= nan(nu, nt);

u1(in_vwind_idx, 1)= vwind(1);
u1(in_Tgen_idx, 1)= 0;
u1(in_theta_idx, 1)= 0;

DISCON_mex() % terminate id necessary
DISCON_mex(fullfile(pwd, '../../5MW_Baseline/DISCON.dll'), DISCON_param) % initialize
k= zeros(4, 1);
for i= 2:nt
    Tgen_meas= u1(in_Tgen_idx, i-1); % last setpoint, maybe not used by controller
    om_rot= dq1(phi_rot_idx, i-1);
    om_gen= dq1(phi_rot_idx, i-1)*p_.GBRatio;
    theta_meas= -u1(in_theta_idx, i-1); % last setpoint, maybe not used by controller
    tow_fa_acc= 0; % not used by controller
    tow_ss_acc= 0; % not used by controller
    phi_rot= q1(phi_rot_idx, i-1); % probably not used by controller

    [theta_set, Tgen_set, status]= DISCON_mex(t(i), vwind(i), Tgen_meas, om_rot, om_gen, theta_meas, tow_fa_acc, tow_ss_acc, phi_rot);
    if status==-1
        error('DISCON finished')
    end

    u1(in_vwind_idx, i)= vwind(i);
    u1(in_Tgen_idx, i)= Tgen_set;
    u1(in_theta_idx, i)= -theta_set; % sign of theta is reverse in controller and model
%     [~, x]= ode23s(@(t, x)ode(x(1:2), x(3:4), u1(:, i), p_), [0 ts], [q1(:, i-1); dq1(:, i-1)]);
%     q1(:, i)= x(end, 1:2)';
%     dq1(:, i)= x(end, 3:4)';
    [q1(:, i), dq1(:, i), k]= iRK1_symplect(q1(:, i-1), dq1(:, i-1), u1(:, i), p_, ts, k);
end
DISCON_mex()

%%
tiledlayout(3, 1)
nexttile
plot(t, -u(in_theta_idx, :)/pi*180, t, -u1(in_theta_idx, :)/pi*180)
ylabel('Pitch angle in °')
grid on

nexttile
plot(t, u(in_Tgen_idx, :)/1000, t, u1(in_Tgen_idx, :)/1000)
ylabel('Gen.torque in kNm')
grid on

nexttile
plot(t, dq(phi_rot_idx, :)/pi*30, t, dq1(phi_rot_idx, :)/pi*30)
ylabel('Rot.speed in rpm')
grid on

function f= ode(q, dq, u, p_)
[M, f, A, B, C, D]= T1_descriptor_mex(q, dq, u, p_);
f= [dq; M\f];
end