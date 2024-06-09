%% turns aligned calcium data into new structure for further analysis
%% separates and labels blue, green, and red channels of calcium data
%% preprocesses/normalizes calcium traces

clear all

%%variables of note
%alignTraces: calcium data for each sensor that's cropped to be the same timespan as behavior
%alignTS: associated timestamps of calcium data

[filename, pathname] = uigetfile('Select Aligned Traces File', 'MultiSelect', 'on');

%Change to directory that data is in
cd (pathname);

files = size(filename, 2);

%% go through all files
for f=1:files
    
    load(filename{f});
% Reassign important traces to new structure for further analysis
fnRegion = fieldnames(alignTraces);
fnTraces = fieldnames(alignTraces.(fnRegion{1}));

if size(fnTraces, 1) == 3
for r=1:size(fnRegion,1)
    traces.isosbestic.(fnRegion{r}) = alignTraces.(fnRegion{r}).blue;
    traces.signalG.(fnRegion{r}) = alignTraces.(fnRegion{r}).green;
    traces.signalR.(fnRegion{r}) = alignTraces.(fnRegion{r}).red;
end
else
    for r=1:size(fnRegion,1)
    traces.isosbestic.(fnRegion{r}) = alignTraces.(fnRegion{r}).blue;
    traces.signalG.(fnRegion{r}) = alignTraces.(fnRegion{r}).green;
    end
end

%% Make isobestic and signal same size
for r = 1:size(fnRegion,1)
    if size(traces.isosbestic.(fnRegion{r}),1) ~= size(traces.signalG.(fnRegion{r}),1)
        %get minimum size of trace
        minlength = min([size(traces.isosbestic.(fnRegion{r}),1), size(traces.signalG.(fnRegion{r}),1)]);
        traces.isosbestic.(fnRegion{r})=traces.isosbestic.(fnRegion{r})(1:minlength,:);
        traces.signalG.(fnRegion{r})=traces.signalG.(fnRegion{r})(1:minlength,:);
    end
    
    if size(fnTraces, 1) == 3
    if size(traces.isosbestic.(fnRegion{r}),1) ~= size(traces.signalR.(fnRegion{r}),1)
        minlength = min([size(traces.isosbestic.(fnRegion{r}),1), size(traces.signalR.(fnRegion{r}),1)]);
        traces.isosbestic.(fnRegion{r})=traces.isosbestic.(fnRegion{r})(1:minlength,:);
        traces.signalR.(fnRegion{r})=traces.signalR.(fnRegion{r})(1:minlength,:);
    end
    end
    
    %check again after doing red
    if size(traces.isosbestic.(fnRegion{r}),1) ~= size(traces.signalG.(fnRegion{r}),1)
        %get minimum size of trace
        minlength = min([size(traces.isosbestic.(fnRegion{r}),1), size(traces.signalG.(fnRegion{r}),1)]);
        traces.isosbestic.(fnRegion{r})=traces.isosbestic.(fnRegion{r})(1:minlength,:);
        traces.signalG.(fnRegion{r})=traces.signalG.(fnRegion{r})(1:minlength,:);
    end
end

%% Subtract isosbestic from signal
%Subtract out fit of isosbestic from signal
for r = 1:size(fnRegion,1)
   
   %fit isosbestic to green signal
   p = regress(traces.signalG.(fnRegion{r}),[ones(size(traces.isosbestic.(fnRegion{r}))) traces.isosbestic.(fnRegion{r})]);
   isoFitG = p(1)+ p(2)*traces.isosbestic.(fnRegion{r});
   %Subtract out isosbestic
   traces.motionfitG.(fnRegion{r}) = traces.signalG.(fnRegion{r}) - isoFitG;
   %Divide by isosbestic to get deltaF/F
   traces.deltaFG.(fnRegion{r}) = traces.motionfitG.(fnRegion{r})./isoFitG;
   
   if size(fnTraces, 1) == 3
   %fit isosbestic to red signal
   p = regress(traces.signalR.(fnRegion{r}),[ones(size(traces.isosbestic.(fnRegion{r}))) traces.isosbestic.(fnRegion{r})]);
   isoFitR = p(1)+ p(2)*traces.isosbestic.(fnRegion{r});
   
   %Subtract out isosbestic
   traces.motionfitR.(fnRegion{r}) = traces.signalR.(fnRegion{r}) - isoFitR;
   
   %Divide by isosbestic to get deltaF/F
   traces.deltaFR.(fnRegion{r}) = traces.motionfitR.(fnRegion{r})./isoFitR;
   end
end

%% Center traces by subtracting minimum
for r = 1:size(fnRegion,1)
    %find moving minimum with a sliding window of 120s (1200 samples)
    minG = smooth(movmin((traces.deltaFG.(fnRegion{r})),1200),1200);
    traces.deltaFGmin.(fnRegion{r}) = (traces.deltaFG.(fnRegion{r})) - (minG);
    
    if size(fnTraces, 1) == 3
    minR = smooth(movmin((traces.deltaFR.(fnRegion{r})),1200),1200);
    traces.deltaFRmin.(fnRegion{r}) = (traces.deltaFR.(fnRegion{r})) - (minR);
    end
    
end    
%% divide by standard deviation
for r = 1:size(fnRegion,1)                                              %filter trace for each region (r)
    tracestdev = nanstd(traces.deltaFGmin.(fnRegion{r}));
    traces.deltaFGscale.(fnRegion{r}) = traces.deltaFGmin.(fnRegion{r})/tracestdev;
    
    if size(fnTraces, 1) == 3
    tracestdev = nanstd(traces.deltaFRmin.(fnRegion{r}));
    traces.deltaFRscale.(fnRegion{r}) = traces.deltaFRmin.(fnRegion{r})/tracestdev;
    end
end
%% move relevant traces to signal structure
for r = 1:size(fnRegion,1) 
    signal.(fnRegion{r}).deltaFG = traces.deltaFGscale.(fnRegion{r});
    
    if size(fnTraces, 1) == 3
    signal.(fnRegion{r}).deltaFR = traces.deltaFRscale.(fnRegion{r});
    end
end

save([animalID, 'Test1-tracesNoFilt112821.mat'], 'alignTS', 'animalID', 'traces', 'signal', 'behavAlign');
clearvars -except files filename pathname
end
