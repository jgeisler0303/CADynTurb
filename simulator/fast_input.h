#ifndef FAST_INPUT_H_
#define FAST_INPUT_H_

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
#include <algorithm> 
#include <cctype>
#include <locale>

// trim from end (in place)
static inline void rtrim(std::string &s) {
    s.erase(std::find_if(s.rbegin(), s.rend(), [](unsigned char ch) {
        return !std::isspace(ch);
    }).base(), s.end());
}

class FAST_InputException: public std::exception {
public:
    FAST_InputException(const std::string& msg= "Abstract FAST intput exception") :
        m_msg(msg)
    {  }
    
    virtual const char* what() const throw () {
        return m_msg.c_str();
    }
    
    const std::string m_msg;
};



class FAST_Input {
public:
    FAST_Input(const std::string& file_name):
        NumOutChans(0),
        NT(0),
        TimeOut(0.0),
        TimeIncr(0.0),
        FileID(0)
    {
        read(file_name);
    }
    
    void read(const std::string &fname) {
        std::ifstream in(fname, std::ios::in | std::ios::binary);
        
        if(!in.good())
            throw FAST_InputException("Error opening inputfile \"" + fname + "\"");
        
        in.read((char*)&FileID, sizeof(int16_t));
        
        int16_t LenName;
        if(FileID == 4) // FileFmtID.ChanLen_In
            in.read((char*)&LenName, sizeof(int16_t)); // Number of characters in channel names and units
        else
            LenName = 10; // default number of characters per channel name
        
        in.read((char*)&NumOutChans, sizeof(int32_t));
        
        in.read((char*)&NT, sizeof(int32_t));
        
        
        double TimeScl;
        double TimeOff;
        if(FileID == 1) { // FileFmtID.WithTime
            in.read((char*)&TimeScl, sizeof(double));
            in.read((char*)&TimeOff, sizeof(double));
        } else {
            in.read((char*)&TimeOut, sizeof(double));
            in.read((char*)&TimeIncr, sizeof(double));
        }
        
        std::vector<float> ColScl(NumOutChans);
        std::vector<float> ColOff(NumOutChans);
        if(FileID != 3) { // ! FileFmtID.NoCompressWithoutTime
            in.read((char*)&ColScl[0], NumOutChans*sizeof(float));
            in.read((char*)&ColOff[0], NumOutChans*sizeof(float));
        }
        
        int32_t LenDesc;
        in.read((char*)&LenDesc, sizeof(int32_t));
        
        comment.resize(LenDesc);
        in.read(&comment[0], LenDesc*sizeof(char));
        rtrim(comment);
        
        std::vector<std::string> ChanNames(NumOutChans+1);
        for(int i= 0; i<=NumOutChans; ++i) {
            std::string ChanName(LenName, ' ');
            in.read(&ChanName[0], LenName);
            rtrim(ChanName);
            ChanNames[i]= ChanName;
            if(i>0) // first is always time
                data.insert(std::pair<std::string, std::vector<double> >(ChanNames[i], std::vector<double>(NT)));
        }
        
        for(int i= 0; i<=NumOutChans; ++i) {
            std::string ChanUnit(LenName, ' ');
            in.read(&ChanUnit[0], LenName);
            rtrim(ChanUnit);
            units[ChanNames[i]]= ChanUnit;
        }
        
        time.resize(NT);
        if(FileID == 1) { // FileFmtID.WithTime
            std::vector<int32_t> PackedTime(NT);
            in.read((char*)&PackedTime.data()[0], NT*sizeof(int32_t));
            
            for(int i= 0; i<NT; ++i)
                time[i]= (PackedTime[i] - TimeOff) / TimeScl;
        } else {
            for(int i= 0; i<NT; ++i)
                time[i]= TimeOut + TimeIncr*i;
        }
            
        int32_t nPts= NT*NumOutChans; // number of data points in the file   
        if(FileID == 3) { // FileFmtID.NoCompressWithoutTime
            std::vector<double> data_(nPts);
            in.read((char*)&data_[0], nPts*sizeof(double));
            
            for(int i_chan= 0; i_chan<NumOutChans; ++i_chan) {
                for(int i_t= 0; i_t<NT; ++i_t) {
                    data[ChanNames[i_chan+1]][i_t]= data_[i_chan + i_t*NumOutChans];
                }
            }
        } else {
            std::vector<int16_t> PackedData(nPts);
            in.read((char*)&PackedData[0], nPts*sizeof(int16_t));
            
            for(int i_chan= 0; i_chan<NumOutChans; ++i_chan) {
                for(int i_t= 0; i_t<NT; ++i_t) {
                    data[ChanNames[i_chan+1]][i_t]= (PackedData[i_chan + i_t*NumOutChans] - ColOff[i_chan])/ColScl[i_chan];
                }
            }
        }
        
        in.close();
    }

    std::string comment;
    std::vector<double> time;
    std::map<std::string, std::vector<double>> data;
    std::map<std::string, std::string> units;
    
    int32_t NumOutChans;
    int32_t NT;
    double TimeOut;
    double TimeIncr;
    int16_t FileID;
};


#endif /* FAST_INPUT_H_ */
