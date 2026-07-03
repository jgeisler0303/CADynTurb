// DISCON_sandbox_mex.cpp
// Purpose: Run DISCON.dll in an isolated worker process and communicate with MEX via inter-process communication (IPC).
// This file contains two programs in one source:
//   1) MEX client (default build): exports mexFunction and controls worker lifecycle.
//   2) Worker executable (build with -DDISCON_SANDBOX_WORKER_MAIN): has main().
// Compile hint:
//   - Build MEX: mex -D_USE_MATH_DEFINES DISCON_sandbox_mex.cpp
//   - Build worker: g++ -DDISCON_SANDBOX_WORKER_MAIN DISCON_sandbox_mex.cpp -o DISCON_sandbox_worker

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <stdint.h>
#include <string>
#include <vector>
#include <stdexcept>
#include <fstream>
#include <sstream>

#include "discon_interface.h"

#ifndef DISCON_SANDBOX_WORKER_MAIN
#include "mex.h"
#ifndef HAVE_OCTAVE
#include "matrix.h"
#endif
#endif

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#pragma comment(lib, "ws2_32.lib")
typedef SOCKET SocketHandle;
static const SocketHandle kInvalidSocket = INVALID_SOCKET;
#else
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <signal.h>
#include <unistd.h>
#include <errno.h>
#include <sys/stat.h>
typedef int SocketHandle;
static const SocketHandle kInvalidSocket = -1;
#endif

enum input_idx1 {
    in_idx_dll_path = 0,
    in_idx_discon_parameter,
    in_idx_config_path,
    in_idx1_last
};

enum input_idx2 {
    in_idx_t = 0,
    in_idx_vwind,
    in_idx_Tgen_in,
    in_idx_om_rot,
    in_idx_om_gen,
    in_idx_theta_in,
    in_idx_tow_fa_acc,
    in_idx_tow_ss_acc,
    in_idx_phi_rot,
    in_idx2_last
};

enum output_idx {
    out_idx_theta_out = 0,
    out_idx_Tgen_out,
    out_idx_sim_status,
    out_idx_last
};

enum MessageType {
    msg_init_req = 1,
    msg_init_resp = 2,
    msg_step_req = 3,
    msg_step_resp = 4,
    msg_shutdown_req = 5,
    msg_shutdown_resp = 6,
    msg_error = 100
};

struct OptionalDouble {
    bool has;
    double value;
};

struct DisconParamsWire {
    OptionalDouble comm_interval;
    OptionalDouble Ptch_Min;
    OptionalDouble Ptch_Max;
    OptionalDouble PtchRate_Min;
    OptionalDouble PtchRate_Max;
    OptionalDouble pitch_actuator;
    OptionalDouble Gain_OM;
    OptionalDouble GenSpd_MinOM;
    OptionalDouble GenSpd_MaxOM;
    OptionalDouble GenSpd_Dem;
    OptionalDouble GenTrq_Dem;
    OptionalDouble GenPwr_Dem;
    OptionalDouble Ptch_SetPnt;
    OptionalDouble yaw_ctrl_mode;
    OptionalDouble num_blades;
    OptionalDouble Ptch_Cntrl;
    OptionalDouble gen_contractor;
    OptionalDouble controller_state;
    OptionalDouble time_to_output;
    OptionalDouble version;
};

struct InitRequest {
    std::string dll_path;
    std::string config_path;
    DisconParamsWire params;
    bool detailed_logging;
};

struct StepRequest {
    double t;
    double vwind;
    double Tgen_in;
    double om_rot;
    double om_gen;
    double theta_in;
    double tow_fa_acc;
    double tow_ss_acc;
    double phi_rot;
};

struct GenericResponse {
    int32_t code;
    int32_t sim_status;
    double theta_out;
    double Tgen_out;
    std::string message;
};

static bool g_at_exit_registered = false;

struct SandboxProcessState {
    bool connected;
    SocketHandle sock;
    uint16_t port;
    std::string worker_path;
    std::string worker_log_path;
#ifdef _WIN32
    PROCESS_INFORMATION pi;
#else
    pid_t pid;
#endif
};

static SandboxProcessState g_sandbox = {
    false,
    kInvalidSocket,
    0,
    "",
    "",
#ifdef _WIN32
    {0}
#else
    -1
#endif
};

static std::string get_last_os_error() {
#ifdef _WIN32
    DWORD err = GetLastError();
    LPSTR msg_buf = nullptr;
    DWORD size = FormatMessageA(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        err,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPSTR)&msg_buf,
        0,
        NULL);
    std::string msg = (size > 0 && msg_buf != nullptr) ? std::string(msg_buf, size) : std::string("unknown error");
    if (msg_buf != nullptr) {
        LocalFree(msg_buf);
    }
    return msg;
#else
    return std::string(strerror(errno));
#endif
}

static void close_socket(SocketHandle s) {
    if (s == kInvalidSocket) {
        return;
    }
#ifdef _WIN32
    closesocket(s);
#else
    close(s);
#endif
}

static bool init_socket_lib(std::string& err) {
#ifdef _WIN32
    static bool initialized = false;
    if (initialized) {
        return true;
    }
    WSADATA wsa_data;
    if (WSAStartup(MAKEWORD(2, 2), &wsa_data) != 0) {
        err = "WSAStartup failed";
        return false;
    }
    initialized = true;
#else
    (void)err;
#endif
    return true;
}

static bool send_all(SocketHandle sock, const uint8_t* data, size_t len, std::string& err) {
    size_t sent = 0;
    while (sent < len) {
#ifdef _WIN32
        int n = send(sock, reinterpret_cast<const char*>(data + sent), static_cast<int>(len - sent), 0);
        if (n == SOCKET_ERROR) {
            err = "send failed: " + get_last_os_error();
            return false;
        }
#else
        ssize_t n = send(sock, data + sent, len - sent, 0);
        if (n < 0) {
            err = "send failed: " + get_last_os_error();
            return false;
        }
#endif
        if (n == 0) {
            err = "send returned 0 bytes";
            return false;
        }
        sent += static_cast<size_t>(n);
    }
    return true;
}

static bool recv_all(SocketHandle sock, uint8_t* data, size_t len, std::string& err) {
    size_t recvd = 0;
    while (recvd < len) {
#ifdef _WIN32
        int n = recv(sock, reinterpret_cast<char*>(data + recvd), static_cast<int>(len - recvd), 0);
        if (n == SOCKET_ERROR) {
            err = "recv failed: " + get_last_os_error();
            return false;
        }
#else
        ssize_t n = recv(sock, data + recvd, len - recvd, 0);
        if (n < 0) {
            err = "recv failed: " + get_last_os_error();
            return false;
        }
#endif
        if (n == 0) {
            err = "peer closed connection";
            return false;
        }
        recvd += static_cast<size_t>(n);
    }
    return true;
}

static void append_u8(std::vector<uint8_t>& buf, uint8_t v) {
    buf.push_back(v);
}

static void append_u32(std::vector<uint8_t>& buf, uint32_t v) {
    for (int i = 0; i < 4; ++i) {
        buf.push_back(static_cast<uint8_t>((v >> (8 * i)) & 0xFF));
    }
}

static void append_i32(std::vector<uint8_t>& buf, int32_t v) {
    append_u32(buf, static_cast<uint32_t>(v));
}

static void append_double(std::vector<uint8_t>& buf, double v) {
    const uint8_t* p = reinterpret_cast<const uint8_t*>(&v);
    for (size_t i = 0; i < sizeof(double); ++i) {
        buf.push_back(p[i]);
    }
}

static void append_string(std::vector<uint8_t>& buf, const std::string& s) {
    append_u32(buf, static_cast<uint32_t>(s.size()));
    buf.insert(buf.end(), s.begin(), s.end());
}

static bool read_u8(const std::vector<uint8_t>& buf, size_t& pos, uint8_t& v) {
    if (pos + 1 > buf.size()) {
        return false;
    }
    v = buf[pos];
    pos += 1;
    return true;
}

static bool read_u32(const std::vector<uint8_t>& buf, size_t& pos, uint32_t& v) {
    if (pos + 4 > buf.size()) {
        return false;
    }
    v = 0;
    for (int i = 0; i < 4; ++i) {
        v |= (static_cast<uint32_t>(buf[pos + i]) << (8 * i));
    }
    pos += 4;
    return true;
}

static bool read_i32(const std::vector<uint8_t>& buf, size_t& pos, int32_t& v) {
    uint32_t tmp = 0;
    if (!read_u32(buf, pos, tmp)) {
        return false;
    }
    v = static_cast<int32_t>(tmp);
    return true;
}

static bool read_double(const std::vector<uint8_t>& buf, size_t& pos, double& v) {
    if (pos + sizeof(double) > buf.size()) {
        return false;
    }
    memcpy(&v, &buf[pos], sizeof(double));
    pos += sizeof(double);
    return true;
}

static bool read_string(const std::vector<uint8_t>& buf, size_t& pos, std::string& s) {
    uint32_t len = 0;
    if (!read_u32(buf, pos, len)) {
        return false;
    }
    if (pos + len > buf.size()) {
        return false;
    }
    s.assign(reinterpret_cast<const char*>(&buf[pos]), reinterpret_cast<const char*>(&buf[pos]) + len);
    pos += len;
    return true;
}

static void append_optional(std::vector<uint8_t>& buf, const OptionalDouble& v) {
    append_u8(buf, v.has ? 1 : 0);
    append_double(buf, v.value);
}

static bool read_optional(const std::vector<uint8_t>& buf, size_t& pos, OptionalDouble& v) {
    uint8_t has = 0;
    if (!read_u8(buf, pos, has)) {
        return false;
    }
    if (!read_double(buf, pos, v.value)) {
        return false;
    }
    v.has = (has != 0);
    return true;
}

static void append_params(std::vector<uint8_t>& buf, const DisconParamsWire& p) {
    append_optional(buf, p.comm_interval);
    append_optional(buf, p.Ptch_Min);
    append_optional(buf, p.Ptch_Max);
    append_optional(buf, p.PtchRate_Min);
    append_optional(buf, p.PtchRate_Max);
    append_optional(buf, p.pitch_actuator);
    append_optional(buf, p.Gain_OM);
    append_optional(buf, p.GenSpd_MinOM);
    append_optional(buf, p.GenSpd_MaxOM);
    append_optional(buf, p.GenSpd_Dem);
    append_optional(buf, p.GenTrq_Dem);
    append_optional(buf, p.GenPwr_Dem);
    append_optional(buf, p.Ptch_SetPnt);
    append_optional(buf, p.yaw_ctrl_mode);
    append_optional(buf, p.num_blades);
    append_optional(buf, p.Ptch_Cntrl);
    append_optional(buf, p.gen_contractor);
    append_optional(buf, p.controller_state);
    append_optional(buf, p.time_to_output);
    append_optional(buf, p.version);
}

static bool read_params(const std::vector<uint8_t>& buf, size_t& pos, DisconParamsWire& p) {
    return read_optional(buf, pos, p.comm_interval) &&
           read_optional(buf, pos, p.Ptch_Min) &&
           read_optional(buf, pos, p.Ptch_Max) &&
           read_optional(buf, pos, p.PtchRate_Min) &&
           read_optional(buf, pos, p.PtchRate_Max) &&
           read_optional(buf, pos, p.pitch_actuator) &&
           read_optional(buf, pos, p.Gain_OM) &&
           read_optional(buf, pos, p.GenSpd_MinOM) &&
           read_optional(buf, pos, p.GenSpd_MaxOM) &&
           read_optional(buf, pos, p.GenSpd_Dem) &&
           read_optional(buf, pos, p.GenTrq_Dem) &&
           read_optional(buf, pos, p.GenPwr_Dem) &&
           read_optional(buf, pos, p.Ptch_SetPnt) &&
           read_optional(buf, pos, p.yaw_ctrl_mode) &&
           read_optional(buf, pos, p.num_blades) &&
           read_optional(buf, pos, p.Ptch_Cntrl) &&
           read_optional(buf, pos, p.gen_contractor) &&
           read_optional(buf, pos, p.controller_state) &&
           read_optional(buf, pos, p.time_to_output) &&
           read_optional(buf, pos, p.version);
}

static bool send_frame(SocketHandle sock, uint32_t type, const std::vector<uint8_t>& payload, std::string& err) {
    std::vector<uint8_t> hdr;
    hdr.reserve(8);
    append_u32(hdr, type);
    append_u32(hdr, static_cast<uint32_t>(payload.size()));

    if (!send_all(sock, &hdr[0], hdr.size(), err)) {
        return false;
    }
    if (!payload.empty() && !send_all(sock, &payload[0], payload.size(), err)) {
        return false;
    }
    return true;
}

static bool recv_frame(SocketHandle sock, uint32_t& type, std::vector<uint8_t>& payload, std::string& err) {
    uint8_t hdr[8];
    if (!recv_all(sock, hdr, sizeof(hdr), err)) {
        return false;
    }
    size_t pos = 0;
    std::vector<uint8_t> hdr_vec(hdr, hdr + sizeof(hdr));
    uint32_t payload_len = 0;
    if (!read_u32(hdr_vec, pos, type) || !read_u32(hdr_vec, pos, payload_len)) {
        err = "invalid frame header";
        return false;
    }

    payload.resize(payload_len);
    if (payload_len > 0 && !recv_all(sock, &payload[0], payload_len, err)) {
        return false;
    }
    return true;
}

static std::vector<uint8_t> serialize_init_request(const InitRequest& req) {
    std::vector<uint8_t> p;
    append_string(p, req.dll_path);
    append_string(p, req.config_path);
    append_params(p, req.params);
    append_u8(p, req.detailed_logging ? 1 : 0);
    return p;
}

static bool deserialize_init_request(const std::vector<uint8_t>& p, InitRequest& req) {
    size_t pos = 0;
    if (!read_string(p, pos, req.dll_path)) {
        return false;
    }
    if (!read_string(p, pos, req.config_path)) {
        return false;
    }
    if (!read_params(p, pos, req.params)) {
        return false;
    }
    uint8_t detailed = 0;
    if (!read_u8(p, pos, detailed)) {
        return false;
    }
    req.detailed_logging = (detailed != 0);
    return pos == p.size();
}

static std::vector<uint8_t> serialize_step_request(const StepRequest& req) {
    std::vector<uint8_t> p;
    append_double(p, req.t);
    append_double(p, req.vwind);
    append_double(p, req.Tgen_in);
    append_double(p, req.om_rot);
    append_double(p, req.om_gen);
    append_double(p, req.theta_in);
    append_double(p, req.tow_fa_acc);
    append_double(p, req.tow_ss_acc);
    append_double(p, req.phi_rot);
    return p;
}

static bool deserialize_step_request(const std::vector<uint8_t>& p, StepRequest& req) {
    size_t pos = 0;
    if (!read_double(p, pos, req.t)) return false;
    if (!read_double(p, pos, req.vwind)) return false;
    if (!read_double(p, pos, req.Tgen_in)) return false;
    if (!read_double(p, pos, req.om_rot)) return false;
    if (!read_double(p, pos, req.om_gen)) return false;
    if (!read_double(p, pos, req.theta_in)) return false;
    if (!read_double(p, pos, req.tow_fa_acc)) return false;
    if (!read_double(p, pos, req.tow_ss_acc)) return false;
    if (!read_double(p, pos, req.phi_rot)) return false;
    return pos == p.size();
}

static std::vector<uint8_t> serialize_response(const GenericResponse& resp) {
    std::vector<uint8_t> p;
    append_i32(p, resp.code);
    append_i32(p, resp.sim_status);
    append_double(p, resp.theta_out);
    append_double(p, resp.Tgen_out);
    append_string(p, resp.message);
    return p;
}

static bool deserialize_response(const std::vector<uint8_t>& p, GenericResponse& resp) {
    size_t pos = 0;
    if (!read_i32(p, pos, resp.code)) {
        return false;
    }
    if (!read_i32(p, pos, resp.sim_status)) {
        return false;
    }
    if (!read_double(p, pos, resp.theta_out)) {
        return false;
    }
    if (!read_double(p, pos, resp.Tgen_out)) {
        return false;
    }
    if (!read_string(p, pos, resp.message)) {
        return false;
    }
    return pos == p.size();
}

#ifndef DISCON_SANDBOX_WORKER_MAIN
static bool try_get_option(double* value, const char* name, const mxArray* mxOptions, int m__ = 1, int n__ = 1) {
    const mxArray* mxOption;
    if ((mxOption = mxGetField(mxOptions, 0, name)) != NULL) {
        int m_ = static_cast<int>(mxGetM(mxOption));
        int n_ = static_cast<int>(mxGetN(mxOption));
        if (mxIsSparse(mxOption) || !mxIsDouble(mxOption) || (m_ != m__ || n_ != n__)) {
            mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Option name '%s' has wrong dimension.", name);
            return false;
        }

        for (int i = 0; i < m__; i++) {
            for (int j = 0; j < n__; j++) {
                value[i + j * m__] = mxGetPr(mxOption)[i + j * m__];
            }
        }

        return true;
    }
    return false;
}

static bool try_get_option_string(std::string& value, const char* name, const mxArray* mxOptions) {
    const mxArray* mxOption = mxGetField(mxOptions, 0, name);
    if (mxOption == NULL) {
        return false;
    }
    if (!mxIsChar(mxOption) || (mxGetM(mxOption) != 1)) {
        mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Option '%s' must be a character row vector.", name);
        return false;
    }
    const int buflen = 4096;
    std::vector<char> buf(static_cast<size_t>(buflen), '\0');
    int status = mxGetString(mxOption, &buf[0], static_cast<mwSize>(buflen));
    if (status != 0) {
        mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Failed to copy option '%s'.", name);
        return false;
    }
    value.assign(&buf[0]);
    return true;
}

static bool try_get_option_bool(bool& value, const char* name, const mxArray* mxOptions) {
    const mxArray* mxOption = mxGetField(mxOptions, 0, name);
    if (mxOption == NULL) {
        return false;
    }

    if (mxIsLogicalScalar(mxOption)) {
        value = mxIsLogicalScalarTrue(mxOption);
        return true;
    }

    if (!mxIsSparse(mxOption) && mxIsDouble(mxOption) && mxGetNumberOfElements(mxOption) == 1) {
        value = (mxGetScalar(mxOption) != 0.0);
        return true;
    }

    mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Option '%s' must be scalar logical or scalar numeric.", name);
    return false;
}

static DisconParamsWire parse_discon_params(const mxArray* mxParams) {
    DisconParamsWire p;
    double value = 0.0;

#define READ_OPT(field_name)                            \
    do {                                                \
        p.field_name.has = try_get_option(&value, #field_name, mxParams); \
        p.field_name.value = value;                     \
    } while (0)

    READ_OPT(comm_interval);
    READ_OPT(Ptch_Min);
    READ_OPT(Ptch_Max);
    READ_OPT(PtchRate_Min);
    READ_OPT(PtchRate_Max);
    READ_OPT(pitch_actuator);
    READ_OPT(Gain_OM);
    READ_OPT(GenSpd_MinOM);
    READ_OPT(GenSpd_MaxOM);
    READ_OPT(GenSpd_Dem);
    READ_OPT(GenTrq_Dem);
    READ_OPT(GenPwr_Dem);
    READ_OPT(Ptch_SetPnt);
    READ_OPT(yaw_ctrl_mode);
    READ_OPT(num_blades);
    READ_OPT(Ptch_Cntrl);
    READ_OPT(gen_contractor);
    READ_OPT(controller_state);
    READ_OPT(time_to_output);
    READ_OPT(version);

#undef READ_OPT

    return p;
}
#endif

static bool is_process_alive() {
#ifdef _WIN32
    if (g_sandbox.pi.hProcess == NULL) {
        return false;
    }
    DWORD wait_res = WaitForSingleObject(g_sandbox.pi.hProcess, 0);
    return wait_res == WAIT_TIMEOUT;
#else
    if (g_sandbox.pid <= 0) {
        return false;
    }
    if (kill(g_sandbox.pid, 0) == 0) {
        return true;
    }
    return errno != ESRCH;
#endif
}

static void kill_worker_process() {
#ifdef _WIN32
    if (g_sandbox.pi.hProcess != NULL) {
        TerminateProcess(g_sandbox.pi.hProcess, 1);
        WaitForSingleObject(g_sandbox.pi.hProcess, 2000);
        CloseHandle(g_sandbox.pi.hThread);
        CloseHandle(g_sandbox.pi.hProcess);
        g_sandbox.pi.hThread = NULL;
        g_sandbox.pi.hProcess = NULL;
    }
#else
    if (g_sandbox.pid > 0) {
        kill(g_sandbox.pid, SIGKILL);
        int status = 0;
        waitpid(g_sandbox.pid, &status, 0);
        g_sandbox.pid = -1;
    }
#endif
}

static void cleanup_worker(bool kill_process) {
    if (g_sandbox.sock != kInvalidSocket) {
        close_socket(g_sandbox.sock);
        g_sandbox.sock = kInvalidSocket;
    }
    if (kill_process) {
        kill_worker_process();
    }
    g_sandbox.connected = false;
    g_sandbox.port = 0;
}

static uint16_t pick_free_port() {
    SocketHandle s = socket(AF_INET, SOCK_STREAM, 0);
    if (s == kInvalidSocket) {
        throw std::runtime_error("Failed to create socket for free-port lookup: " + get_last_os_error());
    }

    sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    addr.sin_port = htons(0);

    if (bind(s, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != 0) {
        std::string err = "bind failed in pick_free_port: " + get_last_os_error();
        close_socket(s);
        throw std::runtime_error(err);
    }

    socklen_t len = static_cast<socklen_t>(sizeof(addr));
    if (getsockname(s, reinterpret_cast<sockaddr*>(&addr), &len) != 0) {
        std::string err = "getsockname failed in pick_free_port: " + get_last_os_error();
        close_socket(s);
        throw std::runtime_error(err);
    }
    uint16_t port = ntohs(addr.sin_port);
    close_socket(s);
    return port;
}

static bool connect_with_retry(uint16_t port, int retries, int sleep_ms, SocketHandle& out_sock, std::string& err) {
    for (int i = 0; i < retries; ++i) {
        SocketHandle s = socket(AF_INET, SOCK_STREAM, 0);
        if (s == kInvalidSocket) {
            err = "socket failed: " + get_last_os_error();
            return false;
        }

        sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_port = htons(port);
        addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);

        if (connect(s, reinterpret_cast<sockaddr*>(&addr), static_cast<socklen_t>(sizeof(addr))) == 0) {
            out_sock = s;
            return true;
        }

        close_socket(s);
#ifdef _WIN32
        Sleep(static_cast<DWORD>(sleep_ms));
#else
        usleep(static_cast<useconds_t>(sleep_ms * 1000));
#endif
    }

    err = "Could not connect to worker on localhost:" + std::to_string(port);
    return false;
}

static std::string quote_cmd_arg(const std::string& s) {
    std::string out = "\"";
    for (size_t i = 0; i < s.size(); ++i) {
        char c = s[i];
        if (c == '\\' || c == '"') {
            out.push_back('\\');
        }
        out.push_back(c);
    }
    out.push_back('"');
    return out;
}

static bool launch_worker_process(const std::string& worker_path, uint16_t port, const std::string& log_path, std::string& err) {
#ifdef _WIN32
    STARTUPINFOA si;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&g_sandbox.pi, sizeof(g_sandbox.pi));

    std::string cmd = quote_cmd_arg(worker_path) + " --worker-port " + std::to_string(port) + " --worker-log " + quote_cmd_arg(log_path);
    std::vector<char> cmd_buf(cmd.begin(), cmd.end());
    cmd_buf.push_back('\0');

    BOOL ok = CreateProcessA(
        NULL,
        &cmd_buf[0],
        NULL,
        NULL,
        FALSE,
        0,
        NULL,
        NULL,
        &si,
        &g_sandbox.pi);

    if (!ok) {
        err = "CreateProcess failed: " + get_last_os_error();
        return false;
    }
#else
    {
        struct stat st;
        if (stat(worker_path.c_str(), &st) != 0) {
            err = "worker executable not found: " + worker_path + " (cwd-dependent relative path?)";
            return false;
        }
        if (access(worker_path.c_str(), X_OK) != 0) {
            err = "worker not executable: " + worker_path;
            return false;
        }
    }

    pid_t pid = fork();
    if (pid < 0) {
        err = "fork failed: " + get_last_os_error();
        return false;
    }
    if (pid == 0) {
        std::string port_str = std::to_string(port);
        if (!log_path.empty()) {
            execl(worker_path.c_str(), worker_path.c_str(), "--worker-port", port_str.c_str(), "--worker-log", log_path.c_str(), (char*)NULL);
        } else {
            execl(worker_path.c_str(), worker_path.c_str(), "--worker-port", port_str.c_str(), (char*)NULL);
        }
        _exit(127);
    }
    g_sandbox.pid = pid;
#endif

    return true;
}

static bool request_response(uint32_t req_type,
                             const std::vector<uint8_t>& req_payload,
                             uint32_t expected_resp_type,
                             GenericResponse& resp,
                             std::string& err) {
    if (!send_frame(g_sandbox.sock, req_type, req_payload, err)) {
        return false;
    }

    uint32_t resp_type = 0;
    std::vector<uint8_t> resp_payload;
    if (!recv_frame(g_sandbox.sock, resp_type, resp_payload, err)) {
        return false;
    }
    if (resp_type != expected_resp_type && resp_type != msg_error) {
        err = "unexpected response type: " + std::to_string(resp_type);
        return false;
    }
    if (!deserialize_response(resp_payload, resp)) {
        err = "failed to deserialize worker response";
        return false;
    }
    return true;
}

static void at_exit_cleanup() {
    cleanup_worker(true);
}

#ifndef DISCON_SANDBOX_WORKER_MAIN

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
    if (!g_at_exit_registered) {
        mexAtExit(at_exit_cleanup);
        g_at_exit_registered = true;
    }

    if ((nrhs < (in_idx_discon_parameter + 1) || nrhs > in_idx1_last) && nrhs != 0 && nrhs != in_idx2_last) {
        mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Wrong number of arguments. Expecting 0 or (dll_path {param, config_path}) or (t, vwind, Tgen, om_rot, om_gen, theta, tow_fa_acc, tow_ss_acc, phi_rot)");
        return;
    }

    std::string sock_err;
    if (!init_socket_lib(sock_err)) {
        mexErrMsgIdAndTxt("DISCON_sandbox:Socket", "Socket init failed: %s", sock_err.c_str());
        return;
    }

    // Terminate DLL: force-kill the external worker process.
    if (nrhs == 0) {
        if (nlhs != 0) {
            mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Wrong number of return values. Expecting 0.");
            return;
        }

        if (!g_sandbox.connected && !is_process_alive()) {
            mexWarnMsgIdAndTxt("DISCON_sandbox:InvalidOperation", "DISCON sandbox worker currently not running.");
            return;
        }

        if (g_sandbox.connected && g_sandbox.sock != kInvalidSocket && is_process_alive()) {
            GenericResponse resp;
            std::vector<uint8_t> req_payload;
            if (request_response(msg_shutdown_req, req_payload, msg_shutdown_resp, resp, sock_err)) {
                if (resp.code == 0 && !resp.message.empty()) {
                    mexPrintf("DISCON message: %s\n", resp.message.c_str());
                }
            }
        }

        cleanup_worker(true);
        return;
    }

    // Initialize DLL: kill old process (if any), start a fresh process, then send full init data via IPC.
    if (nrhs <= in_idx1_last) {
        if (nlhs != 0) {
            mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Wrong number of return values. Expecting 0.");
            return;
        }

        const mxArray* mxParams = prhs[in_idx_discon_parameter];
        if (!mxIsStruct(mxParams) || mxGetNumberOfElements(mxParams) != 1) {
            mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Input p must be a scalar struct.");
            return;
        }

        if (!mxIsChar(prhs[in_idx_dll_path]) || (mxGetM(prhs[in_idx_dll_path]) != 1)) {
            mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Argument 'dll_path' must be a character row vector");
            return;
        }

        const int buflen = 4096;
        std::vector<char> dll_path_buf(static_cast<size_t>(buflen), '\0');
        int status = mxGetString(prhs[in_idx_dll_path], &dll_path_buf[0], static_cast<mwSize>(buflen));
        if (status != 0) {
            mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Failed to copy dll_path into %d byte buffer.", buflen);
            return;
        }

        std::string config_path;
        if (nrhs == (in_idx_config_path + 1)) {
            if (!mxIsChar(prhs[in_idx_config_path]) || (mxGetM(prhs[in_idx_config_path]) != 1)) {
                mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Argument 'config_path' must be a character row vector");
                return;
            }
            std::vector<char> config_path_buf(static_cast<size_t>(buflen), '\0');
            status = mxGetString(prhs[in_idx_config_path], &config_path_buf[0], static_cast<mwSize>(buflen));
            if (status != 0) {
                mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Failed to copy config_path into %d byte buffer.", buflen);
                return;
            }
            config_path.assign(&config_path_buf[0]);
        }

        std::string worker_path;
        std::string worker_log_path;
        bool detailed_logging = false;
        if (!try_get_option_string(worker_path, "sandbox_worker_path", mxParams)) {
#ifdef _WIN32
            worker_path = "DISCON_sandbox_worker.exe";
#else
            worker_path = "./DISCON_sandbox_worker";
#endif
        }

        (void)try_get_option_bool(detailed_logging, "sandbox_detailed_logging", mxParams);

        cleanup_worker(true);

        try {
            g_sandbox.port = pick_free_port();
        } catch (const std::exception& e) {
            mexErrMsgIdAndTxt("DISCON_sandbox:Init", "Failed to allocate local TCP port: %s", e.what());
            return;
        }

        if (!try_get_option_string(worker_log_path, "sandbox_log_path", mxParams)) {
            worker_log_path.clear();
        }

        g_sandbox.worker_path = worker_path;
        g_sandbox.worker_log_path = worker_log_path;
        if (!launch_worker_process(g_sandbox.worker_path, g_sandbox.port, g_sandbox.worker_log_path, sock_err)) {
            cleanup_worker(true);
            mexErrMsgIdAndTxt("DISCON_sandbox:Init", "Failed to launch worker '%s': %s", g_sandbox.worker_path.c_str(), sock_err.c_str());
            return;
        }

        if (!connect_with_retry(g_sandbox.port, 80, 50, g_sandbox.sock, sock_err)) {
            if (!g_sandbox.worker_log_path.empty()) {
                if (!is_process_alive()) {
                    sock_err += " | worker exited early; log: " + g_sandbox.worker_log_path;
                } else {
                    sock_err += " | worker log: " + g_sandbox.worker_log_path;
                }
            }
            cleanup_worker(true);
            mexErrMsgIdAndTxt("DISCON_sandbox:Init", "Worker started but IPC connect failed: %s", sock_err.c_str());
            return;
        }
        g_sandbox.connected = true;

        InitRequest req;
        req.dll_path = std::string(&dll_path_buf[0]);
        req.config_path = config_path;
        req.params = parse_discon_params(mxParams);
        req.detailed_logging = detailed_logging;

        GenericResponse resp;
        std::vector<uint8_t> req_payload = serialize_init_request(req);
        if (!request_response(msg_init_req, req_payload, msg_init_resp, resp, sock_err)) {
            cleanup_worker(true);
            mexErrMsgIdAndTxt("DISCON_sandbox:Init", "IPC init request failed: %s", sock_err.c_str());
            return;
        }

        if (resp.code != 0) {
            cleanup_worker(true);
            mexErrMsgIdAndTxt("DISCON_sandbox:Init", "Worker init error: %s", resp.message.c_str());
            return;
        }

        if (!resp.message.empty()) {
            mexPrintf("%s\n", resp.message.c_str());
        }
        return;
    }

    // Run step via IPC with running worker.
    if (nlhs != out_idx_last) {
        mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Wrong number of return values. Expecting [theta_set, Tgen_set, status]");
        return;
    }

    if (!g_sandbox.connected || g_sandbox.sock == kInvalidSocket) {
        mexErrMsgIdAndTxt("DISCON_sandbox:InvalidOperation", "DISCON sandbox worker is not initialized.");
        return;
    }

    if (!is_process_alive()) {
        cleanup_worker(false);
        mexErrMsgIdAndTxt("DISCON_sandbox:Crash", "DISCON sandbox worker process crashed or exited.");
        return;
    }

    if (!mxIsDouble(prhs[in_idx_t]) || mxGetNumberOfElements(prhs[in_idx_t]) != 1) { mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Input 't' must be scalar."); return; }
    if (!mxIsDouble(prhs[in_idx_vwind]) || mxGetNumberOfElements(prhs[in_idx_vwind]) != 1) { mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Input 'vwind' must be scalar."); return; }
    if (!mxIsDouble(prhs[in_idx_Tgen_in]) || mxGetNumberOfElements(prhs[in_idx_Tgen_in]) != 1) { mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Input 'Tgen_meas' must be scalar."); return; }
    if (!mxIsDouble(prhs[in_idx_om_rot]) || mxGetNumberOfElements(prhs[in_idx_om_rot]) != 1) { mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Input 'om_rot' must be scalar."); return; }
    if (!mxIsDouble(prhs[in_idx_om_gen]) || mxGetNumberOfElements(prhs[in_idx_om_gen]) != 1) { mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Input 'om_gen' must be scalar."); return; }
    if (!mxIsDouble(prhs[in_idx_theta_in]) || mxGetNumberOfElements(prhs[in_idx_theta_in]) != 1) { mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Input 'theta_meas' must be scalar."); return; }
    if (!mxIsDouble(prhs[in_idx_tow_fa_acc]) || mxGetNumberOfElements(prhs[in_idx_tow_fa_acc]) != 1) { mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Input 'tow_fa_acc' must be scalar."); return; }
    if (!mxIsDouble(prhs[in_idx_tow_ss_acc]) || mxGetNumberOfElements(prhs[in_idx_tow_ss_acc]) != 1) { mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Input 'tow_ss_acc' must be scalar."); return; }
    if (!mxIsDouble(prhs[in_idx_phi_rot]) || mxGetNumberOfElements(prhs[in_idx_phi_rot]) != 1) { mexErrMsgIdAndTxt("DISCON_sandbox:InvalidArgument", "Input 'phi_rot' must be scalar."); return; }

    StepRequest req;
    req.t = mxGetScalar(prhs[in_idx_t]);
    req.vwind = mxGetScalar(prhs[in_idx_vwind]);
    req.Tgen_in = mxGetScalar(prhs[in_idx_Tgen_in]);
    req.om_rot = mxGetScalar(prhs[in_idx_om_rot]);
    req.om_gen = mxGetScalar(prhs[in_idx_om_gen]);
    req.theta_in = mxGetScalar(prhs[in_idx_theta_in]);
    req.tow_fa_acc = mxGetScalar(prhs[in_idx_tow_fa_acc]);
    req.tow_ss_acc = mxGetScalar(prhs[in_idx_tow_ss_acc]);
    req.phi_rot = mxGetScalar(prhs[in_idx_phi_rot]);

    GenericResponse resp;
    std::vector<uint8_t> req_payload = serialize_step_request(req);
    if (!request_response(msg_step_req, req_payload, msg_step_resp, resp, sock_err)) {
        cleanup_worker(false);
        mexErrMsgIdAndTxt("DISCON_sandbox:Crash", "IPC step failed, worker likely crashed: %s", sock_err.c_str());
        return;
    }

    if (resp.code != 0) {
        mexErrMsgIdAndTxt("DISCON_sandbox:Step", "Worker step error: %s", resp.message.c_str());
        return;
    }

    if (!resp.message.empty()) {
        mexPrintf("%s\n", resp.message.c_str());
    }

    plhs[out_idx_theta_out] = mxCreateDoubleMatrix(1, 1, mxREAL);
    mxGetPr(plhs[out_idx_theta_out])[0] = resp.theta_out;

    plhs[out_idx_Tgen_out] = mxCreateDoubleMatrix(1, 1, mxREAL);
    mxGetPr(plhs[out_idx_Tgen_out])[0] = resp.Tgen_out;

    plhs[out_idx_sim_status] = mxCreateDoubleMatrix(1, 1, mxREAL);
    mxGetPr(plhs[out_idx_sim_status])[0] = static_cast<double>(resp.sim_status);
}

#else

static void set_discon_params(DISCON_Interface& DISCON, const DisconParamsWire& p) {
    if (p.comm_interval.has) DISCON.comm_interval = p.comm_interval.value;

    if (p.Ptch_Min.has) DISCON.min_pitch = p.Ptch_Min.value / 180.0 * M_PI;
    if (p.Ptch_Max.has) DISCON.max_pitch = p.Ptch_Max.value / 180.0 * M_PI;

    if (p.PtchRate_Min.has) DISCON.min_pitch_rate = p.PtchRate_Min.value / 180.0 * M_PI;
    if (p.PtchRate_Max.has) DISCON.max_pitch_rate = p.PtchRate_Max.value / 180.0 * M_PI;

    if (p.pitch_actuator.has) DISCON.pitch_actuator = p.pitch_actuator.value;
    if (p.Gain_OM.has) DISCON.opt_mode_gain = p.Gain_OM.value;

    if (p.GenSpd_MinOM.has) DISCON.min_gen_speed = p.GenSpd_MinOM.value / 30.0 * M_PI;
    if (p.GenSpd_MaxOM.has) DISCON.max_gen_speed = p.GenSpd_MaxOM.value / 30.0 * M_PI;
    if (p.GenSpd_Dem.has) DISCON.gen_speed_dem = p.GenSpd_Dem.value / 30.0 * M_PI;

    if (p.GenTrq_Dem.has) DISCON.gen_torque_sp = p.GenTrq_Dem.value;
    if (p.GenPwr_Dem.has) DISCON.power_dem = p.GenPwr_Dem.value;

    if (p.Ptch_SetPnt.has) DISCON.sp_pitch_partial = p.Ptch_SetPnt.value / 180.0 * M_PI;

    if (p.yaw_ctrl_mode.has) DISCON.yaw_ctrl_mode = p.yaw_ctrl_mode.value;
    if (p.num_blades.has) DISCON.num_blades = p.num_blades.value;
    if (p.Ptch_Cntrl.has) DISCON.pitch_ctrl_mode = p.Ptch_Cntrl.value;
    if (p.gen_contractor.has) DISCON.gen_contractor = p.gen_contractor.value;
    if (p.controller_state.has) DISCON.controller_state = p.controller_state.value;
    if (p.time_to_output.has) DISCON.time_to_output = p.time_to_output.value;
    if (p.version.has) DISCON.version = p.version.value;

    DISCON.ts_lut_idx = 0;
    DISCON.ts_lut_len = 0;
}

static void discon_step(DISCON_Interface& DISCON,
                        double& theta_out,
                        double& Tgen_out,
                        int& sim_status,
                        std::string& message,
                        const StepRequest& step) {
    DISCON.current_time = step.t;

    DISCON.wind_speed_hub = step.vwind;
    DISCON.yaw_error_meas = 0;
    DISCON.abs_yaw = 0;
    DISCON.gen_torque_meas = step.Tgen_in;
    DISCON.rot_speed_meas = step.om_rot;
    DISCON.gen_speed_meas = step.om_gen;
    DISCON.power_out_meas = DISCON.gen_speed_meas * DISCON.gen_torque_meas;

    DISCON.blade1_pitch = step.theta_in;
    DISCON.blade2_pitch = step.theta_in;
    DISCON.blade3_pitch = step.theta_in;
    DISCON.pitch_dem = 0;

    DISCON.f_a_acc = step.tow_fa_acc;
    DISCON.s_s_acc = step.tow_ss_acc;

    DISCON.rotor_pos = step.phi_rot;

    DISCON.blade1_oop_moment = 0;
    DISCON.blade2_oop_moment = 0;
    DISCON.blade3_oop_moment = 0;
    DISCON.blade1_ip_moment = 0;
    DISCON.blade2_ip_moment = 0;
    DISCON.blade3_ip_moment = 0;
    DISCON.shaft_brake_status = 0;

    DISCON.grid_volt_fact = 1.0;
    DISCON.grid_freq_fact = 1.0;

    if (DISCON.run()) {
        message = DISCON.getMessage();
    } else {
        message.clear();
    }

    theta_out = DISCON.pitch_coll_dem;
    Tgen_out = DISCON.gen_torque_dem;
    sim_status = DISCON.sim_status;
}

static int parse_worker_port(int argc, char** argv) {
    for (int i = 1; i < argc - 1; ++i) {
        if (strcmp(argv[i], "--worker-port") == 0) {
            return atoi(argv[i + 1]);
        }
    }
    return -1;
}

static std::string parse_worker_log_path(int argc, char** argv) {
    for (int i = 1; i < argc - 1; ++i) {
        if (strcmp(argv[i], "--worker-log") == 0) {
            return std::string(argv[i + 1]);
        }
    }
    return std::string();
}

static std::ofstream g_worker_log;
static bool g_worker_detailed_logging = false;

static void open_worker_log_file(const std::string& requested_path) {
    if (requested_path.empty()) {
        return;
    }
    g_worker_log.open(requested_path.c_str(), std::ios::out | std::ios::app);
}

static void log_worker(const std::string& msg) {
    if (!g_worker_log.is_open()) {
        return;
    }
    g_worker_log << msg << std::endl;
    g_worker_log.flush();
}

static void log_step_values_if_enabled(const StepRequest& req,
                                       double theta_out,
                                       double Tgen_out,
                                       int sim_status) {
    if (!g_worker_detailed_logging) {
        return;
    }

    std::ostringstream os;
    os << "step in: t=" << req.t
       << " vwind=" << req.vwind
       << " Tgen_in=" << req.Tgen_in
       << " om_rot=" << req.om_rot
       << " om_gen=" << req.om_gen
       << " theta_in=" << req.theta_in
       << " tow_fa_acc=" << req.tow_fa_acc
       << " tow_ss_acc=" << req.tow_ss_acc
       << " phi_rot=" << req.phi_rot
       << " | out: theta_out=" << theta_out
       << " Tgen_out=" << Tgen_out
       << " sim_status=" << sim_status;
    log_worker(os.str());
}

int main(int argc, char** argv) {
    std::string log_path = parse_worker_log_path(argc, argv);
    open_worker_log_file(log_path);
    log_worker("=== worker start ===");

    int port = parse_worker_port(argc, argv);
    if (port <= 0 || port > 65535) {
        log_worker("invalid worker port argument");
        fprintf(stderr, "Invalid --worker-port argument\n");
        return 2;
    }
    {
        std::ostringstream os;
        os << "worker port=" << port;
        log_worker(os.str());
    }

    std::string err;
    if (!init_socket_lib(err)) {
        log_worker(std::string("socket init failed: ") + err);
        fprintf(stderr, "Socket init failed: %s\n", err.c_str());
        return 3;
    }

    SocketHandle srv = socket(AF_INET, SOCK_STREAM, 0);
    if (srv == kInvalidSocket) {
        log_worker(std::string("socket() failed: ") + get_last_os_error());
        fprintf(stderr, "socket failed: %s\n", get_last_os_error().c_str());
        return 4;
    }

    int reuse = 1;
#ifdef _WIN32
    setsockopt(srv, SOL_SOCKET, SO_REUSEADDR, reinterpret_cast<const char*>(&reuse), sizeof(reuse));
#else
    setsockopt(srv, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));
#endif

    sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    addr.sin_port = htons(static_cast<uint16_t>(port));

    if (bind(srv, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != 0) {
        log_worker(std::string("bind() failed: ") + get_last_os_error());
        fprintf(stderr, "bind failed: %s\n", get_last_os_error().c_str());
        close_socket(srv);
        return 5;
    }
    log_worker("bind() ok");

    if (listen(srv, 1) != 0) {
        log_worker(std::string("listen() failed: ") + get_last_os_error());
        fprintf(stderr, "listen failed: %s\n", get_last_os_error().c_str());
        close_socket(srv);
        return 6;
    }
    log_worker("listen() ok, waiting for client");

    SocketHandle client = accept(srv, NULL, NULL);
    close_socket(srv);
    if (client == kInvalidSocket) {
        log_worker(std::string("accept() failed: ") + get_last_os_error());
        fprintf(stderr, "accept failed: %s\n", get_last_os_error().c_str());
        return 7;
    }
    log_worker("accept() ok, client connected");

    DISCON_Interface* DISCON = NULL;
    bool keep_running = true;

    while (keep_running) {
        uint32_t msg_type = 0;
        std::vector<uint8_t> payload;
        if (!recv_frame(client, msg_type, payload, err)) {
            log_worker(std::string("recv_frame failed: ") + err);
            break;
        }

        GenericResponse resp;
        resp.code = 0;
        resp.sim_status = 0;
        resp.theta_out = 0.0;
        resp.Tgen_out = 0.0;
        resp.message = "";
        uint32_t resp_type = msg_error;

        try {
            if (msg_type == msg_init_req) {
                log_worker("received init request");
                InitRequest req;
                if (!deserialize_init_request(payload, req)) {
                    throw std::runtime_error("Invalid init payload");
                }
                g_worker_detailed_logging = req.detailed_logging;
                if (g_worker_detailed_logging) {
                    std::ostringstream os;
                    os << "detailed logging enabled, dll_path='" << req.dll_path << "'"
                       << ", config_path='" << req.config_path << "'";
                    log_worker(os.str());
                }

                if (DISCON != NULL) {
                    delete DISCON;
                    DISCON = NULL;
                }

                if (!req.config_path.empty()) {
                    DISCON = new DISCON_Interface(req.dll_path, req.config_path);
                } else {
                    DISCON = new DISCON_Interface(req.dll_path);
                }
                log_worker("DISCON interface created");
                set_discon_params(*DISCON, req.params);
                if (DISCON->init()) {
                    resp.message = DISCON->getMessage();
                }
                log_worker("DISCON init done");

                resp.sim_status = DISCON->sim_status;
                resp_type = msg_init_resp;
            } else if (msg_type == msg_step_req) {
                log_worker("received step request");
                StepRequest req;
                if (!deserialize_step_request(payload, req)) {
                    throw std::runtime_error("Invalid step payload");
                }
                if (DISCON == NULL) {
                    throw std::runtime_error("Worker not initialized");
                }

                discon_step(*DISCON, resp.theta_out, resp.Tgen_out, resp.sim_status, resp.message, req);
                log_worker("step done");
                log_step_values_if_enabled(req, resp.theta_out, resp.Tgen_out, resp.sim_status);
                resp_type = msg_step_resp;
            } else if (msg_type == msg_shutdown_req) {
                log_worker("received shutdown request");
                if (DISCON != NULL) {
                    if (DISCON->finish()) {
                        resp.message = DISCON->getMessage();
                    }
                    delete DISCON;
                    DISCON = NULL;
                }
                resp.sim_status = -1;
                resp_type = msg_shutdown_resp;
                keep_running = false;
            } else {
                throw std::runtime_error("Unknown message type");
            }
        } catch (const std::exception& e) {
            resp.code = -1;
            resp.message = e.what();
            log_worker(std::string("exception: ") + e.what());
            if (DISCON != NULL) {
                resp.sim_status = DISCON->sim_status;
            }
            if (msg_type == msg_init_req) {
                resp_type = msg_init_resp;
            } else if (msg_type == msg_step_req) {
                resp_type = msg_step_resp;
            } else if (msg_type == msg_shutdown_req) {
                resp_type = msg_shutdown_resp;
            }
        }

        std::vector<uint8_t> out_payload = serialize_response(resp);
        if (!send_frame(client, resp_type, out_payload, err)) {
            log_worker(std::string("send_frame failed: ") + err);
            break;
        }
    }

    if (DISCON != NULL) {
        delete DISCON;
        DISCON = NULL;
    }
    close_socket(client);

#ifdef _WIN32
    WSACleanup();
#endif

    log_worker("worker exit");
    if (g_worker_log.is_open()) {
        g_worker_log.close();
    }

    return 0;
}

#endif
