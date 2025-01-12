#ifndef FAST_PARENT_PARAM_H_
#define FAST_PARENT_PARAM_H_

#include <cstring>
#include <string>
#include <sstream>
#include <map>
#include <exception>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <fstream>
#include <limits>
#include <array>
#include <vector>
#include <algorithm>
#include "fast_parameters.h"

class FAST_Parent_Parameters : public FAST_Parameters {
public:
    FAST_Parent_Parameters() :
        FAST_Parameters()
    {}

    FAST_Parent_Parameters(const std::string& file_name, bool with_exception= true) :
        FAST_Parameters(file_name, with_exception)
    {
        readFile();
    }
    
    void readFile(const std::string& file_name, bool with_exception= true) {
        FAST_Parameters::readFile(file_name, with_exception);
        readFile();
    }

    void readFile() {
        // detect and fill main file
        try {
//             children.emplace( std::piecewise_construct, std::make_tuple("BDBldFile(1)"), std::make_tuple(getFilename("BDBldFile(1)"), false) );
//             children.emplace( std::piecewise_construct, std::make_tuple("BDBldFile(2)"), std::make_tuple(getFilename("BDBldFile(2)"), false) );
//             children.emplace( std::piecewise_construct, std::make_tuple("BDBldFile(3)"), std::make_tuple(getFilename("BDBldFile(3)"), false) );
            children.emplace( std::piecewise_construct, std::make_tuple("InflowFile"), std::make_tuple(getFilename("InflowFile"), false) );
            children.emplace( std::piecewise_construct, std::make_tuple("AeroFile"), std::make_tuple(getFilename("AeroFile"), false) );
            children.emplace( std::piecewise_construct, std::make_tuple("ServoFile"), std::make_tuple(getFilename("ServoFile"), false) );
            children.emplace( std::piecewise_construct, std::make_tuple("HydroFile"), std::make_tuple(getFilename("HydroFile"), false) );
            children.emplace( std::piecewise_construct, std::make_tuple("SubFile"), std::make_tuple(getFilename("SubFile"), false) );
            children.emplace( std::piecewise_construct, std::make_tuple("MooringFile"), std::make_tuple(getFilename("MooringFile"), false) );
            children.emplace( std::piecewise_construct, std::make_tuple("IceFile"), std::make_tuple(getFilename("IceFile"), false) );
            children.emplace( std::piecewise_construct, std::make_tuple("EDFile"), std::make_tuple(getFilename("EDFile"), false) );
        } catch(...) {
        }
        
        // detect and fill BeamDyn file
        try {
            // children.emplace( std::piecewise_construct, std::make_tuple("BldFile"), std::make_tuple(getFilename("BldFile"), false) );
        } catch(...) {
        }
        
        // detect and fill AeroDyn file
        try {
            children.emplace( std::piecewise_construct, std::make_tuple("AA_InputFile"), std::make_tuple(getFilename("AA_InputFile"), false) );
            children.emplace( std::piecewise_construct, std::make_tuple("OLAFInputFileName"), std::make_tuple(getFilename("OLAFInputFileName"), false) );
            children.emplace( std::piecewise_construct, std::make_tuple("ADBlFile(1)"), std::make_tuple(getFilename("ADBlFile(1)"), false) );
            children.emplace( std::piecewise_construct, std::make_tuple("ADBlFile(2)"), std::make_tuple(getFilename("ADBlFile(2)"), false) );
            children.emplace( std::piecewise_construct, std::make_tuple("ADBlFile(3)"), std::make_tuple(getFilename("ADBlFile(3)"), false) );
        } catch(...) {
        }

        // detect and fill ServoDyn file
        try {
            children.emplace( std::piecewise_construct, std::make_tuple("NTMDfile"), std::make_tuple(getFilename("NTMDfile"), false) );
            children.emplace( std::piecewise_construct, std::make_tuple("TTMDfile"), std::make_tuple(getFilename("TTMDfile"), false) );
        } catch(...) {
        }

        // detect and fill ElastoDyn file
        try {
            children.emplace( std::piecewise_construct, std::make_tuple("BldFile(1)"), std::make_tuple(getFilename("BldFile(1)"), false) );
            children.emplace( std::piecewise_construct, std::make_tuple("BldFile(2)"), std::make_tuple(getFilename("BldFile(2)"), false) );
            children.emplace( std::piecewise_construct, std::make_tuple("BldFile(3)"), std::make_tuple(getFilename("BldFile(3)"), false) );
            children.emplace( std::piecewise_construct, std::make_tuple("FurlFile"), std::make_tuple(getFilename("FurlFile"), false) );
            children.emplace( std::piecewise_construct, std::make_tuple("TwrFile"), std::make_tuple(getFilename("TwrFile"), false) );
        } catch(...) {
        }        
    }
    
    double operator[](const std::string &name) {
        size_t pos;
        if((pos=name.find('.')) != std::string::npos) {
            if(children.find(name.substr(0, pos))==children.end())
                throw FAST_ParametersException("Parameter \"" + name + "\" not found: no sub-file found");
            
            try {
                FAST_Parent_Parameters child= children.at(name.substr(0, pos));
                return child[name.substr(pos+1)];
            } catch(...) {
                throw FAST_ParametersException("Parameter \"" + name.substr(pos+1) + "\" in sub-file \"" + name.substr(0, pos) + "\" not found");
            }
        } else {
            std::string uname= name;
            std::transform(uname.begin(), uname.end(), uname.begin(), ::toupper);
            
            if(values.find(uname)==values.end())
                throw FAST_ParametersException("Parameter \"" + name + "\" not found");
        
            return values[uname];
        }
    }
    
    const std::string &getString(const std::string &name) {
        size_t pos;
        if((pos=name.find('.')) != std::string::npos) {
            if(children.find(name.substr(0, pos))==children.end())
                throw FAST_ParametersException("Parameter \"" + name + "\" not found: no sub-file found");
            
            try {
                FAST_Parent_Parameters child= children.at(name.substr(0, pos));
                return child.getString(name.substr(pos+1));
            } catch(...) {
                throw FAST_ParametersException("Parameter \"" + name.substr(pos+1) + "\" in sub-file \"" + name.substr(0, pos) + "\" not found");
            }
        } else {
            std::string uname= name;
            std::transform(uname.begin(), uname.end(), uname.begin(), ::toupper);
            
            if(strings.find(uname)==strings.end())
                throw FAST_ParametersException("Parameter \"" + name + "\" not found");
            
            return strings[uname];
        }
    }
    
    const std::string getFilename(const std::string &name) {
        size_t pos;
        if((pos=name.find('.')) != std::string::npos) {
            if(children.find(name.substr(0, pos))==children.end())
                throw FAST_ParametersException("Parameter \"" + name + "\" not found: no sub-file found");
            
            try {
                FAST_Parent_Parameters child= children.at(name.substr(0, pos));
                return child.getFilename(name.substr(pos+1));
            } catch(...) {
                throw FAST_ParametersException("Parameter \"" + name.substr(pos+1) + "\" in sub-file \"" + name.substr(0, pos) + "\" not found");
            }
        } else {
            std::string value= getString(name);
            return make_path_absolute(value);
        }
    }

    const std::vector<std::vector<double>> &getTable(const std::string &name) {
        size_t pos;
        if((pos=name.find('.')) != std::string::npos) {
            if(children.find(name.substr(0, pos))==children.end())
                throw FAST_ParametersException("Parameter \"" + name + "\" not found: no sub-file found");
            
            try {
                FAST_Parent_Parameters child= children.at(name.substr(0, pos));
                return child.getTable(name.substr(pos+1));
            } catch(...) {
                throw FAST_ParametersException("Parameter \"" + name.substr(pos+1) + "\" in sub-file \"" + name.substr(0, pos) + "\" not found");
            }
        } else {
            std::string uname= name;
            std::transform(uname.begin(), uname.end(), uname.begin(), ::toupper);
            
            if(tables.find(uname)==tables.end())
                throw FAST_ParametersException("Parameter \"" + name + "\" not found");
            
            return tables[uname];
        }
    }
    
    friend std::ostream& operator<< (std::ostream& os, const FAST_Parent_Parameters& p) {
        os << p.comment << std::endl;
        
//         for(auto const &item : p.values) {
//             os << item.first << ": " << item.second << std::endl;            
//         }
        
        for(auto const &item : p.strings) {
            os << item.first << ": " << item.second << std::endl;
            try {
                os << p.children.at(item.first);
                os << "END " << item.second << std::endl;
            } catch(...) {
            }
        }
        
        for(auto const &item : p.tables) {
            os << item.first << ":" << std::endl;
            for(auto const &vec : item.second) {
                os << "  ";
                for(auto const &val : vec) {
                    os << val << ", ";
                }
                os << std::endl;
            }
        }
        
        os << "Filenames:" << std::endl;
        for(auto const &name : p.filenames) {
            os << "  \"" << name << "\"" << std::endl;
        }
        
        return os;
    }
    
    std::map<std::string, FAST_Parent_Parameters> children;  
};


#endif /* FAST_PARENT_PARAM_H_ */
