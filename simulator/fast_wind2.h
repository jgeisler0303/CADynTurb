#ifndef FAST_WIND2_H_
#define FAST_WIND2_H_

#include "fast_wind0.h"

class FAST_Wind_Type2 : public FAST_Wind {
public:
    FAST_Wind_Type2(FAST_Parent_Parameters &p) :
        FAST_Wind(p),
        wind(0)
    {
        if(p["InflowFile.WindType"]!=2)
            throw FAST_WindException("Trying to instantiate FAST_Wind_Type2 but parameter WindType is " + std::to_string(p["WindType"]));
        
        loadWindTable(p.getFilename("InflowFile.Filename_Uni"));
        
        RefHt= p["InflowFile.RefHt"];
        RefLength= p["InflowFile.RefLength"];
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

#endif /* FAST_WIND2_H_ */
