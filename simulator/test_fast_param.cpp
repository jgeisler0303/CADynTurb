#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <stdint.h>
#include <cstring>

#include "fast_parent_param.h"

int main(void) {
    FAST_Parent_Parameters p("5MW_Land_IMP_6.fst");
    std::cout << p;
    
    std::cout << "AeroFile.WakeMod: " << p["AeroFile.WakeMod"] << std::endl;
    std::cout << "AeroFile.OLAFInputFileName: " << p.getString("AeroFile.OLAFInputFileName") << std::endl;
    
    exit(EXIT_SUCCESS);
}
