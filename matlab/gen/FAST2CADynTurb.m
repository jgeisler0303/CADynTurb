function [param, data, tw_sid, bd_sid]= FAST2CADynTurb(fst_file, tower_modes, blade_modes)
if ~exist('tower_modes', 'var')
    tower_modes= {[1 2]};
end
if ~exist('blade_modes', 'var')
    blade_modes= [1 2];
end

[fst_dir, fname]= fileparts(fst_file);
base_path= fullfile(fst_dir, fname);

param= [];

%%
fstDataOut = FAST2Matlab(fst_file);

EDFile= strrep(GetFASTPar(fstDataOut, 'EDFile'), '"', '');
edDataOut = FAST2Matlab(fullfile(fst_dir, EDFile));
EDTwrFile= strrep(GetFASTPar(edDataOut, 'TwrFile'), '"', '');

edtwrDataOut = FAST2Matlab(fullfile(fst_dir, EDTwrFile));

Rz= edtwrDataOut.TowProp(:, find(strcmp(edtwrDataOut.TowPropHdr, 'HtFract'))) * GetFASTPar(edDataOut, 'TowerHt');
mu= edtwrDataOut.TowProp(:, find(strcmp(edtwrDataOut.TowPropHdr, 'TMassDen')));
EIy= edtwrDataOut.TowProp(:, find(strcmp(edtwrDataOut.TowPropHdr, 'TwFAStif')));
EIz= edtwrDataOut.TowProp(:, find(strcmp(edtwrDataOut.TowPropHdr, 'TwSSStif')));

data= [];
n= length(Rz);
for i= 1:n
    data(i).Rz= Rz(i);
    data(i).mu= mu(i);
    data(i).EIy= EIy(i);
    data(i).EIz= EIz(i);
    data(i).node_interpolation= 'linear';
end

%%
tw_sid= FEMBeam2SID(data, 1, tower_modes, 1);
% TODO: allow more than 2 tower modes
if size(tw_sid.Ke.M0, 1)==2
    tw_sid.De.M0= diag(2*sqrt(tw_sid.Me.M0*tw_sid.Ke.M0)) .* [GetFASTPar(edtwrDataOut, 'TwrFADmp(1)') GetFASTPar(edtwrDataOut, 'TwrSSDmp(1)')]/100;
else
    tw_sid.De.M0= diag(2*sqrt(tw_sid.Me.M0*tw_sid.Ke.M0)) .* [GetFASTPar(edtwrDataOut, 'TwrFADmp(1)')]/100;
end
tw_sid.De.structure= 1;

%  write_sid_maxima(tw_sid, [base_path '_tw_sid'], 'tower', length(tw_sid.frame), 1e-5, 1)

tname= [tempname '.m'];
write_sid_maxima(tw_sid, tname, 'tower', length(tw_sid.frame), 1e-5, 2);
param= load2struct(tname, param);
delete(tname)

%%
EDBldFile= strrep(GetFASTPar(edDataOut, 'BldFile(1)'), '"', '');
edbldDataOut = FAST2Matlab(fullfile(fst_dir, EDBldFile));

BldLen= GetFASTPar(edDataOut, 'TipRad') - GetFASTPar(edDataOut, 'HubRad');
Rz= edbldDataOut.BldProp(:, find(strcmp(edbldDataOut.BldPropHdr, 'BlFract'))) * BldLen + GetFASTPar(edDataOut, 'HubRad');
mu= edbldDataOut.BldProp(:, find(strcmp(edbldDataOut.BldPropHdr, 'BMassDen')));
EIy= edbldDataOut.BldProp(:, find(strcmp(edbldDataOut.BldPropHdr, 'FlpStff')));
EIz= edbldDataOut.BldProp(:, find(strcmp(edbldDataOut.BldPropHdr, 'EdgStff')));
phi_abs= -edbldDataOut.BldProp(:, find(strcmp(edbldDataOut.BldPropHdr, 'StrcTwst')))/180*pi;
phi= [phi_abs(1); diff(phi_abs(:))]; 

data= [];
n= length(Rz);
for i= 1:n
    data(i).Rz= Rz(i);
    data(i).mu= mu(i);
    data(i).EIy= EIy(i);
    data(i).EIz= EIz(i);
    data(i).phi= phi(i);
    data(i).node_interpolation= 'linear';
end

%%
bd_sid= FEMBeam2SID(data, 1, blade_modes, 1);
% TODO: allow more than 2 blade modes
if size(bd_sid.Ke.M0, 1)==2
    bd_sid.De.M0= 2*real(sqrt(bd_sid.Me.M0*bd_sid.Ke.M0)) * diag([GetFASTPar(edbldDataOut, 'BldFlDmp(1)') GetFASTPar(edbldDataOut, 'BldEdDmp(1)')])/100;
else
    bd_sid.De.M0= 2*real(sqrt(bd_sid.Me.M0*bd_sid.Ke.M0)) * diag([GetFASTPar(edbldDataOut, 'BldFlDmp(1)')])/100;
end
bd_sid.De.structure= 2;

%  write_sid_maxima(bd_sid, [base_path '_bd_sid'], 'tower', [], 1e-5, 1)
tname= [tempname '.m'];
write_sid_maxima(bd_sid, tname, 'blade', 'last', 1e-5, 2);
param= load2struct(tname, param);
delete(tname)

%%
AeroFile= strrep(GetFASTPar(fstDataOut, 'AeroFile'), '"', '');
adDataOut = FAST2Matlab(fullfile(fst_dir, AeroFile));

ADBldFile= strrep(GetFASTPar(adDataOut, 'ADBlFile(1)'), '"', '');
adbldDataOut = FAST2Matlab(fullfile(fst_dir, ADBldFile));

data= [];
data.R= adbldDataOut.BldNodes(:, find(strcmp(adbldDataOut.BldNodesHdr, 'BlSpn'))) + GetFASTPar(edDataOut, 'HubRad');
data.chord= adbldDataOut.BldNodes(:, find(strcmp(adbldDataOut.BldNodesHdr, 'BlChord')));
data.twist= adbldDataOut.BldNodes(:, find(strcmp(adbldDataOut.BldNodesHdr, 'BlTwist')))/180*pi;
data.airfoil_idx= adbldDataOut.BldNodes(:, find(strcmp(adbldDataOut.BldNodesHdr, 'BlAFID')));
data.rho= GetFASTPar(adDataOut, 'AirDens');
data.TipLoss= double(strcmpi(GetFASTPar(adDataOut, 'TipLoss'), 'true'));
data.HubLoss= double(strcmpi(GetFASTPar(adDataOut, 'HubLoss'), 'true'));
data.TanInd= double(strcmpi(GetFASTPar(adDataOut, 'TanInd'), 'true'));
data.AIDrag= double(strcmpi(GetFASTPar(adDataOut, 'AIDrag'), 'true'));
data.TIDrag= double(strcmpi(GetFASTPar(adDataOut, 'TIDrag'), 'true'));
data.SkewMod= GetFASTPar(adDataOut, 'SkewMod');
data.SkewModFactor= GetFASTPar(adDataOut, 'SkewModFactor');
data.AeroFile= AeroFile;
data.B= GetFASTPar(edDataOut, 'NumBl');
data.IndToler= GetFASTPar(adDataOut, 'IndToler');
if strcmpi(strrep(data.IndToler, '"', ''), 'default')
    data.IndToler= 1e-6;
end
data.acorr= 0.3;

idx_alpha= GetFASTPar(adDataOut, 'InCol_Alfa');
idx_cl= GetFASTPar(adDataOut, 'InCol_Cl');
idx_cd= GetFASTPar(adDataOut, 'InCol_Cd');
% idx_cm= GetFASTPar(adDataOut, 'InCol_Cm');
for i= 1:length(adDataOut.FoilNm)
    AirFoil= FAST2Matlab(fullfile(fst_dir, strrep(adDataOut.FoilNm{i}, '"', '')));
    data.AirFoil(i).alpha= AirFoil.AFCoeff(:, idx_alpha)/180*pi;
    data.AirFoil(i).cl= AirFoil.AFCoeff(:, idx_cl);
    data.AirFoil(i).cd= AirFoil.AFCoeff(:, idx_cd);
end

for i= 1:length(bd_sid.frame)
    R(i)= bd_sid.frame(i).origin.M0(3);
    for j= 1:size(bd_sid.frame(i).Phi.M0, 2)
        ModalShape{j}(:, i)= bd_sid.frame(i).Phi.M0(1:2, j);
    end
end
for j= 1:size(bd_sid.frame(i).Phi.M0, 2)
    data.ModalShapes{j}= interp1([-1 R 1000]', [ModalShape{j}(:, 1) ModalShape{j} ModalShape{j}(:, end)]', data.R);
end

AeroFields= calcAeroFields(data);
fields= fieldnames(AeroFields);
for i= 1:length(fields)
    param.(fields{i})= AeroFields.(fields{i});
end

%%
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
param.NacMass= GetFASTPar(edDataOut, 'NacMass');
param.NacXIner= 0;
param.NacYIner= GetFASTPar(edDataOut, 'NacYIner');
param.Rrot= GetFASTPar(edDataOut, 'TipRad');
param.Arot= pi*param.Rrot^2;
param.rho= GetFASTPar(adDataOut, 'AirDens');
param.g= GetFASTPar(edDataOut, 'Gravity');
param.TwTrans2Roll= tw_sid.frame(11).Psi.M0(2, 1);




