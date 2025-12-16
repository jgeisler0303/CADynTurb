function plotMPCTrajectory(x, OmSet, TrqSet)
%%
t= 0:0.1:15;

%%
subplot(6, 1, 1)
plot(t, x(:, 3), t(1:end), x(:, 2))
legend('actual pitch', 'set point')
title('pitch')
grid on

subplot(6, 1, 2)
plot(t, x(:, 4:5)/pi*30, t, t*0+OmSet/pi*30)
title('speed')
legend('generator speed', 'rotor speed', 'set point')
grid on

subplot(6, 1, 3)
plot(t(1:end), x(:, 1), t(1:end), x(:, 11), t(1:end), x(:, 1)*0+TrqSet)
legend('gen trq', 'avg trq', 'set point')
title('torque')
grid on

subplot(6, 1, 4)
plot(t, x(:, 7), t, x(:, 9))
legend('twr', 'bld')
title('tower, blade')
grid on

subplot(6, 1, 5)
plot(t, x(:, 8), t, x(:, 10))
legend('twr', 'bld')
title('tower, blade rate')
grid on

subplot(6, 1, 6)
plot(t(1:end), x(:, 1).*x(:, 4))
title('power')
grid on
