
%% Read excel file of behavior data
clear all
[filename, pathname] = uigetfile('*.xlsx', 'Select the Behavior Data File');

%Combine filename with path to access files in different location
filepath = fullfile(pathname, filename);

%Change to directory that behavior data is in
cd (pathname)

%Go through each sheet (1 sheet per animal)
[status, sheets] = xlsfinfo(filename);
[r, Nsheets] = size(sheets);

%%Input bin size
bin = input('Bin size? (ms)');

%Create cell array for data
%time in ms
t = (1000/bin)*25;
mouseid = [];
time = [-5000:bin:19500];

%Create vector of laser start times
laseriti = [350, 300, 250, 250, 350, 300, 350, 300, 350, 300, 350, 300, 350, 350, 300, 250, 300, 250, 250, 250, 350, 300, 300, 300, 300, 350, 350, 250, 350, 350, 250, 300, 300, 250, 300, 250, 250, 250, 250, 350, 250, 350, 250, 250, 300, 300, 250, 350, 300, 350];
firstlaseron = 600;
tempITIs = cumsum(laseriti + 100);
laseron = 100*[firstlaseron,(tempITIs+firstlaseron)];
%% Get data
for i=1:Nsheets
    
    groomtimes = [];
    
    %Get sheet name which is also animal name
    sheet = sheets{1,i};
    
    %Columns of interest:
    %H time stamps array from grooming indices
    [num, text, timestamps] = xlsread(filename, sheet, 'H:H');
    clear num text;
    
    %L behavior name cell string array
    [num, behavtype, raw] = xlsread(filename, sheet, 'L:L');
    clear num raw;
    
     %M start or stop cell string array from behavior indices
    [num, state, raw] = xlsread(filename, sheet, 'M:M');
    clear num raw;
    
    %Find session start time
    sessionstart = cell2mat(timestamps(strcmpi(behavtype, 'LED on')));
    
    %New laser start times = + session start
    laseronadj = 1000*sessionstart + laseron;
    
    %Find all grooming times
    groomi = find(strcmpi(behavtype, 'pseudogrooming') | strcmpi(behavtype, 'Face Grooming') | strcmpi(behavtype, 'Body Grooming') | strcmpi(behavtype, 'Scratching'));
    if isempty(groomi)
        mouseid = strvcat(mouseid,sheet);
        
        %Plot this animals grooming probability
        figure
        plot(time, probgroom(i,:));
        title(mouseid(i,:));
        ylim([0 .15]);
        continue
    end
    groomtimes = 1000*cell2mat(timestamps(groomi));
    
    %Plot grooming data for every 10s before, during, after laserpulse
    groombinarydata = zeros(length(laseronadj),25000);
    %laser pulse is from 10001:20000
    %Go through all laser pulse times and find grooming around them
    for la=1:length(laseron)
        %Find if any grooming occurred near pulse
        gi = find(groomtimes>((laseronadj(la))-5000) & groomtimes<((laseronadj(la))+20000));
        if isempty(gi)
            continue
        elseif groomtimes(gi) == laseronadj(la)
            continue
        end
        
        %Convert to timerelative to pulse
        %Subtract laser time then add 10000 to make all indices positive
        mattimes = floor(groomtimes(gi)-laseronadj(la)+5000);
        
        %Odd indices: start times, Even indices:stop times
        gd=1;
        %If first index is even (stop time), make all values before that 1
        if rem(gi(1),2)==0
            groombinarydata(la,1:mattimes(1))=1;
            %Update future for loop index to 2 to begin at first start time
            gd=2;
        end
        
        %Go through all groomtimes and add 1's/0's to matrix
        for g=gd:2:length(gi)
                %If last indice is out of bounds, it's a start time
                if g+1>length(gi)
                    groombinarydata(la,mattimes(g):size(groombinarydata,2))=1;
                else
                    groombinarydata(la,mattimes(g):mattimes(g+1))=1;
                end
        end
    end
    
    %%Separate into subsets of trials based on state
    groomtrials = [];
    nongroomtrials = [];
    for s=1:size(groombinarydata,1)
        
        if all(groombinarydata(s,4995:5000));
            groomtrials = vertcat(groomtrials, groombinarydata(s,:));
        else
            nongroomtrials = vertcat(nongroomtrials, groombinarydata(s,:));
        end       
        
    end

    %Convert groomdata to smaller bins
    edges = [0:bin:25000];
    allbinned = zeros(size(groombinarydata,1), 25000/bin);
    groombinned = zeros(size(groomtrials,1), 25000/bin);
    nongroombinned = zeros(size(nongroomtrials,1), 25000/bin);
    
    for b=1:size(groombinarydata, 1)
        [allhist, e] = histcounts(find(groombinarydata(b,:)),edges);
        allbinned(b,:) = logical(allhist);
        allhist = [];
        
    end
    for b=1:size(groomtrials, 1)
        [groomhist, e] = histcounts(find(groomtrials(b,:)),edges);
        groombinned(b,:) = logical(groomhist);
        groomhist = [];
        
    end
    
    for b=1:size(nongroomtrials, 1)
        [groomhist, e] = histcounts(find(nongroomtrials(b,:)),edges);
        nongroombinned(b,:) = logical(groomhist);
        groomhist = [];
        
    end
    
    
    %Get probability of grooming at every point by dividing by trials
    probgroom(i,:)=mean(groombinned,1);
    proball(i,:) = mean(allbinned,1);
    probnongroom(i,:) = mean(nongroombinned,1);
   
    mouseid = strvcat(mouseid,sheet(1:4));

end

%%
save('ProbGroomAllTrialTypes021020Cohort2.mat', 'probgroom', 'proball', 'probnongroom','mouseid');

