#pragma once

#include <algorithm>
#include <cmath>
#include <limits>
#include <stdexcept>
#include <type_traits>

#include <Eigen/Dense>

struct TrackingReferences {
    double om_rot_ref = 0.0;
    double Tgen_ref = 0.0;
    double theta_ref = 0.0;
    double P_ref = 0.0;
};

template <typename real_type>
inline double clamp_value(real_type v, real_type lo, real_type hi) {
    return std::max(lo, std::min(v, hi));
}

template <typename real_type, int N>
inline double interp1_linear_clamped(
    const Eigen::Matrix<real_type, 1, N>& x,
    const Eigen::Matrix<real_type, 1, N>& y,
    double xq) {
    static_assert(N >= 2, "interp1 input vectors must have fixed size >= 2.");

    if (xq <= x[0]) {
        return y[0];
    }
    if (xq >= x[N - 1]) {
        return y[N - 1];
    }

    int lo = 0;
    int hi = N - 1;
    while (hi - lo > 1) {
        const int mid = lo + (hi - lo) / 2;
        if (xq < x[mid]) {
            hi = mid;
        } else {
            lo = mid;
        }
    }

    const double dx = static_cast<double>(x[hi]) - static_cast<double>(x[lo]);
    const double w = (xq - static_cast<double>(x[lo])) / dx;
    return (1.0 - w) * static_cast<double>(y[lo]) + w * static_cast<double>(y[hi]);
}

inline double bilinear_cp_lut(
    const T1_optParameters& param,
    double lam,
    double theta_deg) {
    if (param.cp_lut.rows() < 2 || param.cp_lut.cols() < 2) {
        throw std::runtime_error("cp_lut must have at least 2x2 entries.");
    }
    const double lambda_step = param.lambdaStep;
    const double theta_step = param.thetaStep;
    if (lambda_step <= 0.0 || theta_step <= 0.0) {
        throw std::runtime_error("Invalid lambda/theta grid in generated parameter object.");
    }

    const double lam_max = param.lambdaMax;
    const double th_max = param.thetaMax;

    const double lam_c = clamp_value(lam, param.lambdaMin, lam_max - lambda_step);
    const double th_c = clamp_value(theta_deg, param.thetaMin, th_max - theta_step);

    const double lam_scaled = (lam_c - param.lambdaMin) / lambda_step;
    const double th_scaled = (th_c - param.thetaMin) / theta_step;

    const int i = static_cast<int>(std::floor(lam_scaled));
    const int j = static_cast<int>(std::floor(th_scaled));

    const double wi = lam_scaled - i;
    const double wj = th_scaled - j;

    const double c00 = param.cp_lut(i, j);
    const double c10 = param.cp_lut(i + 1, j);
    const double c01 = param.cp_lut(i, j + 1);
    const double c11 = param.cp_lut(i + 1, j + 1);

    const double c0 = (1.0 - wi) * c00 + wi * c10;
    const double c1 = (1.0 - wi) * c01 + wi * c11;
    return (1.0 - wj) * c0 + wj * c1;
}

inline TrackingReferences calc_tracking_references(
    double vwind,
    const Parameters_t& param) {
    constexpr double kPi = 3.14159265358979323846;
    constexpr double kEps = 1e-9;

    TrackingReferences out;
    if (vwind <= kEps) {
        return out;
    }

    const double om_rot_opt = param.lambda_opt * vwind / param.Rrot;
    const double om_rot_max = param.rpm_max / 30.0 * kPi / param.GBRatio;
    const double om_rot_min = param.rpm_min / 30.0 * kPi / param.GBRatio;
    out.om_rot_ref = clamp_value(om_rot_opt, om_rot_min, om_rot_max);

    const double lam = out.om_rot_ref * param.Rrot / vwind;
    const double theta_opt_deg = interp1_linear_clamped(param.lambda, param.theta_opt_lut, lam);

    double cp_opt = bilinear_cp_lut(param, lam, theta_opt_deg);
    cp_opt = std::max(lam * cp_opt, 0.0);

    const double P_opt = 0.5 * param.rho * param.Arot * vwind * vwind * vwind * cp_opt;
    out.P_ref = std::min(P_opt, static_cast<double>(param.power_max));

    out.Tgen_ref = (out.om_rot_ref > kEps)
        ? out.P_ref / out.om_rot_ref / param.GBRatio
        : 0.0;

    const double theta_ref_deg = (P_opt <= param.power_max)
        ? theta_opt_deg
        : interp1_linear_clamped(param.vwind_vec, param.theta_full_lut, vwind);

    out.theta_ref = -theta_ref_deg / 180.0 * kPi;
    return out;
}
