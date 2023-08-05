#ifndef FAST_OUTPUT_H_
#define FAST_OUTPUT_H_

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

class FAST_OutputException: public std::exception {
public:
    FAST_OutputException(const std::string& msg= "Abstract FAST output exception") :
        m_msg(msg)
    {  }
    
    virtual const char* what() const throw () {
        return m_msg.c_str();
    }
    
    const std::string m_msg;
};



class FAST_Output {
public:
    FAST_Output(int nt_= 0) :
        TimeOut(0.0),
        TimeIncr(0.0),
        channels(),
        nt((nt_>0)? nt_ : 0),
        t_idx(0),
        idx(0),
        data(nullptr),
        ColScl(nullptr),
        ColOff(nullptr),
        compressed(nullptr)
        
    {   }
    
    virtual ~FAST_Output() {
        if(data) {
            free(data);
            data= nullptr;
        }
        if(ColScl) {
            free(ColScl);
            ColScl= nullptr;
        }
        if(ColOff) {
            free(ColOff);
            ColOff= nullptr;
        }
        if(compressed) {
            free(compressed);
            compressed= nullptr;
        }
    }
    
    void setNT(int nt_) {
        if(data)
            throw FAST_OutputException("Trying to set nt after data block was allocated");
        
        if(nt_>0)
            nt= nt_;
    }
    
    void setTime(double TimeOut_, double TimeIncr_) {
        TimeOut= TimeOut_;
        TimeIncr= TimeIncr_;
    }
    
    void addChannel(const std::string &name, const std::string &unit, const double* value, double scaling= 0.0) {
        if(data)
            throw FAST_OutputException("Trying to add channel after data block was allocated");
        
        channels.push_back({name, unit, value, scaling});
    }
    
    void allocData() {
        if(data)
            throw FAST_OutputException("Trying to allocate data twice");
        
        data= (double*)malloc(sizeof(double)*nt*channels.size());
        
        if(!data)
            throw FAST_OutputException("Could not allocate " + std::to_string(sizeof(double)*nt*channels.size()) + " bytes for data");
    }
    
    void collectData() {
        if(!data) allocData();
        if(t_idx>=nt) {
            printf("max capacity is %d\n", nt);
            throw FAST_OutputException("Trying to collect data beyond maximum capacity");
        }
        
        for(auto const &item : channels) {
            data[idx]= std::get<2>(item)[0];
            if(std::get<3>(item))
                data[idx]*= std::get<3>(item);
            idx++; 
        }
        ++t_idx;
    }
    
    void compressData() {
        if(!ColScl) {
            ColScl= (float*)malloc(sizeof(float)*channels.size());
            
            if(!ColScl)
                throw FAST_OutputException("Could not allocate " + std::to_string(sizeof(float)*channels.size()) + " bytes for ColScl");
        }            
        if(!ColOff) {
            ColOff= (float*)malloc(sizeof(float)*channels.size());
            
            if(!ColOff)
                throw FAST_OutputException("Could not allocate " + std::to_string(sizeof(float)*channels.size()) + " bytes for ColOff");
        }            
        if(!compressed) {
            compressed= (int16_t*)malloc(sizeof(int16_t)*nt*channels.size());
            
            if(!compressed)
                throw FAST_OutputException("Could not allocate " + std::to_string(sizeof(int16_t)*nt*channels.size()) + " bytes for compressed");
        }
        
        for(int c= 0; c<channels.size(); ++c) {
            double min_val= 0.0;
            double max_val= 0.0;
            
            for(int i= 0; i<t_idx; ++i) {
                if(data[c + i*channels.size()]>max_val) max_val= data[c + i*channels.size()];
                if(data[c + i*channels.size()]<min_val) min_val= data[c + i*channels.size()];
            }
            double range= max_val-min_val;
            if(range<=0.0) range= 1.0;
            
            ColScl[c]= ((double)std::numeric_limits<int16_t>::max() - (double)std::numeric_limits<int16_t>::min() - 2.0) / range;
            ColOff[c]= ((double)std::numeric_limits<int16_t>::min()) - min_val*ColScl[c];
            
            for(int i= 0; i<t_idx; ++i) {
                compressed[c + i*channels.size()]= data[c + i*channels.size()] * ColScl[c] + ColOff[c];
            }
        }
    }
    
    void write(const std::string &fname, const std::string &comment) {
        if(!data || t_idx<1)
            throw FAST_OutputException("Trying to write data before any collection");
        
        compressData();
        
        std::ofstream out(fname, std::ios::out | std::ios::binary);
        
        int16_t FileID= 2; // without time
        out.write((char*)&FileID, sizeof(int16_t));
        
        int32_t NumOutChans= channels.size();
        out.write((char*)&NumOutChans, sizeof(int32_t));
        out.write((char*)&t_idx, sizeof(int32_t));
        
        out.write((char*)&TimeOut, sizeof(double));
        out.write((char*)&TimeIncr, sizeof(double));
        
        out.write((char*)&ColScl[0], NumOutChans*sizeof(float));
        out.write((char*)&ColOff[0], NumOutChans*sizeof(float));
        
        int32_t LenDesc= comment.length();
        out.write((char*)&LenDesc, sizeof(int32_t));
        out.write((char*)&comment.data()[0], LenDesc*sizeof(char));
        
        char Str[11];

        snprintf(Str, 11, "%-10s", "Time");
        out.write((char*)&Str[0], 10*sizeof(char));
        
        for(auto const &item : channels) {
            snprintf(Str, 11, "%-10s", std::get<0>(item).c_str());
            out.write((char*)&Str[0], 10*sizeof(char));
        }
        
        snprintf(Str, 11, "%-10s", "s");
        out.write((char*)&Str[0], 10*sizeof(char));
        
        for(auto const &item : channels) {
            snprintf(Str, 11, "%-10s", std::get<1>(item).c_str());
            out.write((char*)&Str[0], 10*sizeof(char));
        }
        
        out.write((char*)&compressed[0], t_idx*NumOutChans*sizeof(int16_t));
        
        out.close();
    }
   
protected:
    double TimeOut;
    double TimeIncr;
    std::vector<std::tuple<std::string, std::string, const double*, double>> channels;
    
    int32_t nt;
    int32_t t_idx;
    int32_t idx;
    double *data;
    
    float *ColScl;
    float *ColOff;
    int16_t *compressed;
};


#endif /* FAST_OUTPUT_H_ */
