#include <string>
#include <map>
#include <fstream>
#include <iostream>
#include <stdlib.h>
#include <cstdio>
#include <Eigen/Dense>
#include <Eigen/Geometry>

/* File generated form template cadyn_direct_params.hpp.tem on 2023-08-04 11:03:26+02:00. Do not edit! */

/* Multibody system: Simulation of a simplified horizontal axis wind turbine */



class ParameterInfo {
public:
    ParameterInfo() :
        isSet(false),
        nrows(0),
        ncols(0),
        offset(0),
        data(nullptr)
        {}
        
    ParameterInfo(real_type *data_, int nrows_, int ncols_, int offset_) :
        isSet(false),
        nrows(nrows_),
        ncols(ncols_),
        offset(offset_),
        data(data_)
        {}

    bool setParam(const real_type *value);
    real_type getParam() const;
    void getParam(real_type *p) const;
    bool isSet;
    int nrows, ncols;
    int offset;
    
private:
    real_type *data;
};

bool ParameterInfo::setParam(const real_type *value) {
    bool wasSet= isSet;
    
    memcpy(data, value, sizeof(real_type)*nrows*ncols);
    isSet= true;
    return wasSet;
}

real_type ParameterInfo::getParam() const {
    return data[0];
}

void ParameterInfo::getParam(real_type *value) const {
    memcpy(value, data, sizeof(real_type)*nrows*ncols);
}

class turbine_T2B2cG_aeroParameters {
public:
    turbine_T2B2cG_aeroParameters();
    void setParam(const std::string &name, const real_type *value);
    real_type getParam(const std::string &name);
    void getParamArray(real_type *p);
    void setFromFile(const std::string &fileName);
    bool unsetParamsWithMsg();
    
    std::map<std::string, ParameterInfo> info_map;
    int unsetParams;
    
    real_type DTTorDmp;
    real_type DTTorSpr;
    real_type GBRatio;
    real_type GenIner;
    real_type HubCM;
    real_type HubIner;
    real_type HubMass;
    real_type NacCMxn;
    real_type NacCMyn;
    real_type NacCMzn;
    real_type NacMass;
    real_type NacXIner;
    real_type NacYIner;
    real_type OverHang;
    real_type Rrot;
    real_type TwTrans2Roll;
    real_type Twr2Shft;
    real_type blade_Cr0_1_1;
    real_type blade_Cr0_1_2;
    real_type blade_Cr0_2_1;
    real_type blade_Cr0_2_2;
    real_type blade_Ct0_1_1;
    real_type blade_Ct0_1_2;
    real_type blade_Ct0_2_1;
    real_type blade_Ct0_2_2;
    real_type blade_D0_1_1;
    real_type blade_D0_2_2;
    real_type blade_I0_1_1;
    real_type blade_I0_2_2;
    real_type blade_I0_3_3;
    real_type blade_I1_1_3_1;
    real_type blade_I1_1_3_2;
    real_type blade_I1_2_3_1;
    real_type blade_I1_2_3_2;
    real_type blade_K0_1_1;
    real_type blade_K0_1_2;
    real_type blade_K0_2_1;
    real_type blade_K0_2_2;
    real_type blade_Me0_1_1;
    real_type blade_Me0_1_2;
    real_type blade_Me0_2_1;
    real_type blade_Me0_2_2;
    real_type blade_Oe1_1_1_1;
    real_type blade_Oe1_1_1_2;
    real_type blade_Oe1_1_1_4;
    real_type blade_Oe1_1_2_1;
    real_type blade_Oe1_1_2_2;
    real_type blade_Oe1_1_2_4;
    real_type blade_Oe1_2_1_1;
    real_type blade_Oe1_2_1_2;
    real_type blade_Oe1_2_1_4;
    real_type blade_Oe1_2_2_1;
    real_type blade_Oe1_2_2_2;
    real_type blade_Oe1_2_2_4;
    real_type blade_frame_30_origin0_3_1;
    real_type blade_frame_30_origin1_1_1_1;
    real_type blade_frame_30_origin1_1_2_1;
    real_type blade_frame_30_origin1_2_1_1;
    real_type blade_frame_30_origin1_2_2_1;
    real_type blade_frame_30_psi0_1_1;
    real_type blade_frame_30_psi0_1_2;
    real_type blade_frame_30_psi0_2_1;
    real_type blade_frame_30_psi0_2_2;
    real_type blade_mass;
    real_type blade_md0_3_1;
    real_type blade_md1_1_1_1;
    real_type blade_md1_1_2_1;
    real_type blade_md1_2_1_1;
    real_type blade_md1_2_2_1;
    real_type cone;
    real_type g;
    real_type tower_Ct1_1_1_3;
    real_type tower_Ct1_2_2_3;
    real_type tower_D0_1_1;
    real_type tower_D0_2_2;
    real_type tower_K0_1_1;
    real_type tower_K0_2_2;
    real_type tower_Me0_1_1;
    real_type tower_Me0_2_2;
    real_type tower_frame_11_origin1_1_1_1;
    real_type tower_frame_11_origin1_2_2_1;
    real_type tower_frame_11_phi1_1_3_1;
    real_type tower_frame_11_phi1_2_3_2;
    real_type tower_frame_11_psi0_1_2;
    real_type tower_frame_11_psi0_2_1;
    real_type rho;
    real_type lambdaMin;
    real_type lambdaMax;
    real_type lambdaStep;
    real_type thetaMin;
    real_type thetaMax;
    real_type thetaStep;
    real_type Arot;
    Eigen::Matrix<real_type, 25, 91> cm_lut;
    Eigen::Matrix<real_type, 25, 91> ct_lut;
    Eigen::Matrix<real_type, 25, 91> cmy_D23_lut;
    Eigen::Matrix<real_type, 25, 91> cf_lut;
    Eigen::Matrix<real_type, 25, 91> ce_lut;
    Eigen::Matrix<real_type, 25, 91> dcm_dvf_v_lut;
    Eigen::Matrix<real_type, 25, 91> dcm_dve_v_lut;
    Eigen::Matrix<real_type, 25, 91> dct_dvf_v_lut;
    Eigen::Matrix<real_type, 25, 91> dct_dve_v_lut;
    Eigen::Matrix<real_type, 25, 91> dcs_dvy_v_lut;
    Eigen::Matrix<real_type, 25, 91> dcf_dvf_v_lut;
    Eigen::Matrix<real_type, 25, 91> dcf_dve_v_lut;
    Eigen::Matrix<real_type, 25, 91> dce_dvf_v_lut;
    Eigen::Matrix<real_type, 25, 91> dce_dve_v_lut;

};

turbine_T2B2cG_aeroParameters::turbine_T2B2cG_aeroParameters() :
    info_map(),
    unsetParams(107) {
    int offset= 0;
    info_map["DTTorDmp"]= ParameterInfo(&DTTorDmp, 1, 1, offset); offset+= 1;
    info_map["DTTorSpr"]= ParameterInfo(&DTTorSpr, 1, 1, offset); offset+= 1;
    info_map["GBRatio"]= ParameterInfo(&GBRatio, 1, 1, offset); offset+= 1;
    info_map["GenIner"]= ParameterInfo(&GenIner, 1, 1, offset); offset+= 1;
    info_map["HubCM"]= ParameterInfo(&HubCM, 1, 1, offset); offset+= 1;
    info_map["HubIner"]= ParameterInfo(&HubIner, 1, 1, offset); offset+= 1;
    info_map["HubMass"]= ParameterInfo(&HubMass, 1, 1, offset); offset+= 1;
    info_map["NacCMxn"]= ParameterInfo(&NacCMxn, 1, 1, offset); offset+= 1;
    info_map["NacCMyn"]= ParameterInfo(&NacCMyn, 1, 1, offset); offset+= 1;
    info_map["NacCMzn"]= ParameterInfo(&NacCMzn, 1, 1, offset); offset+= 1;
    info_map["NacMass"]= ParameterInfo(&NacMass, 1, 1, offset); offset+= 1;
    info_map["NacXIner"]= ParameterInfo(&NacXIner, 1, 1, offset); offset+= 1;
    info_map["NacYIner"]= ParameterInfo(&NacYIner, 1, 1, offset); offset+= 1;
    info_map["OverHang"]= ParameterInfo(&OverHang, 1, 1, offset); offset+= 1;
    info_map["Rrot"]= ParameterInfo(&Rrot, 1, 1, offset); offset+= 1;
    info_map["TwTrans2Roll"]= ParameterInfo(&TwTrans2Roll, 1, 1, offset); offset+= 1;
    info_map["Twr2Shft"]= ParameterInfo(&Twr2Shft, 1, 1, offset); offset+= 1;
    info_map["blade_Cr0_1_1"]= ParameterInfo(&blade_Cr0_1_1, 1, 1, offset); offset+= 1;
    info_map["blade_Cr0_1_2"]= ParameterInfo(&blade_Cr0_1_2, 1, 1, offset); offset+= 1;
    info_map["blade_Cr0_2_1"]= ParameterInfo(&blade_Cr0_2_1, 1, 1, offset); offset+= 1;
    info_map["blade_Cr0_2_2"]= ParameterInfo(&blade_Cr0_2_2, 1, 1, offset); offset+= 1;
    info_map["blade_Ct0_1_1"]= ParameterInfo(&blade_Ct0_1_1, 1, 1, offset); offset+= 1;
    info_map["blade_Ct0_1_2"]= ParameterInfo(&blade_Ct0_1_2, 1, 1, offset); offset+= 1;
    info_map["blade_Ct0_2_1"]= ParameterInfo(&blade_Ct0_2_1, 1, 1, offset); offset+= 1;
    info_map["blade_Ct0_2_2"]= ParameterInfo(&blade_Ct0_2_2, 1, 1, offset); offset+= 1;
    info_map["blade_D0_1_1"]= ParameterInfo(&blade_D0_1_1, 1, 1, offset); offset+= 1;
    info_map["blade_D0_2_2"]= ParameterInfo(&blade_D0_2_2, 1, 1, offset); offset+= 1;
    info_map["blade_I0_1_1"]= ParameterInfo(&blade_I0_1_1, 1, 1, offset); offset+= 1;
    info_map["blade_I0_2_2"]= ParameterInfo(&blade_I0_2_2, 1, 1, offset); offset+= 1;
    info_map["blade_I0_3_3"]= ParameterInfo(&blade_I0_3_3, 1, 1, offset); offset+= 1;
    info_map["blade_I1_1_3_1"]= ParameterInfo(&blade_I1_1_3_1, 1, 1, offset); offset+= 1;
    info_map["blade_I1_1_3_2"]= ParameterInfo(&blade_I1_1_3_2, 1, 1, offset); offset+= 1;
    info_map["blade_I1_2_3_1"]= ParameterInfo(&blade_I1_2_3_1, 1, 1, offset); offset+= 1;
    info_map["blade_I1_2_3_2"]= ParameterInfo(&blade_I1_2_3_2, 1, 1, offset); offset+= 1;
    info_map["blade_K0_1_1"]= ParameterInfo(&blade_K0_1_1, 1, 1, offset); offset+= 1;
    info_map["blade_K0_1_2"]= ParameterInfo(&blade_K0_1_2, 1, 1, offset); offset+= 1;
    info_map["blade_K0_2_1"]= ParameterInfo(&blade_K0_2_1, 1, 1, offset); offset+= 1;
    info_map["blade_K0_2_2"]= ParameterInfo(&blade_K0_2_2, 1, 1, offset); offset+= 1;
    info_map["blade_Me0_1_1"]= ParameterInfo(&blade_Me0_1_1, 1, 1, offset); offset+= 1;
    info_map["blade_Me0_1_2"]= ParameterInfo(&blade_Me0_1_2, 1, 1, offset); offset+= 1;
    info_map["blade_Me0_2_1"]= ParameterInfo(&blade_Me0_2_1, 1, 1, offset); offset+= 1;
    info_map["blade_Me0_2_2"]= ParameterInfo(&blade_Me0_2_2, 1, 1, offset); offset+= 1;
    info_map["blade_Oe1_1_1_1"]= ParameterInfo(&blade_Oe1_1_1_1, 1, 1, offset); offset+= 1;
    info_map["blade_Oe1_1_1_2"]= ParameterInfo(&blade_Oe1_1_1_2, 1, 1, offset); offset+= 1;
    info_map["blade_Oe1_1_1_4"]= ParameterInfo(&blade_Oe1_1_1_4, 1, 1, offset); offset+= 1;
    info_map["blade_Oe1_1_2_1"]= ParameterInfo(&blade_Oe1_1_2_1, 1, 1, offset); offset+= 1;
    info_map["blade_Oe1_1_2_2"]= ParameterInfo(&blade_Oe1_1_2_2, 1, 1, offset); offset+= 1;
    info_map["blade_Oe1_1_2_4"]= ParameterInfo(&blade_Oe1_1_2_4, 1, 1, offset); offset+= 1;
    info_map["blade_Oe1_2_1_1"]= ParameterInfo(&blade_Oe1_2_1_1, 1, 1, offset); offset+= 1;
    info_map["blade_Oe1_2_1_2"]= ParameterInfo(&blade_Oe1_2_1_2, 1, 1, offset); offset+= 1;
    info_map["blade_Oe1_2_1_4"]= ParameterInfo(&blade_Oe1_2_1_4, 1, 1, offset); offset+= 1;
    info_map["blade_Oe1_2_2_1"]= ParameterInfo(&blade_Oe1_2_2_1, 1, 1, offset); offset+= 1;
    info_map["blade_Oe1_2_2_2"]= ParameterInfo(&blade_Oe1_2_2_2, 1, 1, offset); offset+= 1;
    info_map["blade_Oe1_2_2_4"]= ParameterInfo(&blade_Oe1_2_2_4, 1, 1, offset); offset+= 1;
    info_map["blade_frame_30_origin0_3_1"]= ParameterInfo(&blade_frame_30_origin0_3_1, 1, 1, offset); offset+= 1;
    info_map["blade_frame_30_origin1_1_1_1"]= ParameterInfo(&blade_frame_30_origin1_1_1_1, 1, 1, offset); offset+= 1;
    info_map["blade_frame_30_origin1_1_2_1"]= ParameterInfo(&blade_frame_30_origin1_1_2_1, 1, 1, offset); offset+= 1;
    info_map["blade_frame_30_origin1_2_1_1"]= ParameterInfo(&blade_frame_30_origin1_2_1_1, 1, 1, offset); offset+= 1;
    info_map["blade_frame_30_origin1_2_2_1"]= ParameterInfo(&blade_frame_30_origin1_2_2_1, 1, 1, offset); offset+= 1;
    info_map["blade_frame_30_psi0_1_1"]= ParameterInfo(&blade_frame_30_psi0_1_1, 1, 1, offset); offset+= 1;
    info_map["blade_frame_30_psi0_1_2"]= ParameterInfo(&blade_frame_30_psi0_1_2, 1, 1, offset); offset+= 1;
    info_map["blade_frame_30_psi0_2_1"]= ParameterInfo(&blade_frame_30_psi0_2_1, 1, 1, offset); offset+= 1;
    info_map["blade_frame_30_psi0_2_2"]= ParameterInfo(&blade_frame_30_psi0_2_2, 1, 1, offset); offset+= 1;
    info_map["blade_mass"]= ParameterInfo(&blade_mass, 1, 1, offset); offset+= 1;
    info_map["blade_md0_3_1"]= ParameterInfo(&blade_md0_3_1, 1, 1, offset); offset+= 1;
    info_map["blade_md1_1_1_1"]= ParameterInfo(&blade_md1_1_1_1, 1, 1, offset); offset+= 1;
    info_map["blade_md1_1_2_1"]= ParameterInfo(&blade_md1_1_2_1, 1, 1, offset); offset+= 1;
    info_map["blade_md1_2_1_1"]= ParameterInfo(&blade_md1_2_1_1, 1, 1, offset); offset+= 1;
    info_map["blade_md1_2_2_1"]= ParameterInfo(&blade_md1_2_2_1, 1, 1, offset); offset+= 1;
    info_map["cone"]= ParameterInfo(&cone, 1, 1, offset); offset+= 1;
    info_map["g"]= ParameterInfo(&g, 1, 1, offset); offset+= 1;
    info_map["tower_Ct1_1_1_3"]= ParameterInfo(&tower_Ct1_1_1_3, 1, 1, offset); offset+= 1;
    info_map["tower_Ct1_2_2_3"]= ParameterInfo(&tower_Ct1_2_2_3, 1, 1, offset); offset+= 1;
    info_map["tower_D0_1_1"]= ParameterInfo(&tower_D0_1_1, 1, 1, offset); offset+= 1;
    info_map["tower_D0_2_2"]= ParameterInfo(&tower_D0_2_2, 1, 1, offset); offset+= 1;
    info_map["tower_K0_1_1"]= ParameterInfo(&tower_K0_1_1, 1, 1, offset); offset+= 1;
    info_map["tower_K0_2_2"]= ParameterInfo(&tower_K0_2_2, 1, 1, offset); offset+= 1;
    info_map["tower_Me0_1_1"]= ParameterInfo(&tower_Me0_1_1, 1, 1, offset); offset+= 1;
    info_map["tower_Me0_2_2"]= ParameterInfo(&tower_Me0_2_2, 1, 1, offset); offset+= 1;
    info_map["tower_frame_11_origin1_1_1_1"]= ParameterInfo(&tower_frame_11_origin1_1_1_1, 1, 1, offset); offset+= 1;
    info_map["tower_frame_11_origin1_2_2_1"]= ParameterInfo(&tower_frame_11_origin1_2_2_1, 1, 1, offset); offset+= 1;
    info_map["tower_frame_11_phi1_1_3_1"]= ParameterInfo(&tower_frame_11_phi1_1_3_1, 1, 1, offset); offset+= 1;
    info_map["tower_frame_11_phi1_2_3_2"]= ParameterInfo(&tower_frame_11_phi1_2_3_2, 1, 1, offset); offset+= 1;
    info_map["tower_frame_11_psi0_1_2"]= ParameterInfo(&tower_frame_11_psi0_1_2, 1, 1, offset); offset+= 1;
    info_map["tower_frame_11_psi0_2_1"]= ParameterInfo(&tower_frame_11_psi0_2_1, 1, 1, offset); offset+= 1;
    info_map["rho"]= ParameterInfo(&rho, 1, 1, offset); offset+= 1;
    info_map["lambdaMin"]= ParameterInfo(&lambdaMin, 1, 1, offset); offset+= 1;
    info_map["lambdaMax"]= ParameterInfo(&lambdaMax, 1, 1, offset); offset+= 1;
    info_map["lambdaStep"]= ParameterInfo(&lambdaStep, 1, 1, offset); offset+= 1;
    info_map["thetaMin"]= ParameterInfo(&thetaMin, 1, 1, offset); offset+= 1;
    info_map["thetaMax"]= ParameterInfo(&thetaMax, 1, 1, offset); offset+= 1;
    info_map["thetaStep"]= ParameterInfo(&thetaStep, 1, 1, offset); offset+= 1;
    info_map["Arot"]= ParameterInfo(&Arot, 1, 1, offset); offset+= 1;
    info_map["cm_lut"]= ParameterInfo(cm_lut.data(), 25, 91, offset); offset+= 25*91;
    info_map["ct_lut"]= ParameterInfo(ct_lut.data(), 25, 91, offset); offset+= 25*91;
    info_map["cmy_D23_lut"]= ParameterInfo(cmy_D23_lut.data(), 25, 91, offset); offset+= 25*91;
    info_map["cf_lut"]= ParameterInfo(cf_lut.data(), 25, 91, offset); offset+= 25*91;
    info_map["ce_lut"]= ParameterInfo(ce_lut.data(), 25, 91, offset); offset+= 25*91;
    info_map["dcm_dvf_v_lut"]= ParameterInfo(dcm_dvf_v_lut.data(), 25, 91, offset); offset+= 25*91;
    info_map["dcm_dve_v_lut"]= ParameterInfo(dcm_dve_v_lut.data(), 25, 91, offset); offset+= 25*91;
    info_map["dct_dvf_v_lut"]= ParameterInfo(dct_dvf_v_lut.data(), 25, 91, offset); offset+= 25*91;
    info_map["dct_dve_v_lut"]= ParameterInfo(dct_dve_v_lut.data(), 25, 91, offset); offset+= 25*91;
    info_map["dcs_dvy_v_lut"]= ParameterInfo(dcs_dvy_v_lut.data(), 25, 91, offset); offset+= 25*91;
    info_map["dcf_dvf_v_lut"]= ParameterInfo(dcf_dvf_v_lut.data(), 25, 91, offset); offset+= 25*91;
    info_map["dcf_dve_v_lut"]= ParameterInfo(dcf_dve_v_lut.data(), 25, 91, offset); offset+= 25*91;
    info_map["dce_dvf_v_lut"]= ParameterInfo(dce_dvf_v_lut.data(), 25, 91, offset); offset+= 25*91;
    info_map["dce_dve_v_lut"]= ParameterInfo(dce_dve_v_lut.data(), 25, 91, offset); offset+= 25*91;
}

void turbine_T2B2cG_aeroParameters::setParam(const std::string &name, const real_type *value) {
    auto it = info_map.find(name);
    if(it==info_map.end())    
        throw std::runtime_error("Unknown parameter \"" + name + "\".");
    
    if(!it->second.setParam(value))
        unsetParams--;
}

real_type turbine_T2B2cG_aeroParameters::getParam(const std::string &name) {
    auto it = info_map.find(name);
    if(it==info_map.end())    
        throw std::runtime_error("Unknown parameter \"" + name + "\".");
    
    return it->second.getParam();    
}

void turbine_T2B2cG_aeroParameters::setFromFile(const std::string &fileName) {
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
            if(it==info_map.end())    
                throw std::runtime_error("Unknown parameter \"" + paramName + "\".");
            
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
    
bool turbine_T2B2cG_aeroParameters::unsetParamsWithMsg() {
    if(unsetParams) {
        fprintf(stderr, "The following parameters are not set:\n");
        for(auto const &i : info_map) {
            if(!i.second.isSet)
                fprintf(stderr, "%s\n", i.first.c_str());
        }
    }
    
    return unsetParams;
}

void turbine_T2B2cG_aeroParameters::getParamArray(real_type *p) {
    for(auto const &i : info_map) {
        if(!i.second.isSet)
            throw std::runtime_error("Parameter \"" + i.first + "\" is not set.");
        
        i.second.getParam(&p[i.second.offset]);
    }    
}
