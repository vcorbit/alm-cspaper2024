%% user  modifiable variables
clear all

traces.M2 = 1;
traces.CStoM2 = 2;
traces.M2toCS = 3;
traces.CS = 4;

blackflyStimeFactor = 1000000000;
windowStart = 10;

%% import all data:
%name tracesTS, videoTS, tracesToD, videoToD, videoData, and tracesData
%Get photometry trace file
[filename, pathname] = uigetfile('*.csv', 'Select Traces Data File');
animalID = filename(end-7:end-4);


%Change to directory that all data is in
cd (pathname);

%Load traces data csv files
tracesData = dlmread(filename);

%Load tracesTS
[filename, pathname] = uigetfile('*.csv', 'Select Traces Timestamp File');
%Load csv files
tracestime = dlmread(filename);
tracesTS = tracestime(:,1);
tracesToD = tracestime(1,2);

%Load videoTS
[filename, pathname] = uigetfile('*.csv', 'Select Video Timestamp File');
%Load csv files
videotime = dlmread(filename);
videoTS = videotime(:,1);
videoToD = videotime(1,2);

%% check for dropped frames
plot(tracesTS)
userInput = input('Are there dropped frames? Press 1 for yes, 2 for no: ');
disp(userInput)
close all
if userInput == 1
   dropFrameX = find(tracesTS==0);
   dropOffset = ceil(median(diff(tracesTS)));
   for x = 1:size(dropFrameX,1)
   tracesTS(dropFrameX(x,1),1) = tracesTS((dropFrameX(x,1)-1),1) + dropOffset;
   end
else
end
clear userInput dropFrameX dropOffset

%% Parse behavior data
[filename, pathname] = uigetfile('*.xlsx', 'Select Locomotion Data File');
%Change to directory that all data is in
cd (pathname);
%Load csv files
locxls = importdata(filename);


%get fieldnames of sheets
fnSheets = fieldnames(locxls.data);

%get time of led on

%get timestamps of locomotion
locTS = locxls.data.(fnSheets{1,1})(:,1);
locActive = locxls.data.(fnSheets{1,1})(:,12);
%% find timestamps where locomotion goes from stop to start

locDiff = diff(locActive);
locOnsetidx = find(locDiff == 1);
locOffsetidx = find(locDiff == -1);

locOnsetTS = locTS(locOnsetidx);
locOffsetTS = locTS(locOffsetidx);
%% get session start frame as found in Noldus
ledon = locxls.data.(fnSheets{2,1})(1,1);

sessionStartFrame = ceil(30*ledon);

%% plot traces to determine order

plot(tracesData(1:3:end, 1));                                            %plot one third of M2 interleaved data in blue
hold on
plot(tracesData(2:3:end, 1));                                            %plot other third of M2 interleaved data in red
plot(tracesData(3:3:end, 1)); 
 sigID = input('Which signal is the M2 gCamp? 1=blue, 2=red, 3=yellow');

gsig = sigID;
if gsig==1
    rsig = 2;
    bsig = 3;
elseif gsig==2
    rsig = 3;
    bsig = 1;
elseif gsig==3
    rsig = 1;
    bsig = 2;
end
close all

%% separate traces
%Get trace name
fnTraces = fieldnames(traces);

%Separate traces and assign to 'signal' for each ROI
for t=1:size(fnTraces,1)
signal.(fnTraces{t}).green = tracesData((gsig:3:end),t);
signal.(fnTraces{t}).red = tracesData((rsig:3:end),t);
signal.(fnTraces{t}).blue = tracesData((bsig:3:end),t);

%Plot all 3 channels in each ROI for visual inspection
figure
hold on
plot(signal.(fnTraces{t}).green);
plot(signal.(fnTraces{t}).red);
plot(signal.(fnTraces{t}).blue);
title(cellstr(fnTraces{t}));
end

%Separate timestamps by channel
tracesTSsep.green = tracesTS(gsig:3:end);
tracesTSsep.red = tracesTS(rsig:3:end);
tracesTSsep.blue = tracesTS(bsig:3:end);

%% zero timestamps and convert to seconds
fnChannels = fieldnames(tracesTSsep);

%Separate timestamps and convert to seconds and zeros to first timestamp
for c=1:size(fnChannels,1)
tracesTSzero.(fnChannels{c}) = timestampDecoder(tracesTSsep.(fnChannels{c}))';                                 %run Blackfly FP camera timestamps through timestampDecoder function; converts binary cycled numbers into seconds and zeros it to first timestamp
end

videoTSzero = ((videoTS-videoTS(1,1))/blackflyStimeFactor)';                %convert Blackfly S camera timestamps from nanoseconds to seconds and zero to first timestamp
tracesToDsec = tracesToD/1000;                                              %convert first Bonsai time-of-day timestamp for Blackfly FP camera to seconds
videoToDsec = videoToD/1000;                                                %convert first Bonsai time-of-day timestamp for Blackfly S camera to seconds

%% align timestamps by using first Bonsai timestamps

for c=1:size(fnChannels,1)
tracesTSToD.(fnChannels{c}) = tracesTSzero.(fnChannels{c}) + tracesToDsec;                                  %add first Bonsai Blackfly FP ToD timestamp to whole series; puts timestamps on same time scale
end

videoTSToD = videoTSzero + videoToDsec;                                     %add first Bonsai Blackfly S ToD timestamp to whole series; puts timestamps on same time scale


%% re-zero timestamps based on session start

for c=1:size(fnChannels,1)
subTS.traces.(fnChannels{c}) = (tracesTSToD.(fnChannels{c}) - (videoTSToD(1,sessionStartFrame)));           %subtract the value of the corresponding start frame in the video timestamp vector from all values of the traces timestamp series
end

subTS.video = (videoTSToD - (videoTSToD(1,sessionStartFrame)));             %subtract the value of the corresponding start frame in the video timestamp vector from all values of the video timestamp series

%add to all behavior timestamps
locTSsub = (locTS + subTS.video(1,1))';                             %add first value of properly aligned video timestamp to video time series from Noldus to transform to proper time stamps
locOnsetTSsub = (locOnsetTS + subTS.video(1,1))';
locOffsetTSsub = (locOffsetTS + subTS.video(1,1))';
%% get timestamps within range

%Get last timestamp of traces, subtract window to find latest grooming stop
sessionEnd = subTS.traces.green(end);
windowEnd = sessionEnd-windowStart;

%put all timestamps within range
locOnsetTSsub = locOnsetTSsub(find(locOnsetTSsub> windowStart & locOnsetTSsub < windowEnd));
locOffsetTSsub = locOffsetTSsub(find(locOffsetTSsub> windowStart & locOffsetTSsub < windowEnd));

%% crop camera timestamps to session start and end

%cycle through subTS fieldnames (traces and video) to create new vectors with only the values between the session start and end
for c=1:size(fnChannels,1)
idx.traces.(fnChannels{c}) = subTS.traces.(fnChannels{c})>= 0 & subTS.traces.(fnChannels{c})<= sessionEnd;
alignTS.traces.(fnChannels{c}) = subTS.traces.(fnChannels{c})(idx.traces.(fnChannels{c}));
end

idx.video = subTS.video >= 0 & subTS.video<= sessionEnd;
alignTS.video = subTS.video(idx.video);


%% crop traces data to session start and end
fnTraces = fieldnames(signal);                                              %get fieldnames of signal

for t = 1:size(fnTraces,1)                                                  %cycle through fnTrace fieldnames to create new vectors with values between session start and end
    for c=1:size(fnChannels,1)
       alignTraces.(fnTraces{t}).(fnChannels{c})= signal.(fnTraces{t}).(fnChannels{c})(idx.traces.(fnChannels{c}));   %use traces index from timestamp alignment to create new vectors
    end
end

%% clear variables and save data
clearvars -except alignTS alignTraces locOnsetTSsub locOffsetTSsub animalID

save([animalID, '-alignedMvt.mat']);

