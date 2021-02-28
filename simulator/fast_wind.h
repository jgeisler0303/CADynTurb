#ifndef FAST_WIND_H_
#define FAST_WIND_H_

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

#include "fast_parameters.h"

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
    FAST_Wind(FAST_Parameters &p) :
        p(p)
    {
        PropagationDir= p["PropagationDir"] / 180.0*M_PI;
    }
    
    virtual ~FAST_Wind() {}
    
    virtual double getWind(double time) { return 0; }
    
protected:
    FAST_Parameters &p;
    double PropagationDir;
};

class FAST_Wind_Type1 : public FAST_Wind {
public:
    FAST_Wind_Type1(FAST_Parameters &p) :
        FAST_Wind(p)
    {
        if(p["WindType"]!=1)
            throw FAST_WindException("Trying to instantiate FAST_Wind_Type1 but parameter WindType is " + std::to_string(p["WindType"]));
        
        HWindSpeed= p["HWindSpeed"];
        RefHt= p["RefHt"];
        PLexp= p["PLexp"];
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

class FAST_Wind_Type2 : public FAST_Wind {
public:
    FAST_Wind_Type2(FAST_Parameters &p) :
        FAST_Wind(p),
        wind(0)
    {
        if(p["WindType"]!=2)
            throw FAST_WindException("Trying to instantiate FAST_Wind_Type2 but parameter WindType is " + std::to_string(p["WindType"]));
        
        loadWindTable(p.getFilename(1));
        
        RefHt= p["RefHt"];
        RefLength= p["RefLength"];
    }
    
    virtual ~FAST_Wind_Type2() {}
    
    void loadWindTable(const std::string& Filename) {
        std::ifstream infile(Filename);
        if(!infile.is_open())
            throw FAST_WindException("Could not open uniform wind file \"" + Filename + "\"");
            
        std::string line;
        int l= 0;
        while (getline(infile, line)) {
            l++;
            if(line.empty()) continue;
            if((line.length()>1 && line[0]=='-' && line[1]=='-') || line[0]=='!') continue;
            
            std::istringstream iss(line);
            double values[8];
            for(int i= 0; i<8; ++i) {
                iss >> values[i];
                if(!iss)
                    throw FAST_WindException("Could not read column " + std::to_string(i) + " of wind table in line " + std::to_string(l));
            }
            wind.push_back({values[0], values[1], values[2]/180.0*M_PI, values[3], values[4], values[5], values[6], values[7]});
        }
        
        if(wind.size()<2)
            throw FAST_WindException("Inflow file \"" + Filename + "\" contained less than 2 line of table data");
    }
    
    double interp(double x0, double x1, double y0, double y1, double x) {
        return (y0*(x1-x) + y1*(x-x0))/(x1-x0);
    }
    
    double interpWind(const int idx, double time) {
        return interp(wind[last_idx][0], wind[last_idx+1][0], wind[last_idx][idx], wind[last_idx+1][idx], time);
    }
        
    virtual double getWind(double time) {
        while(last_idx > 0 && time < wind[last_idx][0]) last_idx--;
        while(last_idx < (wind.size()+1) && time > wind[last_idx+1][0]) last_idx++;
            
        if(time < wind[last_idx][0])
            return wind[last_idx][1] * cos(wind[last_idx][2]) + wind[last_idx][7];
        
        if(time > wind[last_idx+1][0])
            return wind[last_idx+1][1] * cos(wind[last_idx+1][2]) + wind[last_idx+1][7];

        return interpWind(1, time) * cos(interpWind(2, time)) + interpWind(7, time);
    }
    
protected:
    std::vector<std::array<double, 8>> wind;
    double RefHt;
    double RefLength;
    int last_idx= 0;
};

class FAST_Wind_Type3 : public FAST_Wind {
public:
    FAST_Wind_Type3(FAST_Parameters &p, double avg_exp_=3.0) :
        FAST_Wind(p),
        wind(0),
        TurbFilename(""),
        avg_exp(avg_exp_)
    {
        if(p["WindType"]!=3)
            throw FAST_WindException("Trying to instantiate FAST_Wind_Type3 but parameter WindType is " + std::to_string(p["WindType"]));
        
        loadWindFile(p.getFilename(2));
        
        TurbFilename= p.getFilename(2);
    }
    
    virtual ~FAST_Wind_Type3() {}
    
    void loadWindFile(const std::string& Filename) {
        double TipRad= p["TipRad"];
        
        std::ifstream infile(Filename, std::ios::in | std::ios::binary);
        if(!infile.is_open())
            throw FAST_WindException("Could not open TurbSim wind file \"" + Filename + "\"");
        
        infile.exceptions(std::ifstream::failbit | std::ifstream::badbit | std::ifstream::eofbit);
        
        int16_t ID;
        infile.read((char*)&ID, sizeof(int16_t));
        
        int32_t NumGrid_Z;
        infile.read((char*)&NumGrid_Z, sizeof(int32_t));
        
        int32_t NumGrid_Y;
        infile.read((char*)&NumGrid_Y, sizeof(int32_t));
        
        int32_t n_tower;
        infile.read((char*)&n_tower, sizeof(int32_t));
        
        int32_t nt;
        infile.read((char*)&nt, sizeof(int32_t));
        wind.reserve(nt);
        
        float dz;
        infile.read((char*)&dz, sizeof(float));
        
        float dy;
        infile.read((char*)&dy, sizeof(float));

        infile.read((char*)&TimeStep, sizeof(float));
        
        float u_hub;
        infile.read((char*)&u_hub, sizeof(float));
        
        float HubHt;
        infile.read((char*)&HubHt, sizeof(float));
        
        float Z_bottom;
        infile.read((char*)&Z_bottom, sizeof(float));
        
        float V_slope[3];
        float V_intercept[3];
        for(int i= 0; i<3; ++i) {
            infile.read((char*)&V_slope[i], sizeof(float));
            infile.read((char*)&V_intercept[i], sizeof(float));
        }
        
        int32_t n_char;
        infile.read((char*)&n_char, sizeof(int32_t));
        
        std::string comment;
        comment.reserve(n_char);
        for(int i= 0; i<n_char; ++i) {
            char c;
            infile.read((char*)&c, sizeof(char));
            comment.push_back(c);
        }
        
        int16_t v_grid_norm;
        float v_grid;
        float v_avg;
        float z_grid;
        float y_grid;
        for(int it= 0; it<nt; ++it) {
            for(int grid_z= 0; grid_z<NumGrid_Z; ++grid_z) {
                v_avg= 0.0;
                
                z_grid= Z_bottom + ((float)grid_z-1.0)*dz;
                for(int grid_y= 0; grid_y<NumGrid_Y; ++grid_y) {
                    y_grid= -0.5*((float)NumGrid_Y-1.0)*dy + ((float)grid_y-1.0)*dy;
                    for(int uvw= 0; uvw<3; ++uvw) {
                        infile.read((char*)&v_grid_norm, sizeof(int16_t));
                        if(uvw==0 && sqrt(pow(z_grid-HubHt, 2.0) + pow(y_grid, 2.0))<TipRad) {
                            v_grid= ((float)v_grid_norm - V_intercept[uvw]) / V_slope[uvw];
                            v_avg+= pow(v_grid, avg_exp);
                        }
                    }
                }
                wind.push_back(pow(v_avg, 1.0/avg_exp));
            }
            for(int i_tower= 0; i_tower<n_tower; ++i_tower) {
                for(int uvw= 0; uvw<3; ++uvw) {
                    infile.read((char*)&v_grid_norm, sizeof(int16_t));
                }
            }
        }
    }
    
    void writeWind2File(const std::string& Filename) {
        std::ofstream outfile(Filename);
        
        outfile << "! Averaged u-wind from file \"" << TurbFilename "\", avaerging exponent " << avg_exp << std::endl;
        outfile << "! Time\tWind\tWind\tVert.\tHoriz.\tVert.\tLinV\tGust" << std::endl;
        outfile << "!\t\t\tSpeed\tDir\tSpeed\tShear\tShear\tShear\tSpeed" << std::endl;
        
        outfile.setf( std::ios_base::scientific, std::ios_base::floatfield );
        outfile.precision(std::numeric_limits<long double>::digits10);
        double time= 0.0;
        for(int i= 0; i<wind.size(); ++i) {
            outfile << time << "\t" << wind[i] << "\t0.0\t0.0\t0.0\t0.0\t0.0\t0.0" << std::endl;
            time+= TimeStep;
        }
    }
    
    virtual double getWind(double time) {
        float TimeScaled= time/TimeStep;
        int idx= std::floor(TimeScaled);
        
        if(idx<0) return wind[0];
        if(idx>=(wind.size()-1)) return wind.back();
        
        float TimeFact= TimeScaled - idx;
        
        return (1.0-TimeFact)*wind[idx] + TimeFact*wind[idx+1];
    }
    
protected:
    std::vector<float> wind;
    float TimeStep;
    std::string TurbFilename;
    double avg_exp;
};

FAST_Wind* makeFAST_Wind(FAST_Parameters &p) {
    switch((int)p["WindType"]) {
        case 1:
            return new FAST_Wind_Type1(p);
        case 2:
            return new FAST_Wind_Type2(p);
        case 3:
            return new FAST_Wind_Type3(p);
        default:
            throw FAST_WindException("Wind type " + std::to_string(p["WindType"]) + " not yet supported");
    }
}

#endif /* FAST_WIND_H_ */
