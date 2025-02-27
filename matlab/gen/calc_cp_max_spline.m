function [xs, ys]= calc_cp_max_spline(param)

wind_min= 3;
lam_max= 1.2*param.rpm_max/param.GBRatio/30*pi*param.Rrot / wind_min;
lam= linspace(0, lam_max, 10000);
cp_max= max(param.cp, [], 1);
cp_max_= interp1(param.lambda, cp_max, lam, 'linear', 'extrap');

[~, idx_lam_max]= max(cp_max);
lam_max= param.lambda(idx_lam_max);

xs= linspace(lam(1), lam(end), 15)';
w(lam>param.lambda(end))= 0.1*exp(param.lambda(end)-lam(lam>param.lambda(end)));
w(lam<param.lambda(1))= 0.1*exp(lam(lam<param.lambda(1))-param.lambda(1));
w(lam>param.lambda(1) & lam<param.lambda(end))= 1;
w(lam>lam_max-2 & lam<lam_max+2)= 10;
w(lam>lam_max-1 & lam<lam_max+1)= 50;
ys= fminsearch(@(ys)rms(w.*(cp_max_-spline(xs, ys, lam))) + 0.1*rms(diff(ys, 3)), interp1(lam, cp_max_, xs));

