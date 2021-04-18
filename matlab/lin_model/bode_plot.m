q= [0.3 -0.04 0 3.5 0.05 0];
qd= [0 0 12/30*pi 0 0 1200/30*pi];
qdd= [0 0 0 0 0 0];
theta_ref= 5.5;
vwind_ref= 13;

VWIND= [12 13 14 15 20];
sys= cell(size(VWIND));
for i= 1:length(VWIND)
    vwind= VWIND(i);
    [A, B, C, D, E]= eval_lin_turbine('turbine_coll_flap_edge_pitch_aero_matlab_lin', param, q, qd, qdd, vwind, vwind_ref, theta_ref);
    sys{i}= dss(A, B(:, 3), C(3, :), D(3, 3), E);
end

bode(sys{:}, {2*pi*0.0001 2*pi*10})
grid on
legend('v= 12', 'v= 13', 'v= 14', 'v= 15', 'v= 20', 'Location', 'southwest')
title('Frequency response pitch to speed')