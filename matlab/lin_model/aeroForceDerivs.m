function [dX_dqd1, dX_dqd3, dX_dqd4, dX_dqd5, dX_dvwind, dX_dtheta]= aeroForceDerivs(cx_stat, dcx_dlam, dcx_dtheta, dcx_dvf_v, dcx_dve_v, dlam_dvw, dlam_dvtow, dlam_domrot, Fwind, Fwind_v, dFwind_dvtow, dFwind_dvw)

dcx_dvw= dcx_dlam * dlam_dvw;
dcx_dvtow= dcx_dlam * dlam_dvtow;
dcx_domrot= dcx_dlam * dlam_domrot;

dX_dqd1= dFwind_dvtow*cx_stat + Fwind*dcx_dvtow;    % TODO to be exact, the derivative of the edge and flap terms is missing here 
dX_dqd3= Fwind*dcx_domrot;                          % TODO to be exact, the derivative of the edge and flap terms is missing here 
dX_dqd4= Fwind_v * dcx_dvf_v;
dX_dqd5= Fwind_v * dcx_dve_v;
dX_dvwind= dFwind_dvw*cx_stat + Fwind*dcx_dvw;      % TODO to be exact, the derivative of the edge and flap terms is missing here 
dX_dtheta= Fwind*dcx_dtheta;                        % TODO to be exact, the derivative of the edge and flap terms is missing here 

