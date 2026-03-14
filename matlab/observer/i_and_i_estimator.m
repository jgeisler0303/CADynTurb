function d = i_and_i_estimator(d, param, WE_Gamma)
% implemented directly from the source code of ROSCO:
% https://github.com/NatLabRockies/ROSCO/blob/122c75864c1c0c1a828975180f46e77220771e60/rosco/controller/src/ControllerBlocks.f90#L263
% Following "A globally convergent wind speed estimator for wind turbine
% systems",  https://doi.org/10.1002/acs.2319

DT = diff(d.Time(1:2));
RotSpeedF = d.LSSTipVxa.Data/30*pi;
BlPitchCMeas = d.BlPitchC.Data;
VS_LastGenTrq = d.GenTq.Data*1000;
WE_Jtot = 3.0*(param.blade_I0_1_1 + param.blade_md0_3_1^2/param.blade_mass) + param.HubIner + param.GBRatio^2*param.GenIner;
WE_GearboxRatio = param.GBRatio;

WE_Vw = zeros(size(RotSpeedF));
WE_Vw(1) = d.Wind1VelX.Data(1);
WE_VwI = WE_Vw;
WE_VwI(1) = WE_VwI(1) - WE_Gamma*RotSpeedF(1);
for i = 2:length(RotSpeedF)
    Tau_r = AeroDynTorque(RotSpeedF(i-1), BlPitchCMeas(i-1), WE_Vw(i-1), param);

    WE_VwIdot = WE_Gamma/WE_Jtot*(VS_LastGenTrq(i-1)*WE_GearboxRatio - Tau_r);
    WE_VwI(i) = WE_VwI(i-1) + WE_VwIdot*DT;
    WE_Vw(i) = WE_VwI(i) + WE_Gamma*RotSpeedF(i);
end

try
    d.RAWS.Data = WE_Vw;
catch
    RAWS= timeseries('RAWS');
    RAWS.Time= d.Time;
    RAWS.Data= WE_Vw;
    RAWS.DataInfo.Units= 'm/s';
    RAWS.TimeInfo.Units= 's';
    d= d.addts(RAWS);
end

end

function AeroDynTorque = AeroDynTorque(RotSpeed, BldPitch, WE_Vw, param)
RotorArea = param.Arot;
WE_BladeRadius = param.Rrot;
WE_RhoAir = param.rho;
Lambda = RotSpeed*WE_BladeRadius/WE_Vw;

Cp = interp2(param.theta, param.lambda, param.cp', BldPitch, Lambda);

AeroDynTorque = 0.5*(WE_RhoAir*RotorArea)*(WE_Vw^3/RotSpeed)*Cp;
AeroDynTorque = max(AeroDynTorque, 0);
end