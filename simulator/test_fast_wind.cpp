#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <stdint.h>
#include <cstring>

#include "fast_wind.h"

int main(void) {
    FAST_Parameters p("/home/jgeisler/Projekte/Research/CADynTurb/5MW_Baseline/NRELOffshrBsline5MW_InflowWind_Steady8mps.dat");
//     std::cout << p;
    
    FAST_Wind* wind= makeFAST_Wind(p);

    std::cout << " Wind at time 1: " << wind->getWind(1) << std::endl;
    
    delete wind;
    
    exit(EXIT_SUCCESS);
}
