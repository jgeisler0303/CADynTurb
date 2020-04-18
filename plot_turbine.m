%%
clf
%  subplot(7, 1, 1)
%  plot(t, x([3 6], :))
%  grid on
%  title('drive train position')
%  ylabel('position in rad')
%  xlabel('time in s')

subplot(3, 1, 1)
plot(t, dx([3 6], :)/pi*30*param.GBRatio)
grid on
title('drive train speed')
ylabel('speed in rmpm')
xlabel('time in s')
legend('rotor (hss)', 'generator');

subplot(3, 1, 2)
plot(t, x(1:2, :))
grid on
title('tower deflection')
ylabel('deflection in m')
xlabel('time in s')

%  subplot(7, 1, 4)
%  plot(t, dx(1:2, :))
%  grid on
%  title('tower deflection rate')
%  ylabel('rate in m/s')
%  xlabel('time in s')
%  legend('longitudinal', 'lateral');

subplot(3, 1, 3)
plot(t, x(4:5, :))
grid on
title('collective blade tip deflection')
ylabel('deflection in m')
xlabel('time in s')

%  subplot(7, 1, 6)
%  plot(t, dx(4:5, :))
%  grid on
%  title('collective blade tip deflection rate')
%  ylabel('rate in m')
%  xlabel('time in s')
%  legend('flapwise', 'edgewise');

%  subplot(7, 1, 7)
%  plot(t, -x(13, :)/pi*180)
%  grid on
%  title('pitch angle')
%  ylabel('angle in °')
%  xlabel('time in s')



%  linkaxes(findobj(gcf, 'type', 'axes'), 'x')
