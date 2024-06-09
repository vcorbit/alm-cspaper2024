# -*- coding: utf-8 -*-
"""
Created on Thu Dec  3 16:05:45 2020
#takes in SLEAP posture tracking data and manual behavior scoring data and align/combine

@author: vlcor
"""
import os
import pandas as pd
import numpy as np
import glob
import h5py
import math
import pickle


#go to folder where SLEAP-tracking data for behavior videos is stored
datafolder = 'T:\SLEAP\CSstimFIXED'
os.chdir(datafolder)

#load scoring data from Observer
eventlog = 'CsStimCohort2EventLogAll_SEAAdded.xlsx'
eventdata = pd.ExcelFile(eventlog)
animalsheets = eventdata.sheet_names

#go through each sheet (animal)
LEDonall = {}
facegroomall = {}
bodygroomall = {}
pseudogroomall = {}
for animal in animalsheets:
    eventdf = eventdata.parse(animal)
    eventnames = eventdf['Behavior']
    timestamps = eventdf['Time_Relative_sf']
    
    #find LED on time
    LEDcurr = eventnames.str.match('LED on')
    LEDcurr = np.where(LEDcurr==True)[0]
    #get timestamp for LED on
    sessionstart = float(timestamps.loc[LEDcurr])
    LEDonall[animal] = sessionstart
    
    #find face grooming times
    facegroomidx = eventnames.str.contains('face grooming', case=False)
    facegroomidx = np.where(facegroomidx==True)[0]
    facegroomtimes = list(timestamps.loc[facegroomidx])
    facegroomall[animal] = facegroomtimes
    
    #find body grooming times
    bodygroomidx = eventnames.str.contains('body grooming', case=False)
    bodygroomidx = np.where(bodygroomidx==True)[0]
    bodygroomtimes = list(timestamps.loc[bodygroomidx])
    bodygroomall[animal] = bodygroomtimes
    
    #find pseudogrooming times
    pgroomidx = eventnames.str.contains('pseudogrooming', case=False)
    pgroomidx = np.where(pgroomidx==True)[0]
    pgroomtimes = list(timestamps.loc[pgroomidx])
    pseudogroomall[animal] = pgroomtimes

#load joint data for each animal into a big array
#keep track of animal names
h5path = os.path.join(datafolder, '*.h5')
h5files = sorted(glob.glob(h5path))

#function for interpolating nans
def interp_nans(joints):
    jointsfix = joints
    for c in range(0,2):
        for s in range(0,joints.shape[1]):
            jointstemp = joints[c,s,:]
            jointsdf = pd.DataFrame(jointstemp)
            jointsfilled = jointsdf.interpolate(method = 'linear', axis=0, limit_direction='both')
            currjoints = jointsfilled.to_numpy()
            jointsfix[c,s,:] = currjoints[:,0]
    return jointsfix

def rotate(x,y,x0,y0,theta): #rotate x,y around xo,yo by theta (rad)
    xr=math.cos(theta)*(x-x0)-math.sin(theta)*(y-y0) + x0
    yr=math.sin(theta)*(x-x0)+math.cos(theta)*(y-y0) + y0
    return [xr,yr]

h5dataall = {}
nanlocs = {}
velall = {}
for file in h5files:
    f = h5py.File(file, 'r')
    animal = file[21:-16]
    h5data = np.array(f['tracks'])
    h5data = h5data.reshape([h5data.shape[1], h5data.shape[2],h5data.shape[3]])
    #reduce to only the joints we care about 1=snout, 2=bodycenter, 0=tailbase, 3=pawR, 4=pawL
    jointidx = [0,1,2,3,4]
    jointsreduced = np.empty([h5data.shape[0], len(jointidx), h5data.shape[2]])
    for j in range(len(jointidx)):
        jointsreduced[:,j,:] = h5data[:,jointidx[j], :]
    
    #find where nans are
    nanloc = np.argwhere(np.isnan(jointsreduced[0,:,:]))
    nanlocs[animal] = nanloc
    
    #interpolate nans
    jointsfixed = interp_nans(jointsreduced)
    
    #calculate velocity based on body center
    centerx = jointsfixed[0,1,:]
    centery = jointsfixed[1,1,:]
    vel = np.sqrt(np.square(np.diff(centerx))+np.square(np.diff(centery)))
    vel = np.append(vel, vel[-1])
    velall[animal] = vel
    
    bodyangle = np.arctan2([jointsfixed[1,1,:]-jointsfixed[1,2,:]], [jointsfixed[0,1,:]-jointsfixed[0,2,:]])
    rotationangle = bodyangle - (math.pi/2)
    
    #subtract tailbase location to center
    jointscenter = np.empty(jointsfixed.shape)
    for joint in range(jointsfixed.shape[1]):
        jointscenter[0,joint,:] = jointsfixed[0,joint,:] - jointsfixed[0,2,:]
        jointscenter[1,joint,:] = jointsfixed[1,joint,:] - jointsfixed[1,2,:]
    
    #rotate joints
    x0 = 0
    y0 = 0
    jointsrotated = np.empty(jointscenter.shape)
    for i in range(0, jointscenter.shape[2]):
        [xnew, ynew] = rotate(jointscenter[0,:,i], jointscenter[1,:,i], x0, y0,-rotationangle[0,i])
        jointsrotated[:,:,i] = [xnew, ynew]
    
    h5dataall[animal] = jointsrotated

output = open('CSstimGroomData-it2.pkl', 'wb')
pickle.dump([h5dataall, LEDonall, facegroomall, bodygroomall, pseudogroomall, nanlocs, velall], output)
output.close()
