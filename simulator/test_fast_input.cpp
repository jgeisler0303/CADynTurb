#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <stdint.h>
#include <cstring>
#include "fast_output.h"
#include "fast_input.h"

int main(void) {
    FAST_Input in("simp_12_6DOF.outb");
    
    
    FAST_Output out(in.NT);
    out.setTime(0.0, in.time[1]-in.time[0]);
    
    std::vector<double> d(in.NumOutChans);
    int i_chan= 0;
    for(auto it=in.data.begin(); it!=in.data.end(); ++it, ++i_chan)
        out.addChannel(it->first, in.units[it->first], &d[i_chan]);
    
    for(int i_t= 0; i_t<in.NT; ++i_t) {
        i_chan= 0;
        for(auto it=in.data.begin(); it!=in.data.end(); ++it, ++i_chan)
            d[i_chan]= it->second[i_t];
        
        out.collectData();
    }
    
    out.write("test_fast_output.outb", in.comment);
    
    exit(EXIT_SUCCESS);
}
