clc

print_cmp(interp_cubic(param, param.lambdaMin, param.thetaMin), param.cp(1, 1))
print_cmp(interp_cubic(param, param.lambdaMin, param.thetaMax), param.cp(end, 1))
print_cmp(interp_cubic(param, param.lambdaMax, param.thetaMin), param.cp(1, end))
print_cmp(interp_cubic(param, param.lambdaMax, param.thetaMax), param.cp(end, end))

print_cmp(interp_cubic(param, param.lambdaMin, param.thetaMin+param.thetaStep), param.cp(2, 1))
print_cmp(interp_cubic(param, param.lambdaMin+param.lambdaStep, param.thetaMin), param.cp(1, 2))
print_cmp(interp_cubic(param, param.lambdaMin+param.lambdaStep, param.thetaMin+param.thetaStep), param.cp(2, 2))

print_cmp(interp_cubic(param, param.lambdaMin, param.thetaMax-param.thetaStep), param.cp(end-1, 1))
print_cmp(interp_cubic(param, param.lambdaMin+param.lambdaStep, param.thetaMax), param.cp(end, 2))
print_cmp(interp_cubic(param, param.lambdaMin+param.lambdaStep, param.thetaMax-param.thetaStep), param.cp(end-1, 2))

print_cmp(interp_cubic(param, param.lambdaMax, param.thetaMin+param.thetaStep), param.cp(2, end))
print_cmp(interp_cubic(param, param.lambdaMax-param.lambdaStep, param.thetaMin), param.cp(1, end-1))
print_cmp(interp_cubic(param, param.lambdaMax-param.lambdaStep, param.thetaMin+param.thetaStep), param.cp(2, end-1))

print_cmp(interp_cubic(param, param.lambdaMax, param.thetaMax-param.thetaStep), param.cp(end-1, end))
print_cmp(interp_cubic(param, param.lambdaMax-param.lambdaStep, param.thetaMax), param.cp(end, end-1))
print_cmp(interp_cubic(param, param.lambdaMax-param.lambdaStep, param.thetaMax-param.thetaStep), param.cp(end-1, end-1))

interp_cmp(param, param.lambdaMin+0.5*param.lambdaStep, param.thetaMin+0.5*param.thetaStep)
interp_cmp(param, param.lambdaMin+0.5*param.lambdaStep, param.thetaMin+1.0*param.thetaStep)
interp_cmp(param, param.lambdaMin+0.5*param.lambdaStep, param.thetaMin+1.5*param.thetaStep)
interp_cmp(param, param.lambdaMin+1.0*param.lambdaStep, param.thetaMin+0.5*param.thetaStep)
interp_cmp(param, param.lambdaMin+1.5*param.lambdaStep, param.thetaMin+0.5*param.thetaStep)

interp_cmp(param, param.lambdaMin+0.5*param.lambdaStep, param.thetaMax-0.5*param.thetaStep)
interp_cmp(param, param.lambdaMin+1.0*param.lambdaStep, param.thetaMax-0.5*param.thetaStep)
interp_cmp(param, param.lambdaMin+1.5*param.lambdaStep, param.thetaMax-0.5*param.thetaStep)
interp_cmp(param, param.lambdaMin+0.5*param.lambdaStep, param.thetaMax-1.0*param.thetaStep)
interp_cmp(param, param.lambdaMin+0.5*param.lambdaStep, param.thetaMax-1.5*param.thetaStep)

interp_cmp(param, param.lambdaMax-0.5*param.lambdaStep, param.thetaMin+0.5*param.thetaStep)
interp_cmp(param, param.lambdaMax-1.0*param.lambdaStep, param.thetaMin+0.5*param.thetaStep)
interp_cmp(param, param.lambdaMax-1.5*param.lambdaStep, param.thetaMin+0.5*param.thetaStep)
interp_cmp(param, param.lambdaMax-0.5*param.lambdaStep, param.thetaMin+1.0*param.thetaStep)
interp_cmp(param, param.lambdaMax-0.5*param.lambdaStep, param.thetaMin+1.5*param.thetaStep)

interp_cmp(param, param.lambdaMax-0.5*param.lambdaStep, param.thetaMax-0.5*param.thetaStep)
interp_cmp(param, param.lambdaMax-1.0*param.lambdaStep, param.thetaMax-0.5*param.thetaStep)
interp_cmp(param, param.lambdaMax-1.5*param.lambdaStep, param.thetaMax-0.5*param.thetaStep)
interp_cmp(param, param.lambdaMax-0.5*param.lambdaStep, param.thetaMax-1.0*param.thetaStep)
interp_cmp(param, param.lambdaMax-0.5*param.lambdaStep, param.thetaMax-1.5*param.thetaStep)

interp_cmp(param, param.lambdaMin+1.5*param.lambdaStep, param.thetaMin+1.5*param.thetaStep)
interp_cmp(param, param.lambdaMin+1.5*param.lambdaStep, param.thetaMax-1.5*param.thetaStep)
interp_cmp(param, param.lambdaMax-1.5*param.lambdaStep, param.thetaMin+1.5*param.thetaStep)
interp_cmp(param, param.lambdaMax-1.5*param.lambdaStep, param.thetaMax-1.5*param.thetaStep)

%%
for i= 1:30
    interp_cmp(param, param.lambdaMin+rand(1)*(param.lambdaMax-param.lambdaMin), param.thetaMin+rand(1)*(param.thetaMax-param.thetaMin))
end

%%
subplot(2, 1, 1)
lam= linspace(param.lambdaMin, param.lambdaMax, 200);
cp= lam;
for i= 1:length(lam)
    cp(i)= interp_cubic(param, lam(i), param.thetaMin+param.thetaStep+0.44);
end
plot(lam, cp, lam, interp2(param.lambda, param.theta, param.cp, lam, param.thetaMin+param.thetaStep+0.44, 'cubic'))
grid on

subplot(2, 1, 2)
th= linspace(param.thetaMin, param.thetaMax, 200);
cp= th;
for i= 1:length(th)
    cp(i)= interp_cubic(param, param.lambdaMin+param.lambdaStep+1.33, th(i));
%     interp_cmp(param, param.lambdaMin+param.lambdaStep+1.33, th(i))
end
plot(th, cp, th, interp2(param.lambda, param.theta, param.cp, param.lambdaMin+param.lambdaStep+1.33, th, 'cubic'))
grid on

%%
function print_cmp(a, b)
s= dbstack;
if (a-b)<1e-6, return; end

fprintf('%d: %f, %f, %f\n', s(end).line, a, b, a-b)
end

function interp_cmp(param, lam, th)
print_cmp(interp_cubic(param, lam, th), interp2(param.lambda, param.theta, param.cp, lam, th, 'cubic'))
end