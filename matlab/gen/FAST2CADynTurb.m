function [param, data, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, tower_modes, blade_modes)
if ~exist('tower_modes', 'var')
    tower_modes= {[1 2]};
end
if ~exist('blade_modes', 'var')
    blade_modes= [1 2];
end

fst_dir= fileparts(fst_file);
% base_path= fullfile(fst_dir, fname);

param= [];

%% tower model
fstDataOut = FAST2Matlab(fst_file);

EDFile= strrep(GetFASTPar(fstDataOut, 'EDFile'), '"', '');
edDataOut = FAST2Matlab(fullfile(fst_dir, EDFile));
EDTwrFile= strrep(GetFASTPar(edDataOut, 'TwrFile'), '"', '');

edtwrDataOut = FAST2Matlab(fullfile(fst_dir, EDTwrFile));


Rz= getFASTTableColumn(edtwrDataOut.TowProp, 'HtFract') * GetFASTPar(edDataOut, 'TowerHt');
mu= getFASTTableColumn(edtwrDataOut.TowProp, 'TMassDen');
EIy= getFASTTableColumn(edtwrDataOut.TowProp, 'TwFAStif');
EIz= getFASTTableColumn(edtwrDataOut.TowProp, 'TwSSStif');

data= struct([]);
n= length(Rz);
for i= 1:n
    data(i).Rz= Rz(i);
    data(i).mu= mu(i);
    data(i).EIy= EIy(i);
    data(i).EIz= EIz(i);
    data(i).node_interpolation= 'linear';
end

tw_sid= FEMBeam2SID(data, 1, tower_modes, 1);
% TODO: allow more than 2 tower modes
if size(tw_sid.Ke.M0, 1)==2
    tw_sid.De.M0= diag(2*sqrt(diag(tw_sid.Me.M0*tw_sid.Ke.M0)) .* [GetFASTPar(edtwrDataOut, 'TwrFADmp(1)') GetFASTPar(edtwrDataOut, 'TwrSSDmp(1)')]'/100);
else
    tw_sid.De.M0= 2*sqrt(tw_sid.Me.M0*tw_sid.Ke.M0) .* GetFASTPar(edtwrDataOut, 'TwrFADmp(1)')/100;
end
tw_sid.De.structure= 1;

%  write_sid_maxima(tw_sid, [base_path '_tw_sid'], 'tower', length(tw_sid.frame), 1e-5, 1)

tname= [tempname '.m'];
write_sid_maxima(tw_sid, tname, 'tower', 'last', 1e-5, 2);
param= load2struct(tname, param);
param.num_tower_frames= length(tw_sid.frame);
delete(tname)

%% blade model
EDBldFile= strrep(GetFASTPar(edDataOut, 'BldFile(1)'), '"', '');
edbldDataOut = FAST2Matlab(fullfile(fst_dir, EDBldFile));

BldLen= GetFASTPar(edDataOut, 'TipRad') - GetFASTPar(edDataOut, 'HubRad');
Rz= getFASTTableColumn(edbldDataOut.BldProp, 'BlFract') * BldLen + GetFASTPar(edDataOut, 'HubRad');
mu= getFASTTableColumn(edbldDataOut.BldProp, 'BMassDen');
EIy= getFASTTableColumn(edbldDataOut.BldProp, 'FlpStff');
EIz= getFASTTableColumn(edbldDataOut.BldProp, 'EdgStff');
phi_abs= -getFASTTableColumn(edbldDataOut.BldProp, 'StrcTwst')/180*pi;
phi= 1.3*[phi_abs(1); diff(phi_abs(:))]; % TODO: dirty hack to get 3D mode shapes right

data= struct([]);
n= length(Rz);
for i= 1:n
    data(i).Rz= Rz(i);
    data(i).mu= mu(i);
    data(i).EIy= EIy(i);
    data(i).EIz= EIz(i);
    data(i).phi= phi(i);
    data(i).node_interpolation= 'linear';
end

bd_sid= FEMBeam2SID(data, 1, blade_modes, 1);
% TODO: allow more than 2 blade modes
if size(bd_sid.Ke.M0, 1)==2
    bd_sid.De.M0= 2*real(sqrt(bd_sid.Me.M0*bd_sid.Ke.M0)) * diag([GetFASTPar(edbldDataOut, 'BldFlDmp(1)') GetFASTPar(edbldDataOut, 'BldEdDmp(1)')])/100;
else
    bd_sid.De.M0= 2*real(sqrt(bd_sid.Me.M0*bd_sid.Ke.M0)) * diag(GetFASTPar(edbldDataOut, 'BldFlDmp(1)'))/100;
end
bd_sid.De.structure= 2;

tname= [tempname '.m'];
write_sid_maxima(bd_sid, tname, 'blade', 'all', 1e-5, 2);
param= load2struct(tname, param);
param.num_blade_frames= length(bd_sid.frame);
delete(tname)

%% aerodynamic model
data= loadAeroData(fst_file);

R= zeros(1, length(bd_sid.frame));
ModalShape= cell(size(bd_sid.frame(i).Phi.M0, 2), 1);
for i= 1:length(bd_sid.frame)
    R(i)= bd_sid.frame(i).origin.M0(3);
    for j= 1:size(bd_sid.frame(i).Phi.M0, 2)
        ModalShape{j}(:, i)= bd_sid.frame(i).Phi.M0(1:2, j);
    end
end
for j= 1:size(bd_sid.frame(i).Phi.M0, 2)
    data.ModalShapes{j}= interp1([-1 R 1000]', [ModalShape{j}(:, 1) ModalShape{j} ModalShape{j}(:, end)]', data.R);
end

AeroFields= aerodynAeroQSFieldmodal(fst_file, data, 1:0.5:13, 0:0.5:45);

fields= fieldnames(AeroFields);
for i= 1:length(fields)
    param.(fields{i})= AeroFields.(fields{i});
end

%% general parameters
param.DTTorDmp= GetFASTPar(edDataOut, 'DTTorDmp');
param.DTTorSpr= GetFASTPar(edDataOut, 'DTTorSpr');
param.GBRatio= GetFASTPar(edDataOut, 'GBRatio');
param.GenIner= GetFASTPar(edDataOut, 'GenIner');
param.HubIner= GetFASTPar(edDataOut, 'HubIner');
param.HubMass= GetFASTPar(edDataOut, 'HubMass');
param.HubCM= GetFASTPar(edDataOut, 'HubCM');
param.NacCMxn= GetFASTPar(edDataOut, 'NacCMxn');
param.NacCMyn= GetFASTPar(edDataOut, 'NacCMyn');
param.NacCMzn= GetFASTPar(edDataOut, 'NacCMzn');
param.OverHang= GetFASTPar(edDataOut, 'OverHang');
param.Twr2Shft= GetFASTPar(edDataOut, 'Twr2Shft');
param.cone= GetFASTPar(edDataOut, 'PreCone(1)')/180*pi;
param.tilt= -GetFASTPar(edDataOut, 'ShftTilt')/180*pi;
param.NacMass= GetFASTPar(edDataOut, 'NacMass');
param.NacXIner= 0;
param.NacYIner= GetFASTPar(edDataOut, 'NacYIner');
param.Rrot= GetFASTPar(edDataOut, 'TipRad');
param.Arot= pi*param.Rrot^2;
param.rho= data.rho;
param.g= GetFASTPar(fstDataOut, 'Gravity');

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

param.Tm_avg= 30;

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

function p= addFieldAlias(p, alias, name)
if isfield(p, name)
    p.(alias)= p.(name)';
end


