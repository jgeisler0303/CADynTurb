#ifndef FAST_WIND0_H_
#define FAST_WIND0_H_

#include <cmath>
#include <cstring>
#include <string>
#include <map>
#include <exception>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <fstream>
#include <limits>
#include <array>
#include <vector>
#include <tuple>
#include <iomanip>

#include "fast_parent_param.h"

class FAST_WindException: public std::exception {
public:
    FAST_WindException(const std::string& msg= "Abstract FAST wind exception") :
        m_msg(msg)
    {  }
    
    virtual const char* what() const throw () {
        return m_msg.c_str();
    }
    
    const std::string m_msg;
};

class FAST_Wind {
public:
    FAST_Wind(FAST_Parent_Parameters &p) :
        p(p)
    {
        PropagationDir= p["InflowFile.PropagationDir"] / 180.0*M_PI;
    }
    
    virtual ~FAST_Wind() {}
    
    virtual double getWind(double time) { return 0; }
    virtual void getShear(double time, double &h_shear, double &v_shear) {
        h_shear= 0.0;
        v_shear= 0.0;
    }
    
protected:
    FAST_Parent_Parameters &p;
    double PropagationDir;
};

#endif /* FAST_WIND0_H_ */
