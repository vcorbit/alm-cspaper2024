# -*- coding: utf-8 -*-
"""
Original file generated by Colab and converted to .py
#takes preprocessed posture tracking data and calculates features for classifier model

"""

#load packages you'll need
import os
import pandas as pd
import numpy as np
import glob
import h5py
import math
import pickle
from scipy.stats import zscore


#load data
datafile = open(r'filename', 'rb')
data = pickle.load(datafile)
h5dataall = data[0]
LEDonall = data[1]
facegroomstartall = data[2]
facegroomstopall = data[3]
bodygroomstartall = data[4]
bodygroomstopall = data[5]
pgroomstartall = data[6]
pgroomstopall = data[7]
stereostartall = data[8]
stereostopall = data[9]
rearstartall = data[10]
rearstopall = data[11]
nanlocs = data[12]
velall = data[13]

#choose an animal
animal = '5045'

#get all the data for this animal
facegroomstart = facegroomstartall[animal]
facegroomstop = facegroomstopall[animal]
bodygroomstart = bodygroomstartall[animal]
bodygroomstop = bodygroomstopall[animal]
pgroomstart = pgroomstartall[animal]
pgroomstop = pgroomstopall[animal]
stereostart = stereostartall[animal]
stereostop = stereostopall[animal]
LEDon = LEDonall[animal]
joints = h5dataall[animal]
nanloc = nanlocs[animal]
vel = velall[animal]

print(stereostart)

#using groom start and stop times, create a matrix of length = samples (frames) and denote what was happening in that frame
#not grooming = 0
#face grooming = 1
#body grooming  = 2
#pseudogrooming = 3
#stereotypy = 4

labels = np.zeros([joints.shape[2], 1])

for f in range(0, len(facegroomstart)):
    startidx = round(40*facegroomstart[f])
    stopidx = round(40*facegroomstop[f])
    labels[startidx:stopidx] = 1

for f in range(0, len(bodygroomstart)):
    startidx = round(40*bodygroomstart[f])
    stopidx = round(40*bodygroomstop[f])
    labels[startidx:stopidx] = 2

for f in range(0, len(pgroomstart)):
    startidx = round(40*pgroomstart[f])
    stopidx = round(40*pgroomstop[f])
    labels[startidx:stopidx] = 3

for f in range(0, len(stereostart)):
    startidx = round(40*stereostart[f])
    stopidx = round(40*stereostop[f])
    labels[startidx:stopidx] = 4

stereoidx = sum((labels == 4))
print(stereoidx)

######### calculate features!! #0=snout 1=bodycenter 2=tailbase 3=pawR 4=pawL
#pawR distance from snout (x)
pawR2snoutx = joints[0,3,:] - joints[0,0,:]

#pawR distance from snout (y)
pawR2snouty = joints[1,3,:] - joints[1,0,:]

#pawL distance from snout (x)
pawL2snoutx = joints[0,4,:] - joints[0,0,:]

#pawL distance from snout (y)
pawL2snouty = joints[1,4,:] - joints[1,0,:]

#body center distance from snout (x)
center2snoutx = joints[0,1,:] - joints[0,0,:]

#body center distance from snout (y)
center2snouty = joints[1,1,:] - joints[1,0,:]

#body center distance from tailbase (x)
center2tailx = joints[0,1,:] - joints[0,2,:]

#body center distance from tailbase (y)
center2taily = joints[1,1,:] - joints[1,2,:]

#snout distance from tailbase (x)
snout2tailx = joints[0,0,:] - joints[0,2,:]

#snout distance from tailbase (y)
snout2taily = joints[1,0,:] - joints[1,2,:]

#angle of snout off body center
snoutangle = np.arctan2([joints[1,0,:]-joints[1,1,:]], [joints[0,0,:]-joints[0,1,:]])
snoutangle = (math.pi/2) - snoutangle.T[:,0]

#angular velocity of snout relative to body center
snoutvel = np.diff(snoutangle)
snoutvel = np.append(snoutvel, snoutvel[-1])

#paw to paw distance (x)
paw2pawx = joints[0,3,:] - joints[0,4,:]

#paw to paw distance (y)
paw2pawy = joints[1,3,:] - joints[1,4,:]

##assemble feature matrix
inputfeatures = np.column_stack((pawR2snoutx, pawR2snouty, pawL2snoutx, pawL2snouty, center2snoutx, center2snouty, center2tailx, center2taily,
                                snout2tailx, snout2taily, snoutangle, snoutvel, paw2pawx, paw2pawx, vel))

#save data
import shutil
savename = '5045modelinputs.pkl'
output = open(savename, 'wb')
pickle.dump([inputfeatures, labels], output)
output.close()