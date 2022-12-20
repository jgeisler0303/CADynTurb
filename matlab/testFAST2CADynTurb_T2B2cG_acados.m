%%
clc
set_path

% base dir doesn't work when run assection, but is returne by set_path
% base_dir= fileparts(mfilename('fullpath'));

model_name= 'turbine_T2B2cG_aero';
model_dir= fullfile(base_dir, '../sim/T2B2cG');

%%
[param, tw_sid, bd_sid]= make_model(model_name, model_dir, {[1 2]}, [1 2]);

%%
old_dir= pwd;
cleanupObj = onCleanup(@()cd(old_dir));
cd(model_dir)

%%
addpath(fullfile(getenv('ACADOS_INSTALL_DIR'), 'examples', 'acados_matlab_octave', 'getting_started'))
check_acados_requirements();
model= turbine_T2B2cG_aero_acados();
acados_sim_6DOF= make_acados_sim(model);

%%
d= sim_standalone(fullfile(model_dir, [model_name '_sim']), '../../5MW_Baseline/5MW_Land_IMP_12.fst', 'simp_12_6DOF.outb', '-a 0.965');

x_ref= [
    d.YawBrTDxp.Data'
    d.YawBrTDyp.Data'
    d.Q_BF1.Data'
    d.Q_BE1.Data'
    d.LSSTipPxa.Data'/180*pi
    d.Q_GeAz.Data'
    d.YawBrTVxp.Data'
    d.YawBrTVyp.Data'
    d.QD_BF1.Data'
    d.QD_BE1.Data'
    d.LSSTipVxa.Data'/30*pi
    d.HSShftV.Data'/30*pi
    ];

u_ref= [
    d.RtVAvgxh.Data'
    d.GenTq.Data'*1000
    d.BlPitchC.Data'/(-180)*pi
    ];

%%
model_parameters
ap= acados_params(parameter_names, param);
acados_sim_6DOF.set('p', ap);
acados_sim_6DOF.set('T', d.Time(2)-d.Time(1));

%% simulate system in loop
N_sim= length(d.Time);
x_sim = zeros(12, N_sim);
x_sim(:, 1)= x_ref(:, 1);

for ii= 2:N_sim
	acados_sim_6DOF.set('x', x_sim(:, ii-1));
	acados_sim_6DOF.set('u', u_ref(:, ii-1));

    acados_sim_6DOF.set('xdot', zeros(12, 1));
	acados_sim_6DOF.solve();

	% get simulated state
	x_sim(:, ii) = acados_sim_6DOF.get('xn');
    
    % forward sensitivities ( dxn_d[x0,u] )
    % S_forw = sim.get('S_forw');
end

%%
d_sim= tscollection();
d_sim.Name= 'acados_sim';

ts= timeseries('YawBrTDxp');
ts.Time= d.Time;
ts.Data= x_sim(1, :)';
ts.DataInfo.Units= 'm';
ts.TimeInfo.Units= 's';
d_sim= d_sim.addts(ts);

ts= timeseries('YawBrTDyp');
ts.Time= d.Time;
ts.Data= x_sim(2, :)';
ts.DataInfo.Units= 'm';
ts.TimeInfo.Units= 's';
d_sim= d_sim.addts(ts);

ts= timeseries('Q_BF1');
ts.Time= d.Time;
ts.Data= x_sim(3, :)';
ts.DataInfo.Units= 'm';
ts.TimeInfo.Units= 's';
d_sim= d_sim.addts(ts);

ts= timeseries('Q_BE1');
ts.Time= d.Time;
ts.Data= x_sim(4, :)';
ts.DataInfo.Units= 'm';
ts.TimeInfo.Units= 's';
d_sim= d_sim.addts(ts);

ts= timeseries('LSSTipPxa');
ts.Time= d.Time;
ts.Data= x_sim(5, :)'/pi*180;
ts.DataInfo.Units= 'deg';
ts.TimeInfo.Units= 's';
d_sim= d_sim.addts(ts);

ts= timeseries('Q_GeAz');
ts.Time= d.Time;
ts.Data= x_sim(6, :)';
ts.DataInfo.Units= 'rad';
ts.TimeInfo.Units= 's';
d_sim= d_sim.addts(ts);

ts= timeseries('YawBrTVxp');
ts.Time= d.Time;
ts.Data= x_sim(7, :)';
ts.DataInfo.Units= 'm/s';
ts.TimeInfo.Units= 's';
d_sim= d_sim.addts(ts);

ts= timeseries('YawBrTVyp');
ts.Time= d.Time;
ts.Data= x_sim(8, :)';
ts.DataInfo.Units= 'm/s';
ts.TimeInfo.Units= 's';
d_sim= d_sim.addts(ts);

ts= timeseries('QD_BF1');
ts.Time= d.Time;
ts.Data= x_sim(9, :)';
ts.DataInfo.Units= 'm/s';
ts.TimeInfo.Units= 's';
d_sim= d_sim.addts(ts);

ts= timeseries('QD_BE1');
ts.Time= d.Time;
ts.Data= x_sim(10, :)';
ts.DataInfo.Units= 'm/s';
ts.TimeInfo.Units= 's';
d_sim= d_sim.addts(ts);

ts= timeseries('LSSTipVxa');
ts.Time= d.Time;
ts.Data= x_sim(11, :)'/pi*30;
ts.DataInfo.Units= 'rpm';
ts.TimeInfo.Units= 's';
d_sim= d_sim.addts(ts);

ts= timeseries('HSShftV');
ts.Time= d.Time;
ts.Data= x_sim(12, :)'/pi*30;
ts.DataInfo.Units= 'rpm';
ts.TimeInfo.Units= 's';
d_sim= d_sim.addts(ts);

%%
plot_timeseries_cmp(d, d_sim, {'RtVAvgxh', 'PtchPMzc', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'});

%%
sim_generate_c_code(acados_sim_6DOF)

%%
if ispc
    system('g++ -fpermissive -g -std=c++17 -D _USE_MATH_DEFINES -I. -I../../simulator -Ic_generated_code -I$ACADOS_INSTALL_DIR/include -I$ACADOS_INSTALL_DIR/include/blasfeo/include -I$ACADOS_INSTALL_DIR/include/hpipm/include ../../simulator/turbine_T2B2cG_aero_acados.cpp c_generated_code/acados_sim_solver_T2B2cG_aero.c c_generated_code/T2B2cG_aero_model/T2B2cG_aero_impl_dae_fun_jac_x_xdot_u.c c_generated_code/T2B2cG_aero_model/T2B2cG_aero_impl_dae_fun_jac_x_xdot_z.c c_generated_code/T2B2cG_aero_model/T2B2cG_aero_impl_dae_fun.c c_generated_code/T2B2cG_aero_model/T2B2cG_aero_impl_dae_hess.c c_generated_code/T2B2cG_aero_model/T2B2cG_aero_impl_dae_jac_x_xdot_u_z.c -L$ACADOS_INSTALL_DIR/lib -lacados -lblasfeo -lhpipm -o turbine_T2B2cG_aero_acados');
else
    system('g++ -fpermissive -g -std=c++17 -I. -I../../simulator -Ic_generated_code -I$ACADOS_INSTALL_DIR/include -I$ACADOS_INSTALL_DIR/include/blasfeo/include -I$ACADOS_INSTALL_DIR/include/hpipm/include ../../simulator/turbine_T2B2cG_aero_acados.cpp c_generated_code/acados_sim_solver_T2B2cG_aero.c c_generated_code/T2B2cG_aero_model/T2B2cG_aero_impl_dae_fun_jac_x_xdot_u.c c_generated_code/T2B2cG_aero_model/T2B2cG_aero_impl_dae_fun_jac_x_xdot_z.c c_generated_code/T2B2cG_aero_model/T2B2cG_aero_impl_dae_fun.c c_generated_code/T2B2cG_aero_model/T2B2cG_aero_impl_dae_hess.c c_generated_code/T2B2cG_aero_model/T2B2cG_aero_impl_dae_jac_x_xdot_u_z.c -L$ACADOS_INSTALL_DIR/lib -ldl -lacados -lblasfeo -lhpipm -o turbine_T2B2cG_aero_acados');
end

%%
sim_command= 'turbine_T2B2cG_aero_acados -a 0.965 -o simp_12_6DOF_acados.outb ../../5MW_Baseline/5MW_Land_IMP_12.fst';
if isunix
    system(['LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 ./' sim_command])
else
    system(['set path=' getenv('PATH') ' & ' sim_command])
end

%%
d_a= loadFAST('simp_12_6DOF_acados.outb');
figure
plot_timeseries_cmp(d, d_a, {'RtVAvgxh', 'PtchPMzc', 'HSShftV', 'GenTq', 'YawBrTDxp', 'YawBrTDyp', 'Q_BF1', 'Q_BE1'});