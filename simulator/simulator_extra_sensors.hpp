#ifndef EXTRASENSORS_H_
#define EXTRASENSORS_H_

#define has_(MEMBER)                                                                          \
    template <typename T, typename = void>                                              \
    struct has_##MEMBER : std::false_type {};                                     \
    template <typename T>                                                               \
    struct has_##MEMBER<T, std::void_t<decltype(T::MEMBER)>> : std::true_type {};

has_(phi_gen)
has_(phi_gen_d)
has_(tow_fa_dd)
has_(tow_ss_dd)
has_(theta1)
has_(h_shear)
has_(Trot1)

template<class T>
class ExtraSensors {
public:
    ExtraSensors(FAST_Output &out, T &system) {
        out.addChannel("RotPwr", "kW", &RotPwr, 1.0/1000.0);
        out.addChannel("LSSTipPxa", "deg", &LSSTipPxa, 180.0/M_PI);        
        
        if constexpr ( has_phi_gen_d<typename T::states_t>::value ) {
            out.addChannel("HSShftPwr", "kW", &HSShftPwr, 1.0/1000.0);
            out.addChannel("QD_DrTr", "rad/s", &QD_DrTr);  
        }
        
        if constexpr ( has_phi_gen<typename T::states_t>::value ) {
            out.addChannel("Q_DrTr", "rad", &Q_DrTr);
            out.addChannel("Q_GeAz", "rad", &Q_GeAz);
        }
    }
    
    void update(T &system) {
        if constexpr ( has_Trot1<T>::value )
            RotPwr= (system.Trot1+system.Trot2+system.Trot3)*system.states.phi_rot_d;
        else
            RotPwr= system.Trot*system.states.phi_rot_d;
        
        LSSTipPxa= std::fmod(system.states.phi_rot, 2*M_PI);        

        if constexpr ( has_phi_gen_d<typename T::states_t>::value ) {
            HSShftPwr= system.inputs.Tgen*system.states.phi_gen_d;
            QD_DrTr= system.states.phi_rot_d - system.states.phi_gen_d/system.param.GBRatio;
        }
        
        if constexpr ( has_phi_gen<typename T::states_t>::value ) {
            Q_DrTr= system.states.phi_rot - system.states.phi_gen/system.param.GBRatio;
            Q_GeAz= std::fmod(system.states.phi_gen/system.param.GBRatio+M_PI*3.0/2.0, 2*M_PI);
        }
    }
    
    real_type RotPwr;
    real_type HSShftPwr;
    real_type Q_DrTr;
    real_type QD_DrTr;
    real_type Q_GeAz;
    real_type LSSTipPxa;
};


#endif /* EXTRASENSORS_H_ */
