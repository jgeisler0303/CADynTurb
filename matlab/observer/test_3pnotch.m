t= d_turb.Time;
dt= diff(t(1:2));
% dt= 0.01;
Wo= 2*pi*0.6/(pi/dt);
[NUM,DEN] = iirnotch(Wo, Wo); no3p= tf(NUM, DEN, dt);
[NUM,DEN] = iirnotch(2*Wo, 2*Wo); no6p= tf(NUM, DEN, dt);
[NUM,DEN] = iirnotch(3*Wo, 3*Wo); no9p= tf(NUM, DEN, dt);
y=lsim(no3p*no6p*no9p, d_turb.RootMyb.Data, d_turb.Time);

% y_= notch_omega(d_turb.RootMyb.Data, d_turb.RootMyb.Data*0+2*pi*0.6, 2*pi*0.6, dt);
% y_= notch_omega(y_, d_turb.RootMyb.Data*0+2*2*pi*0.6, 2*2*pi*0.6, dt);
% y_= notch_omega(y_, d_turb.RootMyb.Data*0+3*2*pi*0.6, 3*2*pi*0.6, dt);
omega= d_turb.LSSTipVxa.Data/30*pi;
y_= notch_369p(d_turb.RootMyb.Data, omega, dt);

% plot(t, d_turb.RootMyb.Data, t, d_shear.RootMyb.Data, t, y, t, y_)
plot(t, d_turb.RootMyb.Data, t, y, t, y_)

%%
bode(no3p*no6p*no9p)