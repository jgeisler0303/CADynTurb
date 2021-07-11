#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <stdint.h>
#include <cstring>

#include "fast_wind.h"

int main(int argc, char* argv[]) {
    FAST_Parent_Parameters p(argv[1]);
    
    FAST_Wind* wind= makeFAST_Wind(p);

    std::cout << " Wind at time 0: " << wind->getWind(0) << std::endl;
    std::cout << " Wind at time 1: " << wind->getWind(1) << std::endl;
    std::cout << " Wind at time 2: " << wind->getWind(2) << std::endl;
    std::cout << " Wind at time 3: " << wind->getWind(3) << std::endl;
    
    delete wind;
    
    exit(EXIT_SUCCESS);
}
