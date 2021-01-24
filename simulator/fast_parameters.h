#ifndef FAST_PARAMETERS_H_
#define FAST_PARAMETERS_H_

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
#include <filesystem>

class FAST_ParametersException: public std::exception {
public:
    FAST_ParametersException(const std::string& msg= "Abstract FAST parameter exception") :
        m_msg(msg)
    {  }
    
    virtual const char* what() const throw () {
        return m_msg.c_str();
    }
    
    const std::string m_msg;
};



class FAST_Parameters {
public:
    FAST_Parameters(const std::string& file_name) :
        values(),
        path(file_name),
        comment()
    {
        // std::setlocale(LC_NUMERIC, "en_US.UTF-8");
        
        std::ifstream infile(file_name);
        if(!infile.is_open())
            throw FAST_ParametersException("Could not open parameter file \"" + file_name + "\"");
        
        path= path.remove_filename();
        
        std::string line;
        std::string label;
        std::string value;
        bool comment_set= false;
        int table_lines= 0;
        int table_line= 0;        
        while (getline(infile, line)) {
            if(line.empty()) continue;
            if((line.length()>1 && line[0]=='-' && line[1]=='-') || line[0]=='!') continue;
            
            if(!comment_set) {
                comment= line;
                comment_set= true;
                continue;
            }
            
            if(table_lines) {
                table_line++;
                if(table_line<0) continue;
                
                if(table_line<table_lines) {
                    std::istringstream iss(line);
                    while(iss) {
                        iss >> value;
                        try {
                            double v= std::stod(value);

                            tables[label][table_line].push_back(v);
                        } catch (const std::exception& e) {
                        }
                    }
                    continue;
                } else
                    table_lines= 0;
                
            }
            
            std::istringstream iss(line);
            iss >> value >> label;
            
            if(value.empty() || label.empty()) continue;
            if(value=="OutList") break;
            
            if(label=="Filename") {
                if(value[0]=='"') value= value.substr(1);
                if(value.length()>0 && value.back()=='"') value= value.substr(0, value.length()-1);
                
                std::filesystem::path fpath= value;
                if(fpath.is_relative()) {
                    fpath= path;
                    fpath+= value;
                }
                
                filenames.push_back(fpath.string());
                
                continue;
            }
            
            if(value[0]=='t' || value[0]=='T') {
                values[label]= 1.0;
                continue;
            }
            if(value[0]=='f' || value[0]=='F') {
                values[label]= 0.0;
                continue;
            }
            
            try {
                double v= std::stod(value);
                
                values[label]= v;
                
                for(int i= 0; i<table_labels.size(); ++i) {
                    if(label==table_labels[i]) {
                        label= label.substr(1);
                        tables[label].resize(v);
                        
                        table_lines= v;
                        table_line= -3;
                        
                        break;
                    }
                }
            } catch (const std::exception& e) {
                if(value[0]=='"') value= value.substr(1);
                if(value.length()>0 && value.back()=='"') value= value.substr(0, value.length()-1);
                
                strings[label]= value;
            }
        }
    }
    
    double operator[](const std::string &name) {
        if(values.find(name)==values.end())
            throw FAST_ParametersException("Parameter \"" + name + "\" not found");
//            return std::numeric_limits<double>::quiet_NaN();
        
        return values[name];
    }
    
    const std::string &getString(const std::string &name) {
        if(strings.find(name)==strings.end())
            throw FAST_ParametersException("Parameter \"" + name + "\" not found");
        //            return std::numeric_limits<double>::quiet_NaN();
        
        return strings[name];
    }
    
    const std::string &getFilename(int idx) {
        if(filenames.size()<=idx)
            throw FAST_ParametersException("Filename index too high");
        
        return filenames[idx];
    }
    
    const std::vector<std::vector<double>> &getTable(const std::string &name) {
        if(tables.find(name)==tables.end())
            throw FAST_ParametersException("Parameter \"" + name + "\" not found");
        //            return std::numeric_limits<double>::quiet_NaN();
        
        return tables[name];
    }
    
    friend std::ostream& operator<< (std::ostream& os, const FAST_Parameters& p) {
        os << p.comment << std::endl;
        
        for(auto const &item : p.values) {
            os << item.first << ": " << item.second << std::endl;            
        }
        
        for(auto const &item : p.strings) {
            os << item.first << ": " << item.second << std::endl;            
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
    
protected:
    std::map<std::string, double> values;
    std::map<std::string, std::string> strings;
    std::map<std::string, std::vector<std::vector<double>>> tables;
    std::vector<std::string> filenames;
    
    std::filesystem::path path;
    std::string comment;
    
    static const std::array<std::string, 1> table_labels;
};

const std::array<std::string, 1> FAST_Parameters::table_labels= {"NKInpSt"};

#endif /* FAST_PARAMETERS_H_ */
