import ctypes
import numpy
from time import time

libT1 = ctypes.CDLL("./libT1_dll_via_cpp.so")
libT1.init()

x = numpy.ctypeslib.ndpointer(dtype=numpy.float64, ndim=1, flags="C")
u = numpy.ctypeslib.ndpointer(dtype=numpy.float64, ndim=1, flags="C")
x_dot = numpy.ctypeslib.ndpointer(dtype=numpy.float64, ndim=1, flags="C")

libT1.eval_f.argtypes = [x, u, x_dot]
libT1.eval_f.restype = None

def eval_f(x, u):
    x_dot = numpy.empty(shape=(4), dtype=numpy.float64)
    libT1.eval_f(x.astype(numpy.float64), u.astype(numpy.float64), x_dot)
    
    return x_dot

x = numpy.array([0, 0, 0, 1000./97./30.*numpy.pi])
u = numpy.array([12., 10000., 0])

print(eval_f(x, u))

