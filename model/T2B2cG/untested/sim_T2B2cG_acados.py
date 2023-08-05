#
# Copyright 2019 Gianluca Frison, Dimitris Kouzoupis, Robin Verschueren,
# Andrea Zanelli, Niels van Duijkeren, Jonathan Frey, Tommaso Sartor,
# Branimir Novoselnik, Rien Quirynen, Rezart Qelibari, Dang Doan,
# Jonas Koenemann, Yutao Chen, Tobias Schöls, Jonas Schlagenhauf, Moritz Diehl
#
# This file is part of acados.
#
# The 2-Clause BSD License
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.;
#

import sys

from acados_template import AcadosSim, AcadosSimSolver
from T2B2cG_acados import T2B2cG_acados
import numpy as np

from pyFAST.input_output import FASTOutputFile
import pandas as pd
import pickle

filenm= 'params.txt'

params = []
row = []
rows = []
p = []
with open(filenm, 'r') as fin:
    for line in fin:
        for v_str in line.split():
            try:
                v = float(v_str)
                row.append(v)
            except:
                mat = np.asarray(rows)
                p = list(mat.flatten('F'))
                params += p
                row = []
                rows = []
            
        rows.append(row)
        row= []
        
    mat = np.asarray(rows)
    p = list(mat.flatten('F'))
    params += p



df = FASTOutputFile('/home/jgeisler/Temp/FASTsim/sim1_30/1p_URef-10_RandSeed1-1_T2B2cG.outb').toDataFrame()
time  = df['Time_[]']
RtVAvgxh = df['RtVAvgxh_[/]']   # input vwind = RtVAvgxh
HSShftTq = df['HSShftTq_[N]']   # input Tgen = HSShftTq*1000.0
BlPitchC = df['BlPitchC_[e]']   # input theta = BlPitchC * -np.pi/180.0

Q_TFA1 = df['Q_TFA1_[]']        # state tow_fa = Q_TFA1
Q_TSS1 = df['Q_TSS1_[]']        # state tow_ss = -Q_TSS1
QD_TFA1 = df['QD_TFA1_[/]']     # state tow_fa_d = QD_TFA1
QD_TSS1 = df['QD_TSS1_[/]']     # state tow_ss_d = -QD_TSS1

Q_BF1 = df['Q_BF1_[]']          # state bld_flp = Q_BF1
Q_BE1 = df['Q_BE1_[]']          # state bld_edg = Q_BE1
QD_BF1 = df['QD_BF1_[/]']       # state bld_flp_d = QD_BF1
QD_BE1 = df['QD_BE1_[/]']       # state bld_edg_d = QD_BE1

LSSTipPxa = df['LSSTipPxa_[e]'] # state phi_rot = LSSTipPxa*np.pi/180.0
Q_GeAz = df['Q_GeAz_[a]']       # state phi_gen = (Q_GeAz-np.pi*3.0/2.0)*97.0
LSSTipVxa = df['LSSTipVxa_[p]'] # state phi_rot_d = LSSTipVxa*np.pi/30.0
HSShftV = df['HSShftV_[p]']     # state phi_gen_d = HSShftV*np.pi/30.0


sim = AcadosSim()

# export model 
model = T2B2cG_acados()

# set model_name 
sim.model = model

Tf = time[1]-time[0]
nx = model.x.size()[0]
nu = model.u.size()[0]
N = len(time)

# set simulation time
sim.solver_options.T = Tf
# set options
sim.solver_options.integrator_type = 'IRK'
sim.solver_options.num_stages = 2
sim.solver_options.num_steps = 1
sim.solver_options.newton_iter = 1 # for implicit integrator

sim.parameter_values = np.array(params)

# create
acados_integrator = AcadosSimSolver(sim)

simX = np.ndarray((N+1, nx))


simX[0,:] = np.array([Q_TFA1[0], -Q_TSS1[0], Q_BF1[0], Q_BE1[0], LSSTipPxa[0]*np.pi/180.0, (Q_GeAz[0]-np.pi*3.0/2.0)*97.0, QD_TFA1[0], -QD_TSS1[0], QD_BF1[0], QD_BE1[0], LSSTipVxa[0]*np.pi/30.0, HSShftV[0]*np.pi/30.0])

for i in range(N):
    acados_integrator.set("u", np.array([RtVAvgxh[i], HSShftTq[i]*1000.0, BlPitchC[i] * -np.pi/180.0]))
    acados_integrator.set("x", simX[i,:])
    # initialize IRK
    if sim.solver_options.integrator_type == 'IRK':
        acados_integrator.set("xdot", np.zeros((nx,)))

    # solve
    status = acados_integrator.solve()
    # get solution
    simX[i+1,:] = acados_integrator.get("x")

    if status != 0:
        raise Exception('acados returned status {}. Exiting.'.format(status))
    
print('Done with Simualtion')

with open("/home/jgeisler/Temp/FASTsim/sim1_30/1p_URef-10_RandSeed1-1_T2B2cG.pickle","wb") as f:
    pickle.dump( simX, f)

df = pd.DataFrame()
df['Time_[]'] = time
df['Q_TFA1_[]'] = simX[0:-1, 0]        # state tow_fa = Q_TFA1
df['Q_TSS1_[]'] = -simX[0:-1, 1]       # state tow_ss = -Q_TSS1
df['QD_TFA1_[/]'] = simX[0:-1, 6]      # state tow_fa_d = QD_TFA1
df['QD_TSS1_[/]'] = -simX[0:-1, 7]     # state tow_ss_d = -QD_TSS1

df['Q_BF1_[]'] = simX[0:-1, 2]         # state bld_flp = Q_BF1
df['Q_BE1_[]'] = simX[0:-1, 3]         # state bld_edg = Q_BE1
df['QD_BF1_[/]'] = simX[0:-1, 8]       # state bld_flp_d = QD_BF1
df['QD_BE1_[/]'] = simX[0:-1, 9]       # state bld_edg_d = QD_BE1

df['LSSTipPxa_[e]'] = simX[0:-1, 4]/np.pi*180.0        # state phi_rot = LSSTipPxa*np.pi/180.0
df['Q_GeAz_[a]'] = simX[0:-1, 5]/97.0 + np.pi*3.0/2.0  # state phi_gen = (Q_GeAz-np.pi*3.0/2.0)*97.0
df['LSSTipVxa_[p]'] = simX[0:-1, 10]/np.pi*30.0        # state phi_rot_d = LSSTipVxa*np.pi/30.0
df['HSShftV_[p]'] = simX[0:-1, 11]/np.pi*30.0          # state phi_gen_d = HSShftV*np.pi/30.0

f = FASTOutputFile()
f.writeDataFrame(df, '/home/jgeisler/Temp/FASTsim/sim1_30/1p_URef-10_RandSeed1-1_T2B2cG_py.outb')
