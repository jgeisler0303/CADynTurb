#ifndef FAST_WIND1_H_
#define FAST_WIND1_H_

#include "fast_wind0.h"

class FAST_Wind_Type1 : public FAST_Wind {
public:
    FAST_Wind_Type1(FAST_Parent_Parameters &p) :
        FAST_Wind(p)
    {
        if(p["InflowFile.WindType"]!=1)
            throw FAST_WindException("Trying to instantiate FAST_Wind_Type1 but parameter WindType is " + std::to_string(p["WindType"]));
        
        HWindSpeed= p["InflowFile.HWindSpeed"];
        RefHt= p["InflowFile.RefHt"];
        PLexp= p["InflowFile.PLexp"];
    }
    
    virtual ~FAST_Wind_Type1() {}
    
    virtual double getWind(double time) {
        return HWindSpeed * cos(PropagationDir);
    }
    
protected:
    double HWindSpeed;
    double RefHt;
    double PLexp;
};

#endif /* FAST_WIND1_H_ */
