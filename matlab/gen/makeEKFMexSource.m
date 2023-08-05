function makeEKFMexSource(model_name)

get_ekf_config= str2func([model_name '_ekf_config']);

ekf_config= get_ekf_config();
model_indices


fid= fopen([model_name '_ekf_mex.cpp'], 'w');

fprintf(fid, '#include "%s_direct.hpp"\n', model_name);
fprintf(fid, '#define SYSTEM %s\n', model_name);
fprintf(fid, '\n');
fprintf(fid, 'const int estimated_q[]= {\n');
for i= 1:ekf_config.n_estimated_dofs
    fprintf(fid, '    %s::states_idx.%s', model_name, dof_names{ekf_config.estimated_states(i)});
    if i<ekf_config.n_estimated_dofs
        fprintf(fid, ',\n');
    else
        fprintf(fid, '\n');
    end
end
fprintf(fid, '};\n');
fprintf(fid, 'const int estimated_dq[]= {\n');
for i= ekf_config.n_estimated_dofs+1:length(ekf_config.estimated_states)
    fprintf(fid, '    %s::states_idx.%s', model_name, dof_names{ekf_config.estimated_states(i)-nq});
    if i<length(ekf_config.estimated_states)
        fprintf(fid, ',\n');
    else
        fprintf(fid, '\n');
    end
end
fprintf(fid, '};\n');
fprintf(fid, '\n');
fprintf(fid, '#define EKF_STATES %d\n', length(ekf_config.estimated_states));
fprintf(fid, '\n');
fprintf(fid, '#include "CADynEKF_mex.hpp"\n');

fclose(fid);