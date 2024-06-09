%% take in calcium and behavior data and find calcium snips that are aligned to behavior initiation

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

window = 30;

allgroom.(groomtype) = NaN(files, (10*window*2));
mouseid = {};

%% go through all files
for f=1:files
    
    
    load(filename{f});
	mouse = strtok(filename{f}, 'B');
	mouseid = [mouseid, mouse];
    
    %get sampling freq of calcium data
    fs = ceil(size(traces.signalG.M2,1)/alignTS.traces.green(end));

	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Align calcium data from indicated region with grooming times
    gseqdata=NaN(size(behavAlign.(groomtype).start, 2), (window*2*fs)); %empty matrix to store trace snippets
    
    %find trace snippets that occured during grooming
    for g=1:size(behavAlign.(groomtype).start,2)
	
        %Get time intervals around this grooming bout start
        period = [behavAlign.(groomtype).start(g)-window, behavAlign.(groomtype).start(g)+window];
        
        %Get indices of signal in this window
        index = find((alignTS.traces.(color) >= period(1)) & (alignTS.traces.(color) < period(2)));
        
        %Get photometry data from those indices and add to temporary matrix
        if strcmp(color, 'green')
            fieldcolorname = 'deltaFG';
        elseif strcmp(color, 'red')
            fieldcolorname = 'deltaFR';
        end
        
        %account for indices being 1 too long
        if index(end) > size(signal.(region).(fieldcolorname),1)
            index = index(1:end-1);
        end
        gseqdata(g,1:size(index,2)) = signal.(region).(fieldcolorname)(index);

    end
    
	%%%%%gseqdata = all trace snippets that occurred during grooming
    
    %%%%%%%%%%%%%%%%%%%%%%%%% get behavior data - determine usable grooming trials based on length and isolation
    goodtrials = [];

    for g = 1: size(behavAlign.(groomtype).start, 2)
        
        if size(behavAlign.(groomtype).start, 2) == 1
            continue
        end
        
        %If it's the first grooming trial
        if g == 1
            start1 = behavAlign.(groomtype).start(g);
            stop1 = behavAlign.(groomtype).stop(g);
            start2 = behavAlign.(groomtype).start(g+1);
            
            %If grooming bout is long enough
            %And next grooming bout is far enough away
            if stop1 - start1 > duration & start2 - stop1 > post
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
        elseif g < size(behavAlign.(groomtype).start, 2) && g > 1
            %Get groom start and stop times
            start1 = behavAlign.(groomtype).start(g);
            stop1 = behavAlign.(groomtype).stop(g);
            start2 = behavAlign.(groomtype).start(g+1);
            stop0 = behavAlign.(groomtype).stop(g-1);
            
            %If grooming bout is long enough
            %If previous grooming bout was far enough away
            %If next groom bout is far enough away
            if stop1 - start1 > duration & start1 - stop0 > pre & start2 - stop1 > post
                goodtrials = [goodtrials; g];
            end
        end
    end
	
	%%%%% goodtrials = indices of trials to use
    
    trialstoplot = gseqdata(goodtrials, :); %only use the calcium traces from well-isolated grooming trials

    %% zero-center trials to plot
        baseline = [-pre:1/fs:0];
        baselineidx = floor((fs*baseline)+(fs*window));
        baselinedata = trialstoplot(:,baselineidx);
        basemean = nanmean(baselinedata,2);
        
        trialtraceZero = trialstoplot - basemean;
        trialtraceZero = trialtraceZero(:,1:floor(fs*window*2));
        
        trialtraceAvg = nanmean(trialtraceZero,1);
        
        trialtraceDS = resample(trialtraceAvg, 10, fs);
    
    allgroom.(groomtype)(f,:) = trialtraceDS;
    
end
%% save
save('M2WTCohort1GroomTypeStartZeroTrials', 'allgroom', 'mouseid');

%% plot groom type averages
fnType = fieldnames(allgroom);
x = linspace(-window,window,(window*2)*10);
figure
hold on
for t=1:size(fnType,1)
    avg = nanmean(allgroom.(fnType{t}),1);
    sem = nanstd(allgroom.(fnType{t}),1,1)/sqrt(size(allgroom.(fnType{t}),1));
    fill([x,fliplr(x)],[(avg+sem),fliplr(avg-sem)],t*[0.2, 0.3, 0.1]);
    plot(x, avg, 'Color', t*[0.2, 0.3, 0.1]);
end

xlim([-3 25]);
ylim([-1.1 1.1]);
legend('groom', '', 'face', '', 'body')
