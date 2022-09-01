function d= DLAM_interp(param, tab, lam, theta_deg)
lambdaScaled= (lam-param.lambdaMin)/param.lambdaStep;
lambdaIdx= floor(lambdaScaled);
thetaScaled= (theta_deg-param.thetaMin)/param.thetaStep;
thetaIdx= floor(thetaScaled);
lambdaFact= 1.0 - lambdaScaled + lambdaIdx;
thetaFact= 1.0 - thetaScaled + thetaIdx;
lambdaIdx= lambdaIdx+1;
thetaIdx= thetaIdx+1;

d= ((thetaFact*(tab(lambdaIdx+1, thetaIdx)-tab(lambdaIdx, thetaIdx))/param.lambdaStep) + (1.0-thetaFact)*((tab(lambdaIdx+1, thetaIdx)-tab(lambdaIdx, thetaIdx))/param.lambdaStep));
