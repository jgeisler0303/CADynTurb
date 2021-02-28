function param= writeModelParams(param, target_dir)

param.cf_lut= param.cb1';
param.ce_lut= param.cb2';
param.ct_lut= param.ct';
param.cm_lut= param.cm';
param.dcm_dvf_v_lut= param.dcm_dvb1_v';
param.dct_dvf_v_lut= param.dct_dvb1_v';
param.dcs_dvy_v_lut= sum(param.dcsi_dvy_v, 3)';
param.dcf_dvf_v_lut= param.dcb1_dvb1_v';
param.dce_dvf_v_lut= param.dcb2_dvb1_v';
param.dcm_dve_v_lut= param.dcm_dvb2_v';
param.dct_dve_v_lut= param.dct_dvb2_v';
param.dcf_dve_v_lut= param.dcb1_dvb2_v';
param.dce_dve_v_lut= param.dcb2_dvb2_v';
param.lambdaMin= param.lambda(1);
param.lambdaMax= param.lambda(end);
param.lambdaStep= mean(diff(param.lambda));

param.thetaMin= param.theta(1);
param.thetaMax= param.theta(end);
param.thetaStep= mean(diff(param.theta));
param.T_wind_filt= 20;
param.D_wind_filt= 1/sqrt(2);


run(fullfile(target_dir, 'model_parameters.m'))

fid= fopen(fullfile(target_dir, 'params.txt'), 'w');
for i= 1:length(parameter_names)
    if ~isnumeric(param.(parameter_names{i})), continue; end
    fprintf(fid, '%s ', parameter_names{i});
    for row= 1:size(param.(parameter_names{i}), 1)
        for col= 1:size(param.(parameter_names{i}), 2)
            fprintf(fid, '%.16e ', param.(parameter_names{i})(row, col));
        end
        fprintf(fid, '\n');
    end
    p_.(parameter_names{i})= param.(parameter_names{i});
end
fclose(fid);

% param= p_;
save(fullfile(target_dir, 'params.mat'), 'param');
