# -*- coding: utf-8 -*-
"""
Created on Thu Dec  3 16:05:45 2020

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
datafolder = 'T:\SLEAP\M2-CSStimAllUsed'
os.chdir(datafolder)

#load scoring data from Observer
eventlog = 'M2CSStimEventLogsUpdated.xlsx'
eventdata = pd.ExcelFile(eventlog)
animalsheets = eventdata.sheet_names

#get laser on times
laseriti = np.asarray([350, 300, 250, 250, 350, 300, 350, 300, 350, 300, 350, 300, 350, 350, 300, 250, 300, 250, 250, 250, 350, 300, 300, 300, 300, 350, 350, 250, 350, 350, 250, 300, 300, 250, 300, 250, 250, 250, 250, 350, 250, 350, 250, 250, 300, 300, 250, 350, 300, 350]);
pulsewidth = 200
pulseN=20
firstlaseron = np.asarray(600)
tempITIs = np.cumsum(laseriti + pulsewidth);
laseron = 100*np.insert(tempITIs+int(firstlaseron), 0, int(firstlaseron), axis=0);
laseron = laseron[0:pulseN]

#go through each sheet (animal)
LEDonall = {}
facegroomstartall = {}
facegroomstopall = {}
bodygroomstartall = {}
bodygroomstopall = {}
pgroomstartall = {}
pgroomstopall = {}
stereostartall = {}
stereostopall = {}
rearstartall = {}
rearstopall = {}
velall = {}
for sheet in animalsheets:
    eventdf = eventdata.parse(sheet)
    eventnames = eventdf['Behavior']
    timestamps = eventdf['Time_Relative_sf']
    
    sheetsplit = sheet.split('Test')
    animal = sheetsplit[0]
    
    #find LED on time
    LEDcurr = eventnames.str.match('LED ON')
    LEDcurr = np.where(LEDcurr==True)[0]
    LEDfirst = LEDcurr[0]
    #get timestamp for LED on
    sessionstart = float(timestamps.loc[LEDfirst])
    LEDonall[animal] = sessionstart
    
    #get times for laser on in thise animal
    laseroncurr = sessionstart+(laseron/1000)
    
    #find face grooming times
    facegroomidx = eventnames.str.contains('face grooming', case=False)
    facegroomidx = np.where(facegroomidx==True)[0]
    facegroomtimes = np.array(timestamps.loc[facegroomidx])
    
    #find body grooming times
    bodygroomidx = eventnames.str.contains('body grooming', case=False)
    bodygroomidx = np.where(bodygroomidx==True)[0]
    bodygroomtimes = np.array(timestamps.loc[bodygroomidx])

    #find stereotypiy times
    stereoidx = eventnames.str.contains('stereotypic behavior', case=False)
    stereoidx = np.where(stereoidx==True)[0]
    stereotimes = list(timestamps.loc[stereoidx])
    stereostart = np.array(stereotimes[0::2])
    stereostop = np.array(stereotimes[1::2])
    stereostartall[animal] = stereostart
    stereostopall[animal] = stereostop
    
    #find stereotypiy times
    rearidx = eventnames.str.contains('rearing', case=False)
    rearidx = np.where(rearidx==True)[0]
    reartimes = list(timestamps.loc[rearidx])
    rearstart = np.array(reartimes[0::2])
    rearstop = np.array(reartimes[1::2])
    rearstartall[animal] = rearstart
    rearstopall[animal] = rearstop
    
    ##identify laser-evoked grooming times as "pseudogroom"
    laseroffcurr = laseroncurr+20
    
    facestart = np.array(facegroomtimes[0::2])
    facestop = np.array(facegroomtimes[1::2])
    bodystart = np.array(bodygroomtimes[0::2])
    bodystop = np.array(bodygroomtimes[1::2])

    pgroomstart = np.array([])
    pgroomstop = np.array([])
    for i in range(laseroncurr.shape[0]):
        ontime = laseroncurr[i]
        offtime = laseroffcurr[i]
        
        f2pstartidx = (facestart>ontime) & (facestart<offtime)
        f2pstartidx = np.where(f2pstartidx==True)[0]
        boutN = f2pstartidx.size
        #check if there are any instances of laser-evoked face grooming
        if boutN != 0:
            #get associated stop times
            pgroomstart = np.append(pgroomstart, facestart[f2pstartidx])
            pgroomstop = np.append(pgroomstop, facestop[f2pstartidx])
            
            facestart = np.delete(facestart, f2pstartidx)
            facestop = np.delete(facestop, f2pstartidx)
            
        b2pstartidx = (bodystart>ontime) & (bodystart<offtime)
        b2pstartidx = np.where(b2pstartidx==True)[0]
        boutN = b2pstartidx.size
        #check if there are any instances of laser-evoked face grooming
        if boutN != 0:
            #get associated stop times
            pgroomstart = np.append(pgroomstart, bodystart[b2pstartidx])
            pgroomstop = np.append(pgroomstop, bodystop[b2pstartidx])
            
            bodystart = np.delete(bodystart, b2pstartidx)
            bodystop = np.delete(bodystop, b2pstartidx)
    
    #organize and clump grooming bouts together
    pgroomstart = np.sort(pgroomstart)
    pgroomstop = np.sort(pgroomstop)
    #go through each stop time and see how far it is from the next start
    thresh = 1
    startdeletei = []
    stopdeletei = []
    for stopi in range((pgroomstop.shape[0]-1)):
        currstop = pgroomstop[stopi]
        nextstart = pgroomstart[stopi+1]
        
        if nextstart-currstop < thresh:
            startdeletei.append((stopi+1))
            stopdeletei.append(stopi)
        
    #delete timestamps that are below threshold
    pgroomstartcont = np.delete(pgroomstart, startdeletei)
    pgroomstopcont = np.delete(pgroomstop, stopdeletei)
    
    facegroomstartall[animal] = facestart
    facegroomstopall[animal] = facestop
    bodygroomstartall[animal] = bodystart
    bodygroomstopall[animal] = bodystop
    pgroomstartall[animal] = pgroomstartcont
    pgroomstopall[animal] = pgroomstopcont

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
    
    filesplit = file.split('Test')
    animal = filesplit[0][26:]
    
    
    h5data = np.array(f['tracks'])
    h5data = h5data.reshape([h5data.shape[1], h5data.shape[2],h5data.shape[3]])
    #reduce to only the joints we care about 1=bodycenter, 2=snout, 0=tailbase, 3=pawR, 4=pawL
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
    centerx = jointsfixed[0,0,:]
    centery = jointsfixed[1,0,:]
    vel = np.sqrt(np.square(np.diff(centerx))+np.square(np.diff(centery)))
    vel = np.append(vel, vel[-1])
    velall[animal] = vel
    
    bodyangle = np.arctan2([jointsfixed[1,0,:]-jointsfixed[1,2,:]], [jointsfixed[0,0,:]-jointsfixed[0,2,:]])
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
    
#    t=3000
#    for j in range(5):
#        plt.scatter(jointsreduced[0,j,t], jointsreduced[1,j,t], color = colors[j])
#    plt.show()
#    
#    fig, ax = plt.subplots()
#    ax.scatter(jointsreduced[0,:,t], jointsreduced[1,:,t])
#    nodes = ['snout', 'body center', 'tailbase', 'forepawR', 'forepawL']
#    for i, txt in enumerate(nodes):
#        ax.annotate(txt, (jointsreduced[0,i,t], jointsreduced[1,i,t]))
    
    h5dataall[animal] = jointsrotated

output = open('M2-CSStimGroomData.pkl', 'wb')
pickle.dump([h5dataall, LEDonall, facegroomstartall, facegroomstopall, bodygroomstartall, bodygroomstopall, pgroomstartall, pgroomstopall, stereostartall, stereostopall, rearstartall, rearstopall, nanlocs, velall], output)
output.close()
