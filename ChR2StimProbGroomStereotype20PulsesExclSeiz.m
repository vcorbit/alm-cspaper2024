
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
% bin = input('Bin size? (ms)');
bin = 500;

%% user modifiable variable - window size in ms
window = [-4999 40000];
ts = (window(2) - window(1) + 1)/1000;
pulsewidth = 20; %s
pulseN = 20;

%Create cell array for data
%time in ms
t = (1000/bin)*ts;
probstereo = zeros(Nsheets, t);
probgroom = zeros(Nsheets, t);
mouseid = [];
time = [window(1):bin:window(2)];

%Create vector of laser start times
laseriti = [350, 300, 250, 250, 350, 300, 350, 300, 350, 300, 350, 300, 350, 350, 300, 250, 300, 250, 250, 250, 350, 300, 300, 300, 300, 350, 350, 250, 350, 350, 250, 300, 300, 250, 300, 250, 250, 250, 250, 350, 250, 350, 250, 250, 300, 300, 250, 350, 300, 350];
firstlaseron = 600;
tempITIs = cumsum(laseriti + (10*pulsewidth));
laserontheor = 100*[firstlaseron,(tempITIs+firstlaseron)];
%% Get data
for i=1:Nsheets
    
    stereotimes = [];
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
    
    %N comments cell string array from behavior indices
    [num, comments, raw] = xlsread(filename, sheet, 'N:N');
    clear num raw;
    
    %Find session start time
    sessionstart = cell2mat(timestamps(find(strcmpi(behavtype, 'LED ON'), 1, 'first')));
    laseron = laserontheor/1000 + sessionstart;
    
    %Find all grooming times
    stereoi = find(strcmpi(behavtype, 'Stereotypic Behavior'));
    groomi = find(strcmpi(behavtype, 'Face Grooming') | strcmpi(behavtype, 'Body Grooming') | strcmpi(behavtype, 'Scratching'));

    if isempty(groomi) & isempty(stereoi)
                probgroom(i,:)=0;
    probstereo(i,:)=0;
    mouseid = strvcat(mouseid,sheet);
        continue
    end
    groomtimes = 1000*cell2mat(timestamps(groomi));
    stereotimes = 1000*cell2mat(timestamps(stereoi));
    
    %go through comments and exclude trials with seizure activity
    seizureidx = find(cellfun(@isempty,strfind(comments, 'pre-seiz'))==0 | ...
        cellfun(@isempty,strfind(comments, 'PRE-SEIZ'))==0);
    if size(seizureidx,1)>0
        for s = 1: size(seizureidx,1)
            seizts = cell2mat(timestamps(seizureidx(s)));
            seizpulse = find(laseron<seizts, 1, 'last');
            laseron(seizpulse) = NaN;
        end
        laseronadj = 1000*laseron(~isnan(laseron));
    else
        laseronadj = 1000*laseron;
    end
    
    if pulseN > length(laseronadj)
        usedpulses = length(laseronadj);
    else
        usedpulses = pulseN;
    end
    
    %Plot grooming data for every 5s before, after laserpulse
    groombinarydata = zeros(length(laseronadj),45000);
    stereobinarydata = zeros(length(laseronadj),45000);
    %laser pulse is from 5001:25000
    %Go through all laser pulse times and find grooming around them
    for la=1:usedpulses
        %Find if any grooming occurred near pulse
        ri = find(groomtimes>=((laseronadj(la))-5000) & groomtimes<((laseronadj(la))+40000));
        si = find(stereotimes>=((laseronadj(la))-5000) & stereotimes<((laseronadj(la))+40000));
        if isempty(ri) & isempty(si)
            continue
        elseif isempty(ri) & ~isempty(si)
            mattimesS = floor(stereotimes(si)-laseronadj(la)+5000);
            %Odd indices: start times, Even indices:stop times
            gd=1;
            %If first index is even (stop time), make all values before that 1
            if rem(si(1),2)==0
                stereobinarydata(la,1:mattimesS(1))=1;
                %Update future for loop index to 2 to begin at first start time
                gd=2;
            end
            
            %Go through all groomtimes and add 1's/0's to matrix
            for g=gd:2:length(si)
                %If last indice is out of bounds, it's a start time
                if g+1>length(si)
                    stereobinarydata(la,mattimesS(g):size(stereobinarydata,2))=1;
                else
                    stereobinarydata(la,mattimesS(g):mattimesS(g+1))=1;
                end
            end
        elseif isempty(si) & ~isempty(ri)
            mattimesG = floor(groomtimes(ri)-laseronadj(la)+5000);
            %Odd indices: start times, Even indices:stop times
            gd=1;
            %If first index is even (stop time), make all values before that 1
            if rem(ri(1),2)==0
                groombinarydata(la,1:mattimesG(1))=1;
                %Update future for loop index to 2 to begin at first start time
                gd=2;
            end
            
            %Go through all groomtimes and add 1's/0's to matrix
            for g=gd:2:length(ri)
                %If last indice is out of bounds, it's a start time
                if g+1>length(ri)
                    groombinarydata(la,mattimesG(g):size(groombinarydata,2))=1;
                else
                    groombinarydata(la,mattimesG(g):mattimesG(g+1))=1;
                end
            end
        elseif ~isempty(si) & ~isempty(ri)
            mattimesG = floor(groomtimes(ri)-laseronadj(la)+5000);
            mattimesS = floor(stereotimes(si)-laseronadj(la)+5000);
            %Odd indices: start times, Even indices:stop times
            gd=1;
            %If first index is even (stop time), make all values before that 1
            if rem(ri(1),2)==0
                groombinarydata(la,1:mattimesG(1))=1;
                %Update future for loop index to 2 to begin at first start time
                gd=2;
            end
            
            %Go through all reartimes and add 1's/0's to matrix
            for g=gd:2:length(ri)
                %If last indice is out of bounds, it's a start time
                if g+1>length(ri)
                    groombinarydata(la,mattimesG(g):size(groombinarydata,2))=1;
                else
                    groombinarydata(la,mattimesG(g):mattimesG(g+1))=1;
                end
            end
            
            
            %Odd indices: start times, Even indices:stop times
            gd=1;
            %If first index is even (stop time), make all values before that 1
            if rem(si(1),2)==0
                stereobinarydata(la,1:mattimesS(1))=1;
                %Update future for loop index to 2 to begin at first start time
                gd=2;
            end
            
            %Go through all stereotimes and add 1's/0's to matrix
            for g=gd:2:length(si)
                %If last indice is out of bounds, it's a start time
                if g+1>length(si)
                    stereobinarydata(la,mattimesS(g):size(stereobinarydata,2))=1;
                else
                    stereobinarydata(la,mattimesS(g):mattimesS(g+1))=1;
                end
            end
        end
    end
    
    
    %Convert reardata to smaller bins
    groomdatabinned = zeros(size(groombinarydata,1), 45000/bin);
    for b=1:45000/bin
        for trial=1:size(groombinarydata,1)
            if any(groombinarydata(trial,1+((b-1)*bin):b*bin)==1)
                groomdatabinned(trial,b) = 1;
            end
        end
    end
    
    stereodatabinned = zeros(size(stereobinarydata,1), 45000/bin);
    for b=1:45000/bin
        for trial=1:size(stereobinarydata,1)
            if any(stereobinarydata(trial,1+((b-1)*bin):b*bin)==1)
                stereodatabinned(trial,b) = 1;
            end
        end
    end
    
    %Get probability of grooming at every point by dividing by trials
    probgroom(i,:)=nanmean(groomdatabinned,1);
    probstereo(i,:)=nanmean(stereodatabinned,1);
    mouseid = strvcat(mouseid,sheet);

end

%%
save('M2-CSProbGroomStereoExclSeiz021020.mat', 'probgroom', 'probstereo', 'mouseid');

