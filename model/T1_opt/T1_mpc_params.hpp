/* File generated form template cadyn_params.hpp.tem on 2026-06-28 19:46:05+02:00. Do not edit! *//* Multibody system: Simulation of a simplified horizontal axis wind turbine */
#include <string>
#include <map>
#include <fstream>
#include <iostream>
#include <stdlib.h>
#include <cstdio>
#include <Eigen/Dense>
#include <Eigen/Geometry>

#include "ParameterInfo.hpp"

class T1_mpcParameters {
public:
    T1_mpcParameters();
    void setParam(const std::string &name, const real_type *value);
    real_type getParam(const std::string &name);
    void getParamArray(real_type *p);
    int getNumParameters();
    void setFromFile(const std::string &fileName, bool skipUnknown= false);
    bool unsetParamsWithMsg();
    
    std::map<std::string, ParameterInfo> info_map;
    int unsetParams;
    
    real_type max_iter;
};

T1_mpcParameters::T1_mpcParameters() :
    info_map(),
    unsetParams(1) {
    int offset= 0;
    info_map["max_iter"]= ParameterInfo(&max_iter, 1, 1, offset); offset+= 1;
}

void T1_mpcParameters::setParam(const std::string &name, const real_type *value) {
    auto it = info_map.find(name);
    if(it==info_map.end())    
        throw std::runtime_error("Unknown parameter \"" + name + "\".");
    
    if(!it->second.setParam(value))
        unsetParams--;
}

real_type T1_mpcParameters::getParam(const std::string &name) {
    auto it = info_map.find(name);
    if(it==info_map.end())    
        throw std::runtime_error("Unknown parameter \"" + name + "\".");
    
    return it->second.getParam();    
}

void T1_mpcParameters::setFromFile(const std::string &fileName, bool skipUnknown) {
    std::ifstream infile(fileName);
    
    if(infile.is_open()) {
        int i= 0;
        for(std::string line; std::getline(infile, line);) {
            ++i;
            std::istringstream iss(line);
            
            std::string paramName;
            iss >> paramName;
            
            if(paramName.empty() || (paramName[0]=='*' || paramName[0]=='#')) // comment or empty line
                continue;
            
            auto it = info_map.find(paramName);
            if(it==info_map.end()) {
                if(skipUnknown)
                    continue;
                else
                    throw std::runtime_error("Unknown parameter \"" + paramName + "\".");
            }
            
            Eigen::Matrix<real_type,Eigen::Dynamic,Eigen::Dynamic> value(it->second.nrows, it->second.ncols);
            bool fail= false;
            
            for(int r= 0; r<it->second.nrows; ++r) {
                if(r>0) {
                    if(!std::getline(infile, line)) {
                        fprintf(stderr, "Out of lines while reading parameter \"%s(%d, 1)\".\n", paramName.c_str(), r);                   
                        fail= true;
                        break;
                    }
                    ++i;
                    iss.str(line);
                }                    
                for(int c= 0; c<it->second.ncols; ++c) {
                    iss >> value(r, c);
                    if(iss.fail()) {
                        fprintf(stderr, "Could not read value for parameter \"%s(%d, %d)\" in line %d.\n", paramName.c_str(), r, c, i);
                        fail= true;
                        break;
                    }                
                }
                if(fail) break;
            }
            if(fail) continue;
            
            try {
                setParam(paramName, value.data());
            } catch (const std::exception& e) {
                fprintf(stderr, "Error: %s in line %d.\n", e.what(), i);
                continue;
            }
        }            
    } else
        throw std::runtime_error("Could not open file \"" + fileName + "\"");
}   
    
bool T1_mpcParameters::unsetParamsWithMsg() {
    if(unsetParams) {
        fprintf(stderr, "The following parameters are not set:\n");
        for(auto const &i : info_map) {
            if(!i.second.isSet)
                fprintf(stderr, "%s\n", i.first.c_str());
        }
    }
    
    return unsetParams;
}

void T1_mpcParameters::getParamArray(real_type *p) {
    for(auto const &i : info_map) {
        if(!i.second.isSet)
            throw std::runtime_error("Parameter \"" + i.first + "\" is not set.");
        
        i.second.getParam(&p[i.second.offset]);
    }    
}

int T1_mpcParameters::getNumParameters() {
    int num= 0;
    for(auto const &i : info_map) {
        num+= i.second.nrows * i.second.ncols;
    }
    return num;
}
