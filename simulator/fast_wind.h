#ifndef FAST_WIND_H_
#define FAST_WIND_H_

#include "fast_wind1.h"
#include "fast_wind2.h"
#include "fast_wind3.h"
#include "fast_wind4.h"

FAST_Wind* makeFAST_Wind(FAST_Parent_Parameters &p, double dx=0.0, bool with_shear= false) {
    switch((int)p["InflowFile.WindType"]) {
        case 1:
            return new FAST_Wind_Type1(p);
        case 2:
            return new FAST_Wind_Type2(p);
        case 3:
            return new FAST_Wind_Type3(p, dx, with_shear);
        case 4:
            return new FAST_Wind_Type4(p, dx, with_shear);
        default:
            throw FAST_WindException("Wind type " + std::to_string(p["InflowFile.WindType"]) + " not yet supported");
    }
}

#endif /* FAST_WIND_H_ */
