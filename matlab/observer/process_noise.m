% Demo and experiment with noise discretisation

T=0.1;
B= [1 0.5; 0 2];
Q= diag([10 1]);
G= expm([-A Q; zeros(2) A']*T);
Qd= G(3:4, 3:4)'*G(1:2, 3:4);
G= expm([-A B*Q*B';zeros(2) A']*T);
QBd= G(3:4, 3:4)'*G(1:2, 3:4);
Gb= expm([A B; zeros(2, 4)]*T);
Bd= Gb(1:2, 3:4);
QBd_=Bd*Q/T*Bd';

[QBd, QBd_]
