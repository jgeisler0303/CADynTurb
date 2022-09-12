function param= writeModelParams(param, target_dir)

param= addFieldAlias(param, 'cf_lut', 'cb1');
param= addFieldAlias(param, 'ce_lut', 'cb2');
param= addFieldAlias(param, 'ct_lut', 'ct');
param= addFieldAlias(param, 'cm_lut', 'cm');
param= addFieldAlias(param, 'cmy_D23_lut', 'cmy_D23');
param= addFieldAlias(param, 'dcm_dvf_v_lut', 'dcm_dvb1_v');
param= addFieldAlias(param, 'dct_dvf_v_lut', 'dct_dvb1_v');
param.dcs_dvy_v_lut= sum(param.dcsi_dvy_v, 3)';
param= addFieldAlias(param, 'dcf_dvf_v_lut', 'dcb1_dvb1_v');
param= addFieldAlias(param, 'dce_dvf_v_lut', 'dcb2_dvb1_v');
param= addFieldAlias(param, 'dcmy_D23_dvf_v_lut', 'dcmy_D23_dvb1_v');
param= addFieldAlias(param, 'dcm_dve_v_lut', 'dcm_dvb2_v');
param= addFieldAlias(param, 'dct_dve_v_lut', 'dct_dvb2_v');
param= addFieldAlias(param, 'dcf_dve_v_lut', 'dcb1_dvb2_v');
param= addFieldAlias(param, 'dce_dve_v_lut', 'dcb2_dvb2_v');
param= addFieldAlias(param, 'dcmy_D23_dve_v_lut', 'dcmy_D23_dvb2_v');
param= addFieldAlias(param, 'dcm_dkappa_v_lut', 'dcm_dkappa_v');
param= addFieldAlias(param, 'dct_dkappa_v_lut', 'dct_dkappa_v');
param= addFieldAlias(param, 'dcf_dkappa_v_lut', 'dcb1_dkappa_v');
param= addFieldAlias(param, 'dce_dkappa_v_lut', 'dcb2_dkappa_v');
param= addFieldAlias(param, 'dcmy_D23_dkappa_v_lut', 'dcmy_D23_dkappa_v');

param.lambdaMin= param.lambda(1);
param.lambdaMax= param.lambda(end);
param.lambdaStep= mean(diff(param.lambda));

param.thetaMin= param.theta(1);
param.thetaMax= param.theta(end);
param.thetaStep= mean(diff(param.theta));

param.T_wind_filt= 20;
param.D_wind_filt= 1/sqrt(2);

% param.torqueForceRadius= param.bd_sid.frame(20).origin.M0(3);
param.torqueForceRadius= param.R(end)*2/3;

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

save(fullfile(target_dir, 'params_config.mat'), 'p_');
save(fullfile(target_dir, 'params.mat'), 'param');


function p= addFieldAlias(p, alias, name)
if isfield(p, name)
    p.(alias)= p.(name)';
end