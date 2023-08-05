c= sym('c', [4, 4]);
t= sym('t', [1, 1]);
s= sym('s', [1, 1]);

g= @(s, c1, c2, c3, c4) c1*(-s^3+2*s^2-s)/2 + c2*(3*s^3-5*s^2+2)/2 + c3*(-3*s^3+4*s^2+s)/2 + c4*(s^3-s^2)/2;

k1= g(t, c(1, 1), c(1, 2), c(1, 3), c(1, 4));
k2= g(t, c(2, 1), c(2, 2), c(2, 3), c(2, 4));
k3= g(t, c(3, 1), c(3, 2), c(3, 3), c(3, 4));
k4= g(t, c(4, 1), c(4, 2), c(4, 3), c(4, 4));
k= g(s, k1, k2, k3, k4);
[coeffs_c, cc]= coeffs(k, c);
matlabFunction(coeffs_c, 'File', 'bicubic_kernel_coeffs')

