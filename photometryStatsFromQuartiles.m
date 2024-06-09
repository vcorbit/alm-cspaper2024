%load quartile data in MATLAB
%find peaks in trace to quantify traces and do stats

%% get peaks and store amplitude and time for each trial in each quartile
promthresh = 1;
for q=1:4
    quartile(q).peaktime = [];
    quartile(q).peakamp = [];
    %get trials
    trials = quartile(q).trials;
    boutstartidx = 10*pre*ones(size(trials,1),1);
    boutstop = quartile(q).boutlengths;
    boutstopidx = ceil(boutstartidx + 10*boutstop);
    for g=1:size(trials,1)
        
        startidx = boutstartidx(g);
        stopidx = boutstopidx(g);
        %get trial
        xtime = [-3:.1:10];
        trialtrace = trials(g,1:size(xtime,2));
        
        
        %smooth trace to reduce noise in peaks
        datasmooth = smooth(xtime,trialtrace, .05);
        
        % find local peaks in trace
        [maxvalue, maxloc, w, maxprom] = findpeaks(datasmooth(:));
        
        %turn logical indices into time values
        maxtime = xtime(maxloc)';
        
        %get only minimums within window (groom start to end of trial)
        maxtime_restrict = maxtime(find(maxtime> 0));
        
        %if there's more than one max
        %find the most prominent one that occurs first
        if numel(maxtime_restrict) > 1
            
            %get prominence for these maxs
            prom_restrict = maxprom(find(maxtime> 0));
            
            %find the first peak after groom start that has high prominence
            firstpromidx = find(prom_restrict>promthresh, 1, 'first');
            
            %get values for that peak
            maxvalue_restrict = maxvalue(find(maxtime> 0));
            
            peak = maxvalue_restrict(firstpromidx);
            loctime = maxtime_restrict(firstpromidx);
            
            %if there's no peaks with prominence greater than 2
            %repeat the process with prominece > 1
            if isempty(loctime)
                
                loctime = NaN;
                peak = NaN;
                trialtraceZero = NaN(size(trialtraceZero));
                
            end
            
            %if max_restrict is empty - values=NaN
        elseif isempty(maxtime_restrict)
            loctime = NaN;
            peak = NaN;
            trialtraceZero = NaN(size(trialtraceZero));
            
            % otherwise, there's only one peak in this time window
        else
            
            %check if this single peak reaches prominence threshold
            prom_restrict = maxprom(find(maxtime> 0));
            if prom_restrict > promthresh
                loctime = maxtime_restrict;
                peak = maxvalue(find(maxtime> 0));
                
                trialtraceZeroDS = resample(trialtraceZero, 10, fs);
                trialsmouse.(fnRegion{r})(g,1:size(trialtraceZeroDS, 2)) = trialtraceZeroDS;
            else
                loctime = NaN;
                peak = NaN;
                trialtraceZero = NaN(size(trialtraceZero));
            end
            
        end
        quartile(q).peaktime(g,1) = loctime;
        quartile(q).peakamp(g,1) = peak;
    end
end

%% organize data and run anova
anovadataamp = [];
anovadataloc = [];
group = [];
d=0;
for q=1:4
    data = quartile(q).peaktime;
    anovadataamp(d+1:d+size(data,1),1) = quartile(q).peakamp;
    anovadataloc(d+1:d+size(data,1),1) = quartile(q).peaktime;
    groupname = q*ones(size(data,1),1);
    %group(d+1:d+size(data,1),1) = num2str(groupname);
    group(d+1:d+size(data,1),1) = groupname;
    d=d+size(data,1);
end

[p,tbl,stats] = anova1(anovadataloc, group);

%% align to stop time and plot means
figure
hold on

for q=1:4
    
    %get trials
    trials = quartile(q).trials;
    boutstartidx = 10*pre*ones(size(trials,1),1);
    boutstop = quartile(q).boutlengths;
    boutstopidx = ceil(boutstartidx + 10*boutstop);
    
    trialsstop = NaN(size(trials,1), 61);
    for t=1:size(trials,1)
    trialsstop(t,:) = trials(t,(boutstopidx(t)-30):(boutstopidx(t)+30));
    
    end
    quartile(q).alignstopmean = nanmean(trialsstop, 1);
    quartile(q).alignstopsem = nanstd(trialsstop,1,1)/sqrt(size(trialsstop,1));
    xtime = [-3:.1:3];
    
    fill([xtime,fliplr(xtime)],[(quartile(q).alignstopmean+quartile(q).alignstopsem),fliplr(quartile(q).alignstopmean-quartile(q).alignstopsem)], q*[0.08, 0.17, 0.25])
    plot(xtime, quartile(q).alignstopmean, 'Color', 'black');
    alpha(.7)
end

line([0 0],[-.5 2]);
