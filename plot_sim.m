clf
subplot(3, 1, 1)
plot(t, cpu_time)
grid on
xlabel('time in s')

subplot(3, 1, 2)
plot(t, int_err)
grid on
xlabel('time in s')

subplot(3, 1, 3)
plot(t, n_steps, t, n_backsteps)
grid on
xlabel('time in s')
