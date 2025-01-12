#ifndef FAST_WIND4_H_
#define FAST_WIND4_H_

#include "fast_wind0.h"

class FAST_Wind_Type4 : public FAST_Wind {
public:
    FAST_Wind_Type4(FAST_Parent_Parameters &p, double dx=0.0, bool with_shear= false, double avg_exp_=1.0) :
        FAST_Wind(p),
        wind(0),
        TimeStep(1.0),
        TurbFilename(""),
        avg_exp(avg_exp_),
        dx(dx),
        with_shear(with_shear)
    {
        if(p["InflowFile.WindType"]!=4)
            throw FAST_WindException("Trying to instantiate FAST_Wind_Type4 but parameter WindType is " + std::to_string(p["WindType"]));
        
        TurbFilename= p.getFilename("InflowFile.FilenameRoot");
        loadWindFile(TurbFilename);
    }
    
    virtual ~FAST_Wind_Type4() {}
    
    void loadWindFile(const std::string& Filename) {
		if(with_shear)
			throw FAST_WindException("Loading shear information from Bladed wind files currently not supported");
		
        double TipRad= p["EDFile.TipRad"];
		
		std::map<std::string, float> SumVars;
		SumVars["HUB HEIGHT"]= 0.0;
		SumVars["CLOCKWISE"]= 0.0;
		SumVars["UBAR"]= 0.0;
		SumVars["TI(U"]= 0.0;
		SumVars["TI(V"]= 0.0;
		SumVars["TI(W"]= 0.0;
		std::map<std::string, bool> SumVarsSet;
		
        std::ifstream infile(Filename + ".wnd", std::ios::in | std::ios::binary);
        if(!infile.is_open())
            throw FAST_WindException("Could not open Binary Bladed-style wind file \"" + Filename + ".wnd\"");
        
        infile.exceptions(std::ifstream::failbit | std::ifstream::badbit | std::ifstream::eofbit);

		float ConvFact = 1.0;  // results in meters and seconds

		//  READ THE HEADER OF THE BINARY FILE 
        int16_t nffc16;
        infile.read((char*)&nffc16, sizeof(int16_t)); // number of components
		int32_t nffc= nffc16;
		
		int32_t nt;
		float dx;
		
		if(nffc != -99) {  // AN OLD-STYLE AERODYN WIND FILE
			int16_t dz_i;
			infile.read((char*)&dz_i, sizeof(int16_t)); // delta z in mm
			int16_t dy_i;
			infile.read((char*)&dy_i, sizeof(int16_t)); // delta y in mm
			int16_t dx_i;
			infile.read((char*)&dx_i, sizeof(int16_t)); // delta x (actually t in this case) in mm
			int16_t nt16;
			infile.read((char*)&nt16, sizeof(int16_t)); // half number of time steps
			int16_t MFFWS_i;
			infile.read((char*)&MFFWS_i, sizeof(int16_t)); // 10 times mean FF wind speed, should be equal to MWS
			infile.ignore(5*sizeof(int16_t)); // unnecessary lines
			int16_t nz;
			infile.read((char*)&nz, sizeof(int16_t)); // 1000 times number of points in vertical direction, max 32
			int16_t ny;
			infile.read((char*)&ny, sizeof(int16_t)); // 1000 times the number of points in horizontal direction, max 32
			infile.ignore(3*(-nffc-1)*sizeof(int16_t)); // unnecessary lines

			// convert the integers to real numbers 
			nffc     = -nffc;
			dz       = 0.001*ConvFact*dz_i;
			dy       = 0.001*ConvFact*dy_i;
			dx       = 0.001*ConvFact*dx_i;
			u_hub    = 0.1*ConvFact*MFFWS_i;
			NumGrid_Z= nz/1000; // the MATLAB code has a modulo operation here. Let's hope this is not necessary
			NumGrid_Y= ny/1000; // the MATLAB code has a modulo operation here. Let's hope this is not necessary
			nt     = nt16;
		} else { //== -99, THE NEWER-STYLE AERODYN WIND FILE
			int16_t fc;
			infile.read((char*)&fc, sizeof(int16_t)); // should be 4 to allow turbulence intensity to be stored in the header

			float TI_U;
			float TI_V;
			float TI_W;
			if(fc == 4) {
				infile.read((char*)&nffc, sizeof(int32_t)); // number of components (should be 3)
				float lat;
				infile.read((char*)&lat, sizeof(float)); // latitude (deg)
				float z0;
				infile.read((char*)&z0, sizeof(float)); // Roughness length (m)
				float zOffset;
				infile.read((char*)&zOffset, sizeof(float)); // Reference height (m) = Z(1) + GridHeight / 2.0
				
				infile.read((char*)&TI_U, sizeof(float)); //  Turbulence Intensity of u component (%)
				infile.read((char*)&TI_V, sizeof(float)); // Turbulence Intensity of v component (%)
				infile.read((char*)&TI_W, sizeof(float)); // Turbulence Intensity of w component (%)
			} else {
				if(fc > 2)
					nffc = 3;
				else
					nffc = 1;
				
				TI_U  = 1.0;
				TI_V  = 1.0;
				TI_W  = 1.0;
				
				if(fc == 8) { // MANN model
					int32_t HeadRec;
					infile.read((char*)&HeadRec, sizeof(int32_t));
					int16_t tmp;
					infile.read((char*)&tmp, sizeof(int16_t));
				}
			} // %fc == 4
			
			infile.read((char*)&dz, sizeof(float)); // delta z in m
			infile.read((char*)&dy, sizeof(float)); // delta y in m
			infile.read((char*)&dx, sizeof(float)); // delta x in m
			infile.read((char*)&nt, sizeof(int32_t)); // half the number of time steps
			infile.read((char*)&u_hub, sizeof(float)); // mean full-field wind speed
			infile.ignore(3*sizeof(float));            // zLu, yLu, xLu: unused variables (for BLADED)
			infile.ignore(2*sizeof(int32_t)); // unused variables (for BLADED)
			infile.read((char*)&NumGrid_Z, sizeof(int32_t)); // number of points in vertical direction
			infile.read((char*)&NumGrid_Y, sizeof(int32_t)); // number of points in horizontal direction
			infile.ignore(3*(nffc-1)*sizeof(int32_t)); // other length scales: unused variables (for BLADED)                

			SumVars["UBAR"]= u_hub;
			SumVars["TI(U"]= TI_U;
			SumVars["TI(V"]= TI_V;
			SumVars["TI(W"]= TI_W;
			SumVarsSet["UBAR"]= true;
			SumVarsSet["TI(U"]= true;
			SumVarsSet["TI(V"]= true;
			SumVarsSet["TI(W"]= true;
			
			if(fc == 8) {
				float gamma;
				infile.read((char*)&gamma, sizeof(float)); // MANN model shear parameter
				float Scale;
				infile.read((char*)&Scale, sizeof(float)); // MANN model scale length
			}			
		} // old or new bladed styles

		nt *= 2;
		if(nt<1) nt= 1;
		float dt = dx/u_hub;
        TimeStep= dt;
		max_time= TimeStep*nt;
	
        wind.reserve(nt);
        // if(with_shear) {
            // h_shear.reserve(nt);
            // v_shear.reserve(nt);
        // }

		//  READ THE SUMMARY FILE FOR SCALING FACTORS
        std::ifstream sum_file(Filename + ".sum", std::ios::in);
        if(!sum_file.is_open())
            throw FAST_WindException("Could not open Binary Bladed-style summary file \"" + Filename + ".sum\"");
        
        sum_file.exceptions(std::ifstream::failbit | std::ifstream::badbit | std::ifstream::eofbit);

		std::string line;
		while (std::getline(sum_file, line) && !SumVarsSet.size()==6) {
			line = to_upper(line);

			// Find the first occurrence of '=' and set findx
			size_t findx = line.find("=");
			if(findx == std::string::npos) findx= 1;
			else findx++;

			// Set the last index of the line
			size_t lindx = line.length();

			// Iterate through SumVars
			for(std::map<std::string, float>::iterator iter = SumVars.begin(); iter != SumVars.end(); ++iter) {
				std::string sum_str = iter->first;
				size_t k = line.find(sum_str);
				if(k != std::string::npos) {
					SumVarsSet[sum_str]= true;

					// Check for comment character '%'
					size_t comment_pos = line.find("%");
					if (comment_pos != std::string::npos) {
						lindx = std::max(findx, comment_pos - 1);
					}

					// Extract token from line
					std::string tmp = strtok(line.substr(findx, lindx - findx + 1));

					// Process the extracted token
					if (!is_numeric(tmp)) {
						if (tmp[0] == 'T' || tmp[0] == 't') {
							SumVars[sum_str] = 1; // True
						} else {
							SumVars[sum_str] = -1; // False
						}
					} else {
						SumVars[sum_str] = std::stod(tmp);
					}
					break;
				}
			}
		} // while read file
	   
		double ZGoffset = 0.0;

		// read the rest of the file to get the grid height offset, if it's there
		while(std::getline(sum_file, line)) {
			line = to_upper(line);
			size_t findx = line.find("HEIGHT OFFSET");

			if(findx != std::string::npos) {
				size_t lindx = line.length();
				findx = line.find("=");
				if(findx == std::string::npos) findx= 1;
				else findx++;
				
				std::string tmp = strtok(line.substr(findx, lindx - findx + 1));
				ZGoffset = std::stod(tmp); // z grid offset
				break;
			}            
		}
		
		// READ THE GRID DATA FROM THE BINARY FILE
		double Scale_U = 0.00001*SumVars["UBAR"]*SumVars["TI(U"];
		// double Scale_V = 0.00001*SumVars["UBAR"]*SumVars["TI(V"];
		// double Scale_W = 0.00001*SumVars["UBAR"]*SumVars["TI(W"];
		double Offset_U= SumVars["UBAR"];
		HubHt = SumVars["HUB HEIGHT"];
		Z_bottom= HubHt - Z_bottom - 0.5*dz*((float)NumGrid_Z-1.0);

        int16_t v_grid_norm;
        double v_grid;
        double v_avg;
        double n_avg;
        double z_grid;
        double y_grid;
        for(int it= 0; it<nt; ++it) {
            v_avg= 0.0;
            n_avg= 0;
            for(int i_grid_z= 0; i_grid_z<NumGrid_Z; ++i_grid_z) {
                z_grid= Z_bottom + ((float)i_grid_z)*dz;
			
                for(int i_grid_y_= 0; i_grid_y_<NumGrid_Y; ++i_grid_y_) {
					int i_grid_y;
					if(SumVars["CLOCKWISE"]>0)
						i_grid_y= NumGrid_Y-i_grid_y_-1;
					else
						i_grid_y= i_grid_y_;
					
                    y_grid= -0.5*((float)NumGrid_Y-1.0)*dy + ((float)i_grid_y)*dy;
					
                    for(int uvw= 0; uvw<nffc; ++uvw) {
                        infile.read((char*)&v_grid_norm, sizeof(int16_t));
                        if(uvw==0) {
                            v_grid= ((float)v_grid_norm) * Scale_U + Offset_U;
                            
                            if(NumGrid_Z<4 || NumGrid_Y<4 || sqrt(pow(z_grid-HubHt, 2.0) + pow(y_grid, 2.0))<TipRad) {
                                v_avg+= pow(v_grid, avg_exp);
                                n_avg+= 1.0;
                            }
                        }
                    }
                }
            }
            wind.push_back(pow(v_avg/n_avg, 1.0/avg_exp));
            // if(with_shear) {
                // h_shear.push_back(0.5*((v22[1][0]-v22[0][0])/dy + (v22[1][1]-v22[0][1])/dy));
                // v_shear.push_back(0.5*((v22[0][1]-v22[0][0])/dz + (v22[1][1]-v22[1][0])/dz));
            // }
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
		// time= time + ((NumGrid_Y-1)*dy/2 + dx)/u_hub;
		time= time + dx/u_hub;
		
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

	// Convert a string to uppercase
	std::string to_upper(const std::string& str) {
		std::string result = str;
		std::transform(result.begin(), result.end(), result.begin(), ::toupper);
		return result;
	}

	// Split a string by whitespace and return the first token
	std::string strtok(const std::string& str) {
		size_t first_non_space = str.find_first_not_of(" \t\n\r");
		if (first_non_space == std::string::npos) return "";

		size_t end = str.find_first_of(" \t\n\r", first_non_space);
		return str.substr(first_non_space, end - first_non_space);
	}

	// Check if a string can be converted to a number
	bool is_numeric(const std::string& str) {
		char* end;
		std::strtod(str.c_str(), &end);
		return *end == '\0';
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
    double max_time;
};

#endif /* FAST_WIND4_H_ */