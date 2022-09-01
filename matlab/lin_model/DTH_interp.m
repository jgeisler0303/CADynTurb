function d= DTH_interp(param, tab, lam, theta_deg)
lambdaScaled= (lam-param.lambdaMin)/param.lambdaStep;
lambdaIdx= floor(lambdaScaled);
thetaScaled= (theta_deg-param.thetaMin)/param.thetaStep;
thetaIdx= floor(thetaScaled);
lambdaFact= 1.0 - lambdaScaled + lambdaIdx;
thetaFact= 1.0 - thetaScaled + thetaIdx;
lambdaIdx= lambdaIdx+1;
thetaIdx= thetaIdx+1;
    
d= (( (lambdaFact*tab(lambdaIdx, thetaIdx+1) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx+1))-(lambdaFact*tab(lambdaIdx, thetaIdx) + (1.0-lambdaFact)*tab(lambdaIdx+1, thetaIdx)) )/param.thetaStep);
