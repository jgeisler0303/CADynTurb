#ifndef STANDARDSENSORS_H_
#define STANDARDSENSORS_H_

#include <type_traits>

// Macro overloading example
// #define FOO1(a) func1(a)
// #define FOO2(a, b) func2(a, b)
// #define FOO3(a, b, c) func3(a, b, c)
// 
// #define EXPAND(x) x
// #define GET_MACRO(_1, _2, _3, NAME, ...) NAME
// #define FOO(...) EXPAND(GET_MACRO(__VA_ARGS__, FOO3, FOO2, FOO1)(__VA_ARGS__))

    
#define LIST_OF_SENSORS(MACRO)                                                                                                  \
    MACRO(Q_BF1, states, bld_flp,   { out.addChannel("Q_BF1", "m", &system.states.bld_flp); } )                                 \
    MACRO(Q_B1F1, states, bld1_flp,   { out.addChannel("Q_B1F1", "m", &system.states.bld1_flp); } )                             \
    MACRO(Q_B2F1, states, bld2_flp,   { out.addChannel("Q_B2F1", "m", &system.states.bld2_flp); } )                             \
    MACRO(Q_B3F1, states, bld3_flp,   { out.addChannel("Q_B3F1", "m", &system.states.bld3_flp); } )                             \
    MACRO(Q_BE1, states, bld_edg,  { out.addChannel("Q_BE1", "m", &system.states.bld_edg); } )                                  \
    MACRO(Q_B1E1, states, bld1_edg,  { out.addChannel("Q_B1E1", "m", &system.states.bld1_edg); } )                              \
    MACRO(Q_B2E1, states, bld2_edg,  { out.addChannel("Q_B2E1", "m", &system.states.bld2_edg); } )                              \
    MACRO(Q_B3E1, states, bld3_edg,  { out.addChannel("Q_B3E1", "m", &system.states.bld3_edg); } )                              \
    MACRO(QD_BF1, states, bld_flp_d,  { out.addChannel("QD_BF1", "m/s", &system.states.bld_flp_d); } )                          \
    MACRO(QD_B1F1, states, bld1_flp_d,  { out.addChannel("QD_B1F1", "m/s", &system.states.bld1_flp_d); } )                      \
    MACRO(QD_B2F1, states, bld2_flp_d,  { out.addChannel("QD_B2F1", "m/s", &system.states.bld2_flp_d); } )                      \
    MACRO(QD_B3F1, states, bld3_flp_d,  { out.addChannel("QD_B3F1", "m/s", &system.states.bld3_flp_d); } )                      \
    MACRO(QD_BE1, states, bld_edg_d,  { out.addChannel("QD_BE1", "m/s", &system.states.bld_edg_d); } )                          \
    MACRO(QD_B1E1, states, bld1_edg_d,  { out.addChannel("QD_B1E1", "m/s", &system.states.bld1_edg_d); } )                      \
    MACRO(QD_B2E1, states, bld2_edg_d,  { out.addChannel("QD_B2E1", "m/s", &system.states.bld2_edg_d); } )                      \
    MACRO(QD_B3E1, states, bld3_edg_d,  { out.addChannel("QD_B3E1", "m/s", &system.states.bld3_edg_d); } )                      \
    MACRO(PtchPMzc, states, theta_deg,  { out.addChannel("PtchPMzc", "deg", &system.theta_deg); } )                             \
    MACRO(PtchPMzc1, states, theta_deg1,  { out.addChannel("PtchPMzc1", "deg", &system.theta_deg1); } )                         \
    MACRO(PtchPMzc2, states, theta_deg2,  { out.addChannel("PtchPMzc2", "deg", &system.theta_deg2); } )                         \
    MACRO(PtchPMzc3, states, theta_deg3,  { out.addChannel("PtchPMzc3", "deg", &system.theta_deg3); } )                         \
    MACRO(LSSTipVxa, states, phi_rot_d,  { out.addChannel("LSSTipVxa", "rpm", &system.states.phi_rot_d, 30.0/M_PI); } )         \
    MACRO(LSSTipAxa, states, phi_rot_dd,  { out.addChannel("LSSTipAxa", "deg/s^2", &system.states.phi_rot_dd, 180.0/M_PI); } )  \
    MACRO(HSShftV, states, phi_gen_d,  { out.addChannel("HSShftV", "rpm", &system.states.phi_gen_d, 30.0/M_PI); } )             \
    MACRO(HSShftA, states, phi_gen_dd,  { out.addChannel("HSShftA", "deg/s^2", &system.states.phi_gen_dd, 180.0/M_PI); } )      \
    MACRO(YawBrTDxp, states, tow_fa,  { out.addChannel("YawBrTDxp", "m", &system.states.tow_fa);                                \
                            out.addChannel("Q_TFA1", "m", &system.states.tow_fa); } )                                           \
    MACRO(YawBrTDyp, states, tow_ss,  { out.addChannel("YawBrTDyp", "m", &system.states.tow_ss);                                \
                            out.addChannel("Q_TSS1", "m", &system.states.tow_ss, -1.0); } )                                     \
    MACRO(YawBrTVxp, states, tow_fa_d,  { out.addChannel("YawBrTVxp", "m/s", &system.states.tow_fa_d);                          \
                            out.addChannel("QD_TFA1", "m/s", &system.states.tow_fa_d); } )                                      \
    MACRO(YawBrTVyp, states, tow_ss_d,  { out.addChannel("YawBrTVyp", "m/s", &system.states.tow_ss_d);                          \
                            out.addChannel("QD_TSS1", "m/s", &system.states.tow_ss_d, -1.0); } )                                \
    MACRO(YawBrTAxp, states, tow_fa_dd,  { out.addChannel("YawBrTAxp", "m/s^2", &system.states.tow_fa_dd); } )                  \
    MACRO(YawBrTAyp, states, tow_ss_dd,  { out.addChannel("YawBrTAyp", "m/s^2", &system.states.tow_ss_dd); } )                  \
    MACRO(RootFxc, states, Fthrust,  { out.addChannel("RootFxc", "kN", &system.Fthrust, 1.0/3000.0);                            \
                            out.addChannel("LSShftFxa", "kN", &system.Fthrust, 1.0/1000.0); } )                                 \
    MACRO(RootFxc1, states, Fthrust1,  { out.addChannel("RootFxc1", "kN", &system.Fthrust1, 1.0/3000.0); } )                    \
    MACRO(RootFxc2, states, Fthrust2,  { out.addChannel("RootFxc2", "kN", &system.Fthrust2, 1.0/3000.0); } )                    \
    MACRO(RootFxc3, states, Fthrust3,  { out.addChannel("RootFxc3", "kN", &system.Fthrust3, 1.0/3000.0); } )                    \
    MACRO(RootMxc, states, Trot,  { out.addChannel("RootMxc", "kNm", &system.Trot, 1.0/3000.0);                                 \
                            out.addChannel("LSShftMxa", "kNm", &system.Trot, 1.0/1000.0); } )                                   \
    MACRO(RootMxc1, states, Trot1,  { out.addChannel("RootMxc1", "kNm", &system.Trot1, 1.0/3000.0); } )                         \
    MACRO(RootMxc2, states, Trot2,  { out.addChannel("RootMxc2", "kNm", &system.Trot2, 1.0/3000.0); } )                         \
    MACRO(RootMxc3, states, Trot3,  { out.addChannel("RootMxc3", "kNm", &system.Trot3, 1.0/3000.0); } )                         \
    MACRO(HSShftTq, inputs, Tgen,  { out.addChannel("HSShftTq", "kNm", &system.inputs.Tgen, 1.0/1000.0);                        \
                            out.addChannel("GenTq", "kNm", &system.inputs.Tgen, 1.0/1000.0); } )                                \
    MACRO(RtVAvgxh, inputs, vwind,  { out.addChannel("RtVAvgxh", "m/s", &system.inputs.vwind); } )                              \
    MACRO(RtTSR, states, lam,  { out.addChannel("RtTSR", "-", &system.lam); } )                                                 \
    MACRO(RtAeroCq, states, cm,  { out.addChannel("RtAeroCq", "-", &system.cm); } )                                             \
    MACRO(RtAeroCt, states, ct,  { out.addChannel("RtAeroCt", "-", &system.ct); } )                                             \
    MACRO(RotCf, states, cflp,  { out.addChannel("RotCf", "-", &system.cflp); } )                                               \
    MACRO(RotCe, states, cedg,  { out.addChannel("RotCe", "-", &system.cedg); } )                                               \
    MACRO(BlPitchC, inputs, theta,  { out.addChannel("BlPitchC", "deg", &system.inputs.theta,  -180.0/M_PI); } )                \
    MACRO(BlPitchC1, inputs, theta1,  { out.addChannel("BlPitchC1", "deg", &system.inputs.theta1,  -180.0/M_PI); } )            \
    MACRO(BlPitchC2, inputs, theta2,  { out.addChannel("BlPitchC2", "deg", &system.inputs.theta2,  -180.0/M_PI); } )            \
    MACRO(BlPitchC3, inputs, theta3,  { out.addChannel("BlPitchC3", "deg", &system.inputs.theta3,  -180.0/M_PI); } )            \
    MACRO(RootMxb, outputs, bld_edg_mom,  { out.addChannel("RootMxb", "kNm", &system.outputs.bld_edg_mom, 1.0/1000.0); } )      \
    MACRO(RootMxb1, outputs, bld1_edg_mom,  { out.addChannel("RootMxb1", "kNm", &system.outputs.bld1_edg_mom, 1.0/1000.0); } )  \
    MACRO(RootMxb2, outputs, bld2_edg_mom,  { out.addChannel("RootMxb2", "kNm", &system.outputs.bld2_edg_mom, 1.0/1000.0); } )  \
    MACRO(RootMxb3, outputs, bld3_edg_mom,  { out.addChannel("RootMxb3", "kNm", &system.outputs.bld3_edg_mom, 1.0/1000.0); } )  \
    MACRO(RootMyb, outputs, bld_flp_mom,  { out.addChannel("RootMyb", "kNm", &system.outputs.bld_flp_mom, 1.0/1000.0); } )      \
    MACRO(RootMyb1, outputs, bld1_flp_mom,  { out.addChannel("RootMyb1", "kNm", &system.outputs.bld1_flp_mom, 1.0/1000.0); } )  \
    MACRO(RootMyb2, outputs, bld2_flp_mom,  { out.addChannel("RootMyb2", "kNm", &system.outputs.bld2_flp_mom, 1.0/1000.0); } )  \
    MACRO(RootMyb3, outputs, bld3_flp_mom,  { out.addChannel("RootMyb3", "kNm", &system.outputs.bld2_flp_mom, 1.0/1000.0); } )  \
    MACRO(TwrBsMyt, outputs, tow_bot_fa_mom,  { out.addChannel("TwrBsMyt", "kNm", &system.outputs.tow_bot_fa_mom, 1.0/1000.0); } )  \
    MACRO(TwrBsMxt, outputs, tow_bot_ss_mom,  { out.addChannel("TwrBsMxt", "kNm", &system.outputs.tow_bot_ss_mom, 1.0/1000.0); } )  \
    MACRO(Spn1ALxb, outputs, bld_flp_acc,  { out.addChannel("Spn1ALxb", "m/s^2", &system.outputs.bld_flp_acc); } )              \
    MACRO(Spn1ALyb, outputs, bld_edg_acc,  { out.addChannel("Spn1ALyb", "m/s^2", &system.outputs.bld_edg_acc); } )           

   
    
// TODO: externals should be in their own struct. For now hack around it with an extra check
#define DECLARE_SENSOR(CHAN_NAME, SUB_CLASS, MEMBER, CODE)                              \
    template <typename T, typename = void>                                              \
    struct can_do_##CHAN_NAME : std::false_type {};                                     \
    template <typename T>                                                               \
    struct can_do_##CHAN_NAME<T, std::void_t<decltype(T::MEMBER)>> : std::true_type {}; \
    template <typename T>                                                               \
    void register_##CHAN_NAME(FAST_Output &out, T &system) {                            \
        if constexpr (can_do_##CHAN_NAME<typename T::SUB_CLASS##_t>::value) {           \
            CODE;                                                                       \
        }                                                                               \
        if constexpr (can_do_##CHAN_NAME<T>::value) {                                   \
            CODE;                                                                       \
        }                                                                               \
    }

LIST_OF_SENSORS( DECLARE_SENSOR )
#undef DECLARE_SENSOR
    
void setupOutputs(FAST_Output &out, MODEL_NAME &system) {
    
#define REGISTER_SENSOR(CHAN_NAME, SUB_CLASS, MEMBER, CODE) register_##CHAN_NAME<MODEL_NAME>(out, system);
LIST_OF_SENSORS( REGISTER_SENSOR )
#undef REGISTER_SENSOR

}

#endif /* STANDARDSENSORS_H_ */
