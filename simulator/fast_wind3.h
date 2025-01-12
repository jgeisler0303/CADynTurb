#ifndef FAST_WIND3_H_
#define FAST_WIND3_H_

#include "fast_wind0.h"

class FAST_Wind_Type3 : public FAST_Wind {
public:
    FAST_Wind_Type3(FAST_Parent_Parameters &p, double dx=0.0, bool with_shear= false, double avg_exp_=3.0) :
        FAST_Wind(p),
        wind(0),
        TimeStep(1.0),
        TurbFilename(""),
        avg_exp(avg_exp_),
        dx(dx),
        with_shear(with_shear)
    {
        if(p["InflowFile.WindType"]!=3)
            throw FAST_WindException("Trying to instantiate FAST_Wind_Type3 but parameter WindType is " + std::to_string(p["WindType"]));
        
        TurbFilename= p.getFilename("InflowFile.Filename_BTS");
        if(with_shear) {
            TurbFilename.erase(TurbFilename.length()-4);
            TurbFilename+= "_shear.bts";
            avg_exp= 1.0;
        }
            
        loadWindFile(TurbFilename);
    }
    
    virtual ~FAST_Wind_Type3() {}
    
    void loadWindFile(const std::string& Filename) {
        double TipRad= p["EDFile.TipRad"];
        
        std::ifstream infile(Filename, std::ios::in | std::ios::binary);
        if(!infile.is_open())
            throw FAST_WindException("Could not open TurbSim wind file \"" + Filename + "\"");
        
        infile.exceptions(std::ifstream::failbit | std::ifstream::badbit | std::ifstream::eofbit);
        
        int16_t ID;
        infile.read((char*)&ID, sizeof(int16_t));
        is_periodic= ID==8;
        if(ID!=7 && ID!=8)
            throw FAST_WindException("TurbSim wind file \"" + Filename + "\" has ID " + std::to_string(ID) + " but should be 7 or 8");
        
        
        infile.read((char*)&NumGrid_Z, sizeof(int32_t));
        infile.read((char*)&NumGrid_Y, sizeof(int32_t));
        
        if(with_shear && NumGrid_Z!=2 && NumGrid_Z!=2)
            throw FAST_WindException("TurbSim wind file \"" + Filename + "\" must have a grid of 2x2 to read shear data");
        
        int32_t n_tower;
        infile.read((char*)&n_tower, sizeof(int32_t));
        
        int32_t nt;
        infile.read((char*)&nt, sizeof(int32_t));
        max_time= nt*TimeStep;
        
        wind.reserve(nt);
        if(with_shear) {
            h_shear.reserve(nt);
            v_shear.reserve(nt);
        }
        
        infile.read((char*)&dz, sizeof(float));
        infile.read((char*)&dy, sizeof(float));

        float fTimeStep;
        infile.read((char*)&fTimeStep, sizeof(float));
        TimeStep= fTimeStep;
        
        infile.read((char*)&u_hub, sizeof(float));
        infile.read((char*)&HubHt, sizeof(float));
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
        
//         std::cout << "TipRad: " << TipRad << std::endl;
//         std::cout << "ID: " << ID << std::endl;
//         std::cout << "NumGrid_Z: " << NumGrid_Z << std::endl;
//         std::cout << "NumGrid_Y: " << NumGrid_Y << std::endl;
//         std::cout << "n_tower: " << n_tower << std::endl;
//         std::cout << "nt: " << nt << std::endl;
//         std::cout << "dz: " << dz << std::endl;
//         std::cout << "dy: " << dy << std::endl;
//         std::cout << "TimeStep: " << TimeStep << std::endl;
//         std::cout << "u_hub: " << u_hub << std::endl;
//         std::cout << "HubHt: " << HubHt << std::endl;
//         std::cout << "Z_bottom: " << Z_bottom << std::endl;
//         std::cout << "V_slope: " << V_slope[0] << " " << V_slope[1] << " "<< V_slope[2] << std::endl;
//         std::cout << "V_intercept: " << V_intercept[0] << " " << V_intercept[1] << " "<< V_intercept[2] << std::endl;
//         std::cout << "comment: " << comment << std::endl;
        
        int16_t v_grid_norm;
        double v_grid;
        double v_avg;
        double n_avg;
        double z_grid;
        double y_grid;
        double v22[2][2];
        for(int it= 0; it<nt; ++it) {
            v_avg= 0.0;
            n_avg= 0;
            for(int i_grid_z= 0; i_grid_z<NumGrid_Z; ++i_grid_z) {
                z_grid= Z_bottom + ((float)i_grid_z)*dz;
                for(int i_grid_y= 0; i_grid_y<NumGrid_Y; ++i_grid_y) {
                    y_grid= -0.5*((float)NumGrid_Y-1.0)*dy + ((float)i_grid_y)*dy;
                    for(int uvw= 0; uvw<3; ++uvw) {
                        infile.read((char*)&v_grid_norm, sizeof(int16_t));
                        if(uvw==0) {
                            v_grid= ((float)v_grid_norm - V_intercept[uvw]) / V_slope[uvw];
                            
                            if(NumGrid_Z<4 || NumGrid_Y<4 || sqrt(pow(z_grid-HubHt, 2.0) + pow(y_grid, 2.0))<TipRad) {
                                v_avg+= pow(v_grid, avg_exp);
                                n_avg+= 1.0;
                            }
                            if(with_shear && i_grid_y<2 && i_grid_z<2)
                                v22[i_grid_y][i_grid_z]= v_grid;
                            
//                             if(it==0 && ((i_grid_z==0 && i_grid_y==0) || (i_grid_z==NumGrid_Z-1 && i_grid_y==0) || (i_grid_z==0 && i_grid_y==NumGrid_Y-1) || (i_grid_z==NumGrid_Z-1 && i_grid_y==NumGrid_Y-1))) {
//                                 std::cout << "z_grid: " << z_grid << std::endl;
//                                 std::cout << "y_grid: " << y_grid << std::endl;
//                                 std::cout << "v_grid: " << v_grid << std::endl;                                
//                             }
                        }
                    }
                }
            }
            for(int i_tower= 0; i_tower<n_tower; ++i_tower) {
                for(int uvw= 0; uvw<3; ++uvw) {
                    infile.read((char*)&v_grid_norm, sizeof(int16_t));
                }
            }
            
//             if(it<3) {             
//                 std::cout << "pow(v_avg/n_avg, 1.0/avg_exp): " << pow(v_avg/n_avg, 1.0/avg_exp) << std::endl;
//                 std::cout << "v_avg: " << v_avg << std::endl;
//                 std::cout << "n_avg: " << n_avg << std::endl;
//             }
            wind.push_back(pow(v_avg/n_avg, 1.0/avg_exp));
            if(with_shear) {
                h_shear.push_back(0.5*((v22[1][0]-v22[0][0])/dy + (v22[1][1]-v22[0][1])/dy));
                v_shear.push_back(0.5*((v22[0][1]-v22[0][0])/dz + (v22[1][1]-v22[1][0])/dz));
            }
        }
    }
    
    void writeWind2File(const std::string& Filename) {
        std::ofstream outfile(Filename);
        
        outfile << "! Averaged u-wind from file \"" << TurbFilename << "\", avaerging exponent " << avg_exp << std::endl;
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
        if(!is_periodic) {
            // if(time<0.1) std::cout << "((NumGrid_Y-1)*dy/2 + dx)/u_hub=" << ((NumGrid_Y-1)*dy/2 + dx)/u_hub << std::endl;
            time= time + ((NumGrid_Y-1)*dy/2 + dx)/u_hub;
        }
        time= std::fmod(time, 2*max_time);
        if(time>max_time) time= 2*max_time - time;
        
        double TimeScaled= time/TimeStep;
        int idx= std::floor(TimeScaled);
        
        if(idx<0) return wind[0];
        if(idx>=(wind.size()-1)) return wind.back();
        
        double TimeFact= TimeScaled - idx;
        
        return (1.0-TimeFact)*wind[idx] + TimeFact*wind[idx+1];
    }
    
    virtual void getShear(double time, double &h_shear_val, double &v_shear_val) {
        if(!with_shear) {
            h_shear_val= 0.0;
            v_shear_val= 0.0;
            return;
        }
        
        if(!is_periodic) {
            // if(time<0.1) std::cout << "((NumGrid_Y-1)*dy/2 + dx)/u_hub=" << ((NumGrid_Y-1)*dy/2 + dx)/u_hub << std::endl;
            time= time + ((NumGrid_Y-1)*dy/2 + dx)/u_hub;
        }
        time= std::fmod(time, 2*max_time);
        if(time>max_time) time= 2*max_time - time;
        
        double TimeScaled= time/TimeStep;
        int idx= std::floor(TimeScaled);
        
        if(idx<0) {
            h_shear_val= h_shear[0];
            v_shear_val= v_shear[0];
            return;
        }
        if(idx>=(wind.size()-1)) {
            h_shear_val= h_shear.back();
            v_shear_val= v_shear.back();
            return;
        }
        
        double TimeFact= TimeScaled - idx;
        
        h_shear_val= (1.0-TimeFact)*h_shear[idx] + TimeFact*h_shear[idx+1];
        v_shear_val= (1.0-TimeFact)*v_shear[idx] + TimeFact*v_shear[idx+1];        
    }
    
protected:
    std::vector<double> wind;
    std::vector<double> h_shear;
    std::vector<double> v_shear;
    double TimeStep;
    std::string TurbFilename;
    double avg_exp;
    double dx;
    bool with_shear;
    
    int32_t NumGrid_Z;
    int32_t NumGrid_Y;
    float dz;
    float dy;
    float u_hub;
    float HubHt;
    float Z_bottom;
    bool is_periodic;
    double max_time;
};

#endif /* FAST_WIND3_H_ */