function y= notch_omega(u, omega, BW, dt)

y= zeros(length(u), 1);
Wo= omega*dt;
BW= BW*dt;
if length(BW)==1
    BW= BW*ones(length(u), 1);
end

for k= 3:length(u)
%     Gb   = 10^(-Ab/20);
%     Ab= 3...; Gb= 1/sqrt(2);
%     beta = (sqrt(1-Gb.^2)/Gb)*tan(BW/2);
%     gain = 1/(1+beta);
    gain= 1/(1+tan(BW(k)/2));
    
    y(k)= gain*(u(k) -2*cos(Wo(k))*(u(k-1)-y(k-1)) + u(k-2) -2*y(k-2)) + y(k-2);
end