function y= notch_369p(u, omega, dt)
y= notch_omega(u, 3*omega, 3*omega, dt);
y= notch_omega(y, 6*omega, 6*omega, dt);
y= notch_omega(y, 9*omega, 9*omega, dt);
y= notch_omega(y, 12*omega, 12*omega, dt);