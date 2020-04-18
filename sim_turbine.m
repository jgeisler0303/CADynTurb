%%
x0= [0.1 0.01 0 1 0.01 0]';
dx0= [0 0 2 0 0 2.001]';
u= [10 16000 2];

ts= 0.01;
t= 0:ts:10;
nt= length(t);

%%
x= zeros(length(x0), nt);
dx= zeros(length(x0), nt);
x(:, 1)= x0;
dx(:, 1)= dx0;
cpu_time= zeros(1, nt);
int_err= zeros(1, nt);
n_steps= zeros(1, nt);
n_backsteps= zeros(1, nt);

for i= 2:nt
    [x(:, i), dx(:, i), ~, ~, ~, cpu_time(i), int_err(i), n_steps(i), n_backsteps(i)]= turbine_coll_flap_edge_pitch_aero_mex(x(:, i-1), dx(:, i-1), u, param, ts, struct('StepTol', 1e-1, 'AbsTol', 1e-4, 'RelTol', 1e-4));
end
