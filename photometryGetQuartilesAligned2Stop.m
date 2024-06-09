%% process calcium data with behavior data by separating grooming bouts into quartiles based on length

%%variables of note
%behavAlign: behavior start and stop timestamps
%alignTS: associated timestamps of calcium data
%signal: pre-processed calcium data (only final)
%traces: pre-processed calcium data (all steps)

clear all

[filename, pathname] = uigetfile('Select Traces Data File', 'MultiSelect', 'on');

%Change to directory that data is in
cd (pathname);

files = size(filename, 2);

%% user variables (all in sec)
%minimum time before bout start with no grooming
pre = 3;
%minimum time between bout start and next bout start
post = 3;
%minimum duration
duration = 0;

region = 'M2';
color = 'green';
groomtype = 'body'; %options = face, body, scratch, groom, rear

trialwindow = 15; %s

%Create empty vectors to store data from all trials from all animals
mouseid = {};
boutlengthsall = [];
trialsall = [];
%% go through all files
for f=1:files
    
    clear behavAlign
    
    %load traces data
    load(filename{f});
    mouse = strtok(filename{f}, 'B');
    mouseid = [mouseid, mouse];
    
    %get sampling freq of calcium data
    fs = ceil(size(traces.signalG.M2,1)/alignTS.traces.green(end));
	
	
    %%%%%%% get calcium trace for analysis
    if strcmp(color, 'red')
        tracefield = 'deltaFRscale';
    elseif strcmp(color, 'green')
        tracefield = 'deltaFGscale';
    end
    trace = traces.(tracefield).(region);
    sessiontime = alignTS.traces.green;



    %%%%%%% go through all trials and determine useable ones for analysis
    %Goal - determine is grooming bout 'g' is usable
    goodtrials = [];
    
    for g = 1: size(behavAlign.(groomtype).start, 2)
        
        %If it's the first grooming trial
        if g == 1
            start1 = behavAlign.(groomtype).start(g);
            stop1 = behavAlign.(groomtype).stop(g);
            
            if size(behavAlign.(groomtype).start, 2) == 1
                %If grooming bout is long enough
                %And next grooming bout is far enough away
                if stop1 - start1 > duration & start2 - start1 > post
                    goodtrials = [goodtrials; g];
                end
                break
            else
                start2 = behavAlign.(groomtype).start(g+1);
                %If grooming bout is long enough
                %And next grooming bout is far enough away
                if stop1 - start1 > duration & start2 - start1 > post
                    goodtrials = [goodtrials; g];
                end
            end
            
            
            %If grooming bout is long enough
            %And next grooming bout is far enough away
            if stop1 - start1 > duration & start2 - start1 > post
                goodtrials = [goodtrials; g];
            end
            
            %If it's the last trial
        elseif g == size(behavAlign.(groomtype).start, 2)
            start1 = behavAlign.(groomtype).start(g);
            stop1 = behavAlign.(groomtype).stop(g);
            stop0 = behavAlign.(groomtype).stop(g-1);
            
            %If grooming bout is long enough
            %If previous grooming bout was far enough away
            if stop1 - start1 > duration & start1 - stop0 > pre
                goodtrials = [goodtrials; g];
            end
            
            %Otherwise consider all options
        else
            %Get groom start and stop times
            start1 = behavAlign.(groomtype).start(g);
            stop1 = behavAlign.(groomtype).stop(g);
            start2 = behavAlign.(groomtype).start(g+1);
            stop0 = behavAlign.(groomtype).stop(g-1);
            
            %If grooming bout is long enough
            %If previous grooming bout was far enough away
            %If next groom bout is far enough away
            if stop1 - start1 > duration & start1 - stop0 > pre & start2 - start1 > post
                goodtrials = [goodtrials; g];
            end
        end
    end
    
    %Get bout lengths for all usable trials
    boutlengths = behavAlign.groom.stop(goodtrials)' - behavAlign.groom.start(goodtrials)';
    %%
    if isempty(goodtrials)
        continue
    end
    
    %get starts and stop times for usable trials
    groomstarts = behavAlign.groom.start(goodtrials);
    groomstops = behavAlign.groom.stop(goodtrials);
	
    
    %crop starts times
    sessionidx = find(groomstops - trialwindow >= 0 & (groomstops + trialwindow) <= sessiontime(end));
    groomstartsEx = groomstarts(sessionidx);
    groomstopsEx = groomstops(sessionidx);
    boutlengthsEx = groomstopsEx-groomstartsEx;
    
	%align calcium data to either stop times or start times
	%currently set to align to groom STOP times, but can switch out to look at groom start if wanted
	
	%create empty matrix for data storage
    usedtrials = NaN(size(groomstopsEx, 2),(trialwindow*2*10));
    %usedtrials = NaN(size(groomstartsEx, 2),(trialwindow*2*10));    
    
    %go through all grooming stop trials
    for g=1:size(groomstopsEx,2);
        
        startTS = groomstartsEx(1,g);
        stopTS = groomstopsEx(1,g);
        
        idxblank = NaN(1,(fs*2*trialwindow));
        
		%get indices in calcium trace using the sessiontime calcium timestamps
        idx = find(sessiontime >= (stopTS-trialwindow) & sessiontime <= (stopTS+trialwindow));
        starttrialidx = find(sessiontime >= (startTS-pre) & sessiontime <= (startTS+trialwindow));
		
        %add this trial to all trials
        trialtrace = trace(idx)';
        startaligntrace = trace(starttrialidx)';
        baselineidx = [1:fs*pre];
        basemean = mean(startaligntrace(baselineidx)); %baseline the trace based on 3s before groom START
        trialtraceZero = trialtrace - basemean;
        
        trialtraceDS = resample(trialtraceZero, 10, fs);
        
        if size(trialtraceDS, 2) < trialwindow*2*10;
            trialtraceDS(size(trialtraceDS,2):(trialwindow*2*10)) = NaN;
        end
        
        usedtrials(g,:) = trialtraceDS;
    end
    
    clear trialtrace idx
    
    %%add data to vector of all data
    boutlengthsall = [boutlengthsall; boutlengthsEx'];
    trialsall = [trialsall; usedtrials];
    
end
%% separate bouts into quartiles
%isolate bouts of different lengths
for q=1:4
    quartile(q).idx = find(boutlengthsall > (q-1)*2 & boutlengthsall <= q*2);
    quartile(q).boutlengths = boutlengthsall(quartile(q).idx);
    quartile(q).trials = trialsall(quartile(q).idx, :);
end

%% NaN each trial set based on average bout length
for q=1:4
    quartile(q).avgbout = mean(quartile(q).boutlengths);
    
    %calculate time axis for average trial length
    quartile(q).xtime = [-trialwindow+.1:.1:trialwindow];
    
    quartile(q).trialscrop = quartile(q).trials;
    quartile(q).trialscrop(:,1:floor((length(quartile(q).xtime)/2-(quartile(q).avgbout*10)-3*10))) = NaN;
    
end

%% save data
save('M2WTAllGroomBoutLengthsQuartilesStopAlign', 'quartile');

%% plot means
figure
hold on

for q=1:4
    quartile(q).avgtrial = nanmean(quartile(q).trialscrop, 1);
    quartile(q).semtrial = nanstd(quartile(q).trialscrop,1,1)/sqrt(size(quartile(q).trialscrop,1));
    xtime = quartile(q).xtime;
    
    fill([xtime,fliplr(xtime)],[(quartile(q).avgtrial+quartile(q).semtrial),fliplr(quartile(q).avgtrial-quartile(q).semtrial)], q*[0.08, 0.17, 0.25])
    plot(xtime, quartile(q).avgtrial, 'Color', 'black');
    
    line([0 0],[0 3], 'Color', q*[0.08, 0.17, 0.25]);
end
