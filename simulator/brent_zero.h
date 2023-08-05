#ifndef BRENT_ZERO_H_
#define BRENT_ZERO_H_

int brent(double(*f)(double, void *), double &xs, double a, double b, void *data, double t= 1e-6, int maxiter= 1000) {

    double fa= f(a, data);
    double fb= f(b, data);

    if(fa*fb>0)
        return -1;

    double c= a;
    double fc= fa;

    double d= b-a;
    double e= d;

    int iter;
    for(iter= 0; iter<maxiter; ++iter) {

        if(fb*fc>0) {
            c= a;
            fc= fa;
            d= b-a;
            e= d;
        }

        if(fabs(fc)<fabs(fb)) {
            a= b;
            b= c;
            c= a;
            fa= fb;
            fb= fc;
            fc= fa;
        }

        double tol= 2*std::numeric_limits<double>::epsilon()*fabs(b)+t;
        double m= (c-b)/2;

        if((fabs(m)>tol) && (fabs(fb)>0)) {
            double s, p, q;

            if((fabs(e)<tol) || (fabs(fa)<=fabs(fb))) {
                d= m;
                e= m;
            } else {
                s= fb/fa;
                if(a==c) {
                    p= 2*m*s;
                    q= 1-s;
                } else {
                    q= fa/fc;
                    double r= fb/fc;
                    p= s*(2*m*q*(q-r)-(b-a)*(r-1));
                    q= (q-1)*(r-1)*(s-1);
                }

                if(p>0)
                    q= -q;
                else
                    p= -p;

                s= e;
                e= d;
                if(( 2*p<3*m*q-abs(tol*q) ) && (p<abs(s*q/2))) {
                    d= p/q;
                } else {
                    d= m;
                    e= m;
                }
            }
            a= b;
            fa= fb;

            if(fabs(d)>tol) {
                b= b+d;
            } else {
                if(m>0)
                    b= b+tol;
                else
                    b= b-tol;
            }
        } else
            break;
            
        fb= f(b, data);
    }
            
    if(iter>=maxiter)
        return -2;
            
    xs= b;
    return iter;
}

#endif /* BRENT_ZERO_H_ */
