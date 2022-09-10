function [param, data, tw_sid]= FAST2CADynTurb2(fst_file, tower_modes, blade_modes)
if ~exist('tower_modes', 'var')
    tower_modes= {[1 2]};
end
if ~exist('blade_modes', 'var')
    blade_modes= [1 2];
end

fst_dir= fileparts(fst_file);
% base_path= fullfile(fst_dir, fname);

param= [];

%% tower model and blade model
param= FAST2SID_direct(param, fst_file);

%% aerodynamic model
data= loadAeroData(fst_file);

for j= 1:length(param.ModalShapes)
    data.ModalShapes{j}= interp1(param.R, param.ModalShapes{j}, data.R);
end

AeroFields= aerodynAeroQSFieldmodal(fst_file, data, 1:0.5:13, 0:0.5:45);

fields= fieldnames(AeroFields);
for i= 1:length(fields)
    param.(fields{i})= AeroFields.(fields{i});
end

%% general parameters
fstDataOut = FAST2Matlab(fst_file);

EDFile= strrep(GetFASTPar(fstDataOut, 'EDFile'), '"', '');
edDataOut = FAST2Matlab(fullfile(fst_dir, EDFile));

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
param.cone= GetFASTPar(edDataOut, 'PreCone(1)')/180*pi;
param.tilt= GetFASTPar(edDataOut, 'ShftTilt')/180*pi;
param.Twr2Shft= GetFASTPar(edDataOut, 'Twr2Shft');
param.NacMass= GetFASTPar(edDataOut, 'NacMass');
param.NacXIner= 0;
param.NacYIner= GetFASTPar(edDataOut, 'NacYIner');
param.Rrot= GetFASTPar(edDataOut, 'TipRad');
param.Arot= pi*param.Rrot^2;
param.rho= data.rho;
param.g= GetFASTPar(edDataOut, 'Gravity');
param.TwTrans2Roll= param.tower_frame_11_psi0_2_1;




