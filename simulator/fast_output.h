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

#define max_sensor_name 10

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
        channels_float(),
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
    
    bool checkAddChannel(std::string &name) {
        if(data)
            throw FAST_OutputException("Trying to add channel after data block was allocated");
        
        if(name.length()>max_sensor_name) {
            printf("Warning writing FAST output: signal name \"%s\" too long. Will be truncated\n", name.c_str());
            name= name.substr(0, max_sensor_name);
        }
        
        for(auto const &item : channels) {
            if(std::get<0>(item).compare(name)==0) {
                printf("Warning adding signal to FAST output: name is not unique: \"%s\". It will not be added.\n", name.c_str());
                return false;
            }
        }
        for(auto const &item : channels_float) {
            if(std::get<0>(item).compare(name)==0) {
                printf("Warning adding signal to FAST output: name is not unique: \"%s\". It will not be added.\n", name.c_str());
                return false;
            }
        }
        return true;
    }
    
    void addChannel(const std::string &name, const std::string &unit, const double* value, double scaling= 0.0) {
        std::string name_= name;
        if(checkAddChannel(name_))
            channels.push_back({name_, unit, value, scaling});
    }
    void addChannel(const std::string &name, const std::string &unit, const float* value) {
        std::string name_= name;
        if(checkAddChannel(name_))
            channels_float.push_back({name_, unit, value});
    }
    
    void allocData() {
        if(data)
            throw FAST_OutputException("Trying to allocate data twice");
        
        int total_channels= channels.size()+channels_float.size();
        data= (double*)malloc(sizeof(double)*nt*total_channels);
        
        if(!data)
            throw FAST_OutputException("Could not allocate " + std::to_string(sizeof(double)*nt*total_channels) + " bytes for data");
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
        for(auto const &item : channels_float) {
            data[idx]= std::get<2>(item)[0];
            idx++; 
        }
        ++t_idx;
    }
    
    void compressData() {
        int total_channels= channels.size()+channels_float.size();
        if(!ColScl) {
            ColScl= (float*)malloc(sizeof(float)*total_channels);
            
            if(!ColScl)
                throw FAST_OutputException("Could not allocate " + std::to_string(sizeof(float)*total_channels) + " bytes for ColScl");
        }            
        if(!ColOff) {
            ColOff= (float*)malloc(sizeof(float)*total_channels);
            
            if(!ColOff)
                throw FAST_OutputException("Could not allocate " + std::to_string(sizeof(float)*total_channels) + " bytes for ColOff");
        }            
        if(!compressed) {
            compressed= (int16_t*)malloc(sizeof(int16_t)*nt*total_channels);
            
            if(!compressed)
                throw FAST_OutputException("Could not allocate " + std::to_string(sizeof(int16_t)*nt*total_channels) + " bytes for compressed");
        }
        
        for(int c= 0; c<total_channels; ++c) {
            double min_val= 0.0;
            double max_val= 0.0;
            
            for(int i= 0; i<t_idx; ++i) {
                if(data[c + i*total_channels]>max_val) max_val= data[c + i*total_channels];
                if(data[c + i*total_channels]<min_val) min_val= data[c + i*total_channels];
            }
            double range= max_val-min_val;
            if(range<=0.0) range= 1.0;
            
            ColScl[c]= ((double)std::numeric_limits<int16_t>::max() - (double)std::numeric_limits<int16_t>::min() - 2.0) / range;
            ColOff[c]= ((double)std::numeric_limits<int16_t>::min()) - min_val*ColScl[c];
            
            for(int i= 0; i<t_idx; ++i) {
                compressed[c + i*total_channels]= data[c + i*total_channels] * ColScl[c] + ColOff[c];
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
        
        int32_t NumOutChans= channels.size() + channels_float.size();
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
        out.write((char*)&Str[0], max_sensor_name*sizeof(char));
        
        for(auto const &item : channels) {
            snprintf(Str, 11, "%-10s", std::get<0>(item).c_str());
            out.write((char*)&Str[0], max_sensor_name*sizeof(char));
        }
        for(auto const &item : channels_float) {
            snprintf(Str, 11, "%-10s", std::get<0>(item).c_str());
            out.write((char*)&Str[0], max_sensor_name*sizeof(char));
        }
        
        snprintf(Str, 11, "%-10s", "s");
        out.write((char*)&Str[0], max_sensor_name*sizeof(char));
        
        for(auto const &item : channels) {
            snprintf(Str, 11, "%-10s", std::get<1>(item).c_str());
            out.write((char*)&Str[0], max_sensor_name*sizeof(char));
        }
        for(auto const &item : channels_float) {
            snprintf(Str, 11, "%-10s", std::get<1>(item).c_str());
            out.write((char*)&Str[0], max_sensor_name*sizeof(char));
        }
        
        out.write((char*)&compressed[0], t_idx*NumOutChans*sizeof(int16_t));
        
        out.close();
    }
   
protected:
    double TimeOut;
    double TimeIncr;
    std::vector<std::tuple<std::string, std::string, const double*, double>> channels;
    std::vector<std::tuple<std::string, std::string, const float*>> channels_float;
    
    int32_t nt;
    int32_t t_idx;
    int32_t idx;
    double *data;
    
    float *ColScl;
    float *ColOff;
    int16_t *compressed;
};


#endif /* FAST_OUTPUT_H_ */
