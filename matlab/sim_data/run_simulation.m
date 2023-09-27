function [d_out, cpu_time, int_err, n_steps, n_backsteps, n_sub_steps, Q, R, x_end_est]= run_simulation(model, d_in, param, opt, step_predict, do_est, Q, R, N, x_est0_)

sys_mex= str2func([model '_mex']);
get_ekf_config= str2func([model '_ekf_config']);
ekf_mex= str2func([model '_ekf_mex']);

if ~exist('step_predict', 'var') || isempty(step_predict)
    step_predict= 0;
end
if ~exist('do_est', 'var')
    do_est= 0;
end
if ~exist('N', 'var')
    N= [];
end
if ~exist('opts', 'var') || isempty(opt)
    % standard
    % opts= struct('StepTol', 1e-8, 'AbsTol', 1e-6, 'RelTol', 1e-6, 'hminmin', 1E-8, 'jac_recalc_step', 4, 'max_steps', 10);
    % one step
    opts= struct('StepTol', 1e6, 'AbsTol', 1e6, 'RelTol', 1e6, 'hminmin', 1E-8, 'jac_recalc_step', 10, 'max_steps', 1);
end

model_indices

t= d_in.Time;
dt= t(2)-t(1);
param.ts= dt;
nt= length(t);

if ~isfield(param, 'Tadapt') || isempty(param.Tadapt)
    param.Tadapt= -1;
end
if ~isfield(param, 'adaptScale') || isempty(param.adaptScale)
    param.adaptScale= ones(1, ny);
end

[x_ref, u, y_meas, x0_est]= convertFAST_CADyn(d_in, param, do_est | step_predict);
q= x_ref(1:nq, :);
dq= x_ref(nq+1:end, :);
ddq= zeros(size(q));
if exist('x0_est_', 'var') && ~isempty(x0_est_)
    x0_est= x0_est_;
end

if do_est
    q(:, 1)= x0_est(1:nq);
    dq(:, 1)= x0_est((nq+1):end);
    ekf_config= get_ekf_config();
    if ~isfield(param, 'adaptUpdate') || isempty(param.adaptUpdate)
        param.adaptUpdate= ones(length(ekf_config.estimated_states), 1);
    end
    u_offset= 1;
else
    u_offset= 0;
end

cpu_time= zeros(1, nt);
int_err= zeros(1, nt);
n_steps= zeros(1, nt);
n_backsteps= zeros(1, nt);
n_sub_steps= zeros(1, nt);

y_pred= zeros(ny, nt);
Sigma_est= [];

tic
if do_est<2
    for i= 2:nt
        if step_predict
            q_in= x_ref(1:nq, i-1);
            dq_in= x_ref(nq+1:end, i-1);
        else
            q_in= q(:, i-1);
            dq_in= dq(:, i-1);
        end
        [q(:, i), dq(:, i), ddq(:, i), y_pred(:, i), AB, CD, res, cpu_time(i), int_err(i), n_steps(i), n_backsteps(i), n_sub_steps(i)]= ...
            sys_mex(q_in, dq_in, u(:, i-u_offset), param, t(i)-t(i-1), opts);
    
        if ~res
            break
        end
    
        if do_est
            [q(:, i), dq(:, i), Sigma_est, Q, R]= ...
                EKF_autotuning(q(:, i), dq(:, i), y_pred(:, i), y_meas(:, i), param, ekf_config, Sigma_est, AB, CD, Q, R, N, t(i));
        end
    end
else
    [q, dq, ~, y_pred, Q, R, cpu_time]= ekf_mex(q(:, 1), dq(:, 1), u, y_meas, param, dt, ekf_config.x_ul, ekf_config.x_ll, Q, R, param.Tadapt, param.adaptScale, param.adaptUpdate, opts);    
end
toc
y_pred(:, 1)= y_pred(:, 2);

if step_predict
    d_out.x= x_ref;
    d_out.x_pred= [q; dq];
    d_out.y= y_meas;
    d_out.y_pred= y_pred;    
else
    d_out= convertFAST_CADyn(t, q, dq, ddq, u, y_pred, param);
    x_end_est= [q(:, end); dq(:, end)];
end