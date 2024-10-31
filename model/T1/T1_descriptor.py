import ctypes
import numpy
import os

os.add_dll_directory(os.getcwd())
os.add_dll_directory(os.path.join(os.getcwd(), "../../simulator"))
os.add_dll_directory(os.path.join(os.getcwd(), "../../5MW_Baseline"))
os.add_dll_directory("C:/ProgramData/MATLAB/SupportPackages/R2023b/3P.instrset/mingw_w64.instrset/bin")

libT1 = ctypes.CDLL("T1_dll_via_cpp.dll")
libT1.init()


x_type = numpy.ctypeslib.ndpointer(dtype=numpy.float64, ndim=1, flags="C")
u_type = numpy.ctypeslib.ndpointer(dtype=numpy.float64, ndim=1, flags="C")
x_dot_type = numpy.ctypeslib.ndpointer(dtype=numpy.float64, ndim=1, flags="C")

libT1.eval_f.argtypes = [x_type, u_type, x_dot_type]
libT1.eval_f.restype = None

def eval_f(x, u):
    x_dot = numpy.empty(shape=(4), dtype=numpy.float64)
    libT1.eval_f(x.astype(numpy.float64), u.astype(numpy.float64), x_dot)
    
    return x_dot

libDISCON = ctypes.CDLL("DISCON_py_dll.dll")
libDISCON.init.argtypes = [ctypes.c_char_p]
libDISCON.step.argtypes = [ctypes.c_double, ctypes.c_double, ctypes.c_double, ctypes.c_double, ctypes.c_double, ctypes.c_double, ctypes.c_double, ctypes.c_double, ctypes.c_double, ctypes.POINTER(ctypes.c_double), ctypes.POINTER(ctypes.c_double), ctypes.POINTER(ctypes.c_int)]

discon_path = "../../5MW_Baseline/DISCON.dll"
b_discon_path = discon_path.encode('utf-8')

def DISCON_step(t, vwind, Tgen_in, om_rot, om_gen, theta_in, tow_fa_acc, tow_ss_acc, phi_rot):
    theta_out = (ctypes.c_double * 1)()
    Tgen_out =  (ctypes.c_double * 1)()
    sim_status =  (ctypes.c_int * 1)()
    
    libDISCON.step(t, vwind, Tgen_in, om_rot, om_gen, theta_in, tow_fa_acc, tow_ss_acc, phi_rot, theta_out, Tgen_out, sim_status)
    
    return theta_out[0], Tgen_out[0], sim_status[0]



GBRatio = 97.
vwind = 12.

x = numpy.array([0, 0, 0, 1000./GBRatio/30.*numpy.pi])
u = numpy.array([vwind, 10000., 0])
ts = 0.01
t = 0

libDISCON.init(b_discon_path)

for i in range(0, 1000):
    Tgen_meas = u[1]
    om_rot= x[3]
    om_gen= x[3]*GBRatio
    theta_meas = -u[2]
    tow_fa_acc = 0
    tow_ss_acc = 0
    phi_rot= x[1]
    
    theta_set, Tgen_set, status = DISCON_step(t, vwind, Tgen_meas, om_rot, om_gen, theta_meas, tow_fa_acc, tow_ss_acc, phi_rot)
    if status==-1:
        print('DISCON finished')
        break

    u[0] = vwind
    u[1] = Tgen_set
    u[2] = -theta_set
    
    x_dot = eval_f(x, u)
    
    x = x + ts*x_dot
    t = t + ts
    
    print(u, x)

libDISCON.terminate()


