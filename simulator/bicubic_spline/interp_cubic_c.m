function cp_out= interp_cubic_c(lam, theta_deg, lambdaMin, lambdaMax, thetaMin, thetaMax, lambdaStep, thetaStep, cp)

lam= min(max(lam, lambdaMin), lambdaMax*(1-eps));
theta_deg= min(max(theta_deg, thetaMin), thetaMax*(1-eps));

lambdaScaled= (lam-lambdaMin)/lambdaStep;
lambdaIdx= floor(lambdaScaled);
thetaScaled= (theta_deg-thetaMin)/thetaStep;
thetaIdx= floor(thetaScaled);
lambdaFact= 1- (lambdaScaled - lambdaIdx);
thetaFact= 1- (thetaScaled - thetaIdx);
% lambdaIdx= lambdaIdx-1;
% thetaIdx= thetaIdx-1;

coeffs_c = bicubic_kernel_coeffs(lambdaFact, thetaFact);
cc= zeros(4);

% c11
if thetaIdx<1
    if lambdaIdx<1
%         cc21= 3*cp(thetaIdx+1, lambdaIdx+1)-3*cp(thetaIdx+2, lambdaIdx+1)+cp(thetaIdx+3, lambdaIdx+1);
%         cc31= 3*cp(thetaIdx+1, lambdaIdx+2)-3*cp(thetaIdx+2, lambdaIdx+2)+cp(thetaIdx+3, lambdaIdx+2);
%         cc41= 3*cp(thetaIdx+1, lambdaIdx+3)-3*cp(thetaIdx+2, lambdaIdx+3)+cp(thetaIdx+3, lambdaIdx+3);
%         cc11= 3*cc21-3*cc31+cc41;
        cc(1, 1)= [3 -3 1]*cp((1:3)+thetaIdx, (1:3)+lambdaIdx)*[3 -3 1]';
    else
        cc(1, 1)= 3*cp(thetaIdx+1, lambdaIdx)-3*cp(thetaIdx+2, lambdaIdx)+cp(thetaIdx+3, lambdaIdx);
    end
else
    if lambdaIdx<1
        cc(1, 1)= 3*cp(thetaIdx, lambdaIdx+1)-3*cp(thetaIdx, lambdaIdx+2)+cp(thetaIdx, lambdaIdx+3);
    else
        cc(1, 1)= cp(thetaIdx, lambdaIdx);
    end
end
% c21
if thetaIdx<1
    cc(2, 1)= 3*cp(thetaIdx+1, lambdaIdx+1)-3*cp(thetaIdx+2, lambdaIdx+1)+cp(thetaIdx+3, lambdaIdx+1);
else
    cc(2, 1)= cp(thetaIdx, lambdaIdx+1);    
end
% c31
if thetaIdx<1
    cc(3, 1)= 3*cp(thetaIdx+1, lambdaIdx+2)-3*cp(thetaIdx+2, lambdaIdx+2)+cp(thetaIdx+3, lambdaIdx+2);
else
    cc(3, 1)= cp(thetaIdx, lambdaIdx+2);    
end
%c41
if thetaIdx<1
    if lambdaIdx+3>size(cp, 2)
        cc(4, 1)= [3 -3 1]*cp((1:3)+thetaIdx, (0:2)+lambdaIdx)*[1 -3 3]';
    else
        cc(4, 1)= 3*cp(thetaIdx+1, lambdaIdx+3)-3*cp(thetaIdx+2, lambdaIdx+3)+cp(thetaIdx+3, lambdaIdx+3);
    end
else
    if lambdaIdx+3>size(cp, 2)
        cc(4, 1)= 3*cp(thetaIdx, lambdaIdx+2)-3*cp(thetaIdx, lambdaIdx+1)+cp(thetaIdx, lambdaIdx);
    else
        cc(4, 1)= cp(thetaIdx, lambdaIdx+3);    
    end
end
%c12
if lambdaIdx<1
    cc(1, 2)= 3*cp(thetaIdx+1, lambdaIdx+1)-3*cp(thetaIdx+1, lambdaIdx+2)+cp(thetaIdx+1, lambdaIdx+3);
else
    cc(1, 2)= cp(thetaIdx+1, lambdaIdx);
end
%c22
cc(2, 2)= cp(thetaIdx+1, lambdaIdx+1);
%c32
cc(3, 2)= cp(thetaIdx+1, lambdaIdx+2);
%c42
if lambdaIdx+3>size(cp, 2)
    cc(4, 2)= 3*cp(thetaIdx+1, lambdaIdx+2)-3*cp(thetaIdx+1, lambdaIdx+1)+cp(thetaIdx+1, lambdaIdx);
else
    cc(4, 2)= cp(thetaIdx+1, lambdaIdx+3);
end
%c13
if lambdaIdx<1
    cc(1, 3)= 3*cp(thetaIdx+2, lambdaIdx+1)-3*cp(thetaIdx+2, lambdaIdx+2)+cp(thetaIdx+2, lambdaIdx+3);
else
    cc(1, 3)= cp(thetaIdx+2, lambdaIdx);
end
%c23
cc(2, 3)= cp(thetaIdx+2, lambdaIdx+1);
%c33
cc(3, 3)= cp(thetaIdx+2, lambdaIdx+2);
%c43
if lambdaIdx+3>size(cp, 2)
    cc(4, 3)= 3*cp(thetaIdx+2, lambdaIdx+2)-3*cp(thetaIdx+2, lambdaIdx+1)+cp(thetaIdx+2, lambdaIdx);
else
    cc(4, 3)= cp(thetaIdx+2, lambdaIdx+3);
end
%c14
if thetaIdx+3>size(cp, 1)
    if lambdaIdx<1
        cc(1, 4)= [1 -3 3]*cp((0:2)+thetaIdx, (1:3)+lambdaIdx)*[3 -3 1]';
    else
        cc(1, 4)= 3*cp(thetaIdx+2, lambdaIdx)-3*cp(thetaIdx+1, lambdaIdx)+cp(thetaIdx, lambdaIdx);
    end
else
    if lambdaIdx<1
        cc(1, 4)= 3*cp(thetaIdx+3, lambdaIdx+1)-3*cp(thetaIdx+3, lambdaIdx+2)+cp(thetaIdx+3, lambdaIdx+3);
    else
        cc(1, 4)= cp(thetaIdx+3, lambdaIdx);
    end
end
%c24
if thetaIdx+3>size(cp, 1)
    cc(2, 4)= 3*cp(thetaIdx+2, lambdaIdx+1)-3*cp(thetaIdx+1, lambdaIdx+1)+cp(thetaIdx, lambdaIdx+1);
else
    cc(2, 4)= cp(thetaIdx+3, lambdaIdx+1);
end
%c34
if thetaIdx+3>size(cp, 1)
    cc(3, 4)= 3*cp(thetaIdx+2, lambdaIdx+2)-3*cp(thetaIdx+1, lambdaIdx+2)+cp(thetaIdx, lambdaIdx+2);
else
    cc(3, 4)= cp(thetaIdx+3, lambdaIdx+2);
end
%c44
if thetaIdx+3>size(cp, 1)
    if lambdaIdx+3>size(cp, 2)
        cc(4, 4)= [1 -3 3]*cp((0:2)+thetaIdx, (0:2)+lambdaIdx)*[1 -3 3]';
    else
        cc(4, 4)= 3*cp(thetaIdx+2, lambdaIdx+3)-3*cp(thetaIdx+1, lambdaIdx+3)+cp(thetaIdx, lambdaIdx+3);
    end
else
    if lambdaIdx+3>size(cp, 2)
        cc(4, 4)= 3*cp(thetaIdx+3, lambdaIdx+2)-3*cp(thetaIdx+3, lambdaIdx+1)+cp(thetaIdx+3, lambdaIdx);
    else
        cc(4, 4)= cp(thetaIdx+3, lambdaIdx+3);
    end
end

cp_out= coeffs_c * cc(:);