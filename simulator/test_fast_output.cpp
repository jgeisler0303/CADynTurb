#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <stdint.h>
#include <cstring>
#include "fast_output.h"

int main(void) {
    double my_value;
    
    FAST_Output out(10);
    out.setTime(0.0, 0.01);
    out.addChannel("MYVAL", "N", &my_value);
    
    for(int i= 0; i<10; ++i) {
        my_value= ((double)i) * 13 + 0.3;
        out.collectData();
    }
    
    out.write("test_fast_output.outb", "This is a test output");
    
    exit(EXIT_SUCCESS);
}
