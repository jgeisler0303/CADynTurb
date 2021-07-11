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
#include <algorithm>
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
    FAST_Parameters(const std::string& file_name, bool with_exception= true) :
        values(),
        path(file_name),
        comment()
    {
        // std::setlocale(LC_NUMERIC, "en_US.UTF-8");
        
        std::ifstream infile(file_name);
        if(!infile.is_open()) {
            if(with_exception)
                throw FAST_ParametersException("Could not open parameter file \"" + file_name + "\"");
            else
                return;
        }
        
        path= path.remove_filename();
        if(path.empty()) path= "./";
        
        std::string line;
        std::string ulabel;
        std::string value;
        bool comment_set= false;
        int table_lines= 0;
        int table_line= 0;
        bool files_list= false;
        while (getline(infile, line)) {
            if(line.empty()) continue;
            if((line.length()>1 && line[0]=='-' && line[1]=='-') || line[0]=='!' || line[0]=='=') continue;
            
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
                    
                    if(files_list) {
                        iss >> value;
                        if(value[0]=='"') value= value.substr(1);
                        if(value.length()>0 && value.back()=='"') value= value.substr(0, value.length()-1);
                        
                        std::filesystem::path fpath= value;
                        if(fpath.is_relative()) {
                            fpath= path;
                            fpath+= value;
                        }
                
                        filenames.push_back(fpath.string());
                    } else {
                        while(iss) {
                            iss >> value;
                            try {
                                double v= std::stod(value);

                                tables[ulabel][table_line].push_back(v);
                            } catch (const std::exception& e) {
                                break;
                            }
                        }
                    }
                    continue;
                } else
                    table_lines= 0;
            }
            
            std::istringstream iss(line);
            iss >> value >> ulabel;
            std::transform(ulabel.begin(), ulabel.end(), ulabel.begin(), ::toupper);

            
            if(value.empty() || ulabel.empty()) continue;
            if(value=="OutList") break;
            
            if(ulabel=="PITCHHAXIS") {
                ulabel= "BLINNST";
                table_lines= values.at("NBLINPST");
                tables[ulabel].resize(table_lines);
                table_line= -2;
                files_list= false;
                continue;
            }
            if(ulabel=="TMASSDEN") {
                ulabel= "TWINPST";
                table_lines= values.at("NTWINPST");
                tables[ulabel].resize(table_lines);
                table_line= -2;
                files_list= false;
                continue;
            }
            
            if(ulabel=="FILENAME") {
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
                values[ulabel]= 1.0;
                continue;
            }
            if(value[0]=='f' || value[0]=='F') {
                values[ulabel]= 0.0;
                continue;
            }
            
            try {
                double v= std::stod(value);
                
                values[ulabel]= v;
                
                if(ulabel[0]=='N') ulabel= ulabel.substr(1);
                if(ulabel[0]=='U') ulabel= ulabel.substr(1);
                if(ulabel[0]=='M') ulabel= ulabel.substr(1);
                for(auto const &item : table_labels) {
                    if(ulabel==item.first) {
                        tables[ulabel].resize(v);
                        
                        table_lines= v;
                        table_line= item.second;
                        files_list= false;

                        break;
                    }
                }
                for(int i= 0; i<vector_labels.size(); ++i) {
                    if(ulabel==vector_labels[i]) {
                        tables[ulabel].resize(1);
                        
                        table_lines= 1;
                        table_line= -1;
                        files_list= false;
                        
                        break;
                    }
                }
                for(int i= 0; i<files_labels.size(); ++i) {
                    if(ulabel==files_labels[i]) {
                        table_lines= v;
                        table_line= -1;
                        files_list= true;
                        
                        break;
                    }
                }
            } catch (const std::exception& e) {
            }
            if(value[0]=='"') value= value.substr(1);
            if(value.length()>0 && value.back()=='"') value= value.substr(0, value.length()-1);
            
            strings[ulabel]= value;
        }
    }
    
    double operator[](const std::string &name) {
        std::string uname= name;
        std::transform(uname.begin(), uname.end(), uname.begin(), ::toupper);
        
        if(values.find(uname)==values.end())
            throw FAST_ParametersException("Parameter \"" + name + "\" not found");
//            return std::numeric_limits<double>::quiet_NaN();
        
        return values[uname];
    }
    
    const std::string &getString(const std::string &name) {
        std::string uname= name;
        std::transform(uname.begin(), uname.end(), uname.begin(), ::toupper);
        
        if(strings.find(uname)==strings.end())
            throw FAST_ParametersException("Parameter \"" + name + "\" not found");
        //            return std::numeric_limits<double>::quiet_NaN();
        
        return strings[uname];
    }
    
    const std::string &getFilename(int idx) {
        if(filenames.size()<=idx)
            throw FAST_ParametersException("Filename index too high");
        
        return filenames[idx];
    }
    
    std::string getFilename(const std::string &name) {
        std::string value= getString(name);
        std::filesystem::path fpath= value;
        if(fpath.is_relative()) {
            fpath= path;
            fpath+= value;
        }
        return fpath.string();
    }

    const std::vector<std::vector<double>> &getTable(const std::string &name) {
        std::string uname= name;
        std::transform(uname.begin(), uname.end(), uname.begin(), ::toupper);
        if(tables.find(uname)==tables.end())
            throw FAST_ParametersException("Parameter \"" + name + "\" not found");
        //            return std::numeric_limits<double>::quiet_NaN();
        
        return tables[uname];
    }
    
    friend std::ostream& operator<< (std::ostream& os, const FAST_Parameters& p) {
        os << p.comment << std::endl;
        
//         for(auto const &item : p.values) {
//             os << item.first << ": " << item.second << std::endl;            
//         }
        
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
    
    static const std::map<std::string, int> table_labels;
    static const std::vector<std::string> vector_labels;
    static const std::vector<std::string> files_labels;
};

const std::map<std::string, int> FAST_Parameters::table_labels= {{"KINPST", -3}, {"TWRNDS", -3}, {"KP_TOTAL", -4}, {"BLNDS", -3}};
const std::vector<std::string> FAST_Parameters::files_labels= {"AFFILES"};
const std::vector<std::string> FAST_Parameters::vector_labels= {"LINTIMES", "BLOUTS", "TWOUTS", "NODEOUTS", "BLGAGES", "TWGAGES"};

#endif /* FAST_PARAMETERS_H_ */
