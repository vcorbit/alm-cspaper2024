
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

%user modifiable variable - window size in ms
window = [-4999 40000];
ts = (window(2) - window(1) + 1)/1000;
pulsewidth = 10; %s
pulseN = 51;

%Create cell array for data
%time in ms
t = (1000/bin)*ts;
probrear = zeros(Nsheets, t);
mouseid = [];
time = [window(1):bin:window(2)];

%Create vector of laser start times
laseriti = [350, 300, 250, 250, 350, 300, 350, 300, 350, 300, 350, 300, 350, 350, 300, 250, 300, 250, 250, 250, 350, 300, 300, 300, 300, 350, 350, 250, 350, 350, 250, 300, 300, 250, 300, 250, 250, 250, 250, 350, 250, 350, 250, 250, 300, 300, 250, 350, 300, 350];
firstlaseron = 600;
tempITIs = cumsum(laseriti + (10*pulsewidth));
laseron = 100*[firstlaseron,(tempITIs+firstlaseron)];
laseron = laseron(1:pulseN);
%% Get data
for i=1:Nsheets
    
    reartimes = [];
    
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
    sessionstart = cell2mat(timestamps(find(strcmpi(behavtype, 'LED ON'), 1, 'first')));
    
    if isempty(sessionstart)
        probrear(i,:)=NaN;
    probgroom(i,:)=NaN;
    mouseid = strvcat(mouseid,sheet);
    continue
    end
    
    %New laser start times = + session start
    laseronadj = 1000*sessionstart + laseron;
    
    %Find all grooming times
    reari = find(strcmpi(behavtype, 'Rearing'));
    groomi = find(strcmpi(behavtype, 'Face Grooming') | strcmpi(behavtype, 'Body Grooming') | strcmpi(behavtype, 'Scratching'));

    if isempty(reari) & isempty(groomi)
                probrear(i,:)=0;
    probgroom(i,:)=0;
    mouseid = strvcat(mouseid,sheet);
        continue
    end
    reartimes = 1000*cell2mat(timestamps(reari));
    groomtimes = 1000*cell2mat(timestamps(groomi));
    
    %Plot grooming data for every 5s before, after laserpulse
    rearbinarydata = zeros(length(laseronadj),45000);
    groombinarydata = zeros(length(laseronadj),45000);
    %laser pulse is from 5001:25000
    %Go through all laser pulse times and find grooming around them
    for la=1:length(laseron)
        %Find if any grooming occurred near pulse
        ri = find(reartimes>=((laseronadj(la))-5000) & reartimes<((laseronadj(la))+40000));
        si = find(groomtimes>=((laseronadj(la))-5000) & groomtimes<((laseronadj(la))+40000));
        if isempty(ri) & isempty(si)
            continue
        elseif isempty(ri) & ~isempty(si)
            mattimesS = floor(groomtimes(si)-laseronadj(la)+5000);
            %Odd indices: start times, Even indices:stop times
            gd=1;
            %If first index is even (stop time), make all values before that 1
            if rem(si(1),2)==0
                groombinarydata(la,1:mattimesS(1))=1;
                %Update future for loop index to 2 to begin at first start time
                gd=2;
            end
            
            %Go through all groomtimes and add 1's/0's to matrix
            for g=gd:2:length(si)
                %If last indice is out of bounds, it's a start time
                if g+1>length(si)
                    groombinarydata(la,mattimesS(g):size(groombinarydata,2))=1;
                else
                    groombinarydata(la,mattimesS(g):mattimesS(g+1))=1;
                end
            end
        elseif isempty(si) & ~isempty(ri)
            mattimesR = floor(reartimes(ri)-laseronadj(la)+5000);
            %Odd indices: start times, Even indices:stop times
            gd=1;
            %If first index is even (stop time), make all values before that 1
            if rem(ri(1),2)==0
                rearbinarydata(la,1:mattimesR(1))=1;
                %Update future for loop index to 2 to begin at first start time
                gd=2;
            end
            
            %Go through all groomtimes and add 1's/0's to matrix
            for g=gd:2:length(ri)
                %If last indice is out of bounds, it's a start time
                if g+1>length(ri)
                    rearbinarydata(la,mattimesR(g):size(rearbinarydata,2))=1;
                else
                    rearbinarydata(la,mattimesR(g):mattimesR(g+1))=1;
                end
            end
        elseif ~isempty(si) & ~isempty(ri)
            mattimesR = floor(reartimes(ri)-laseronadj(la)+5000);
            mattimesS = floor(groomtimes(si)-laseronadj(la)+5000);
            %Odd indices: start times, Even indices:stop times
            gd=1;
            %If first index is even (stop time), make all values before that 1
            if rem(ri(1),2)==0
                rearbinarydata(la,1:mattimesR(1))=1;
                %Update future for loop index to 2 to begin at first start time
                gd=2;
            end
            
            %Go through all reartimes and add 1's/0's to matrix
            for g=gd:2:length(ri)
                %If last indice is out of bounds, it's a start time
                if g+1>length(ri)
                    rearbinarydata(la,mattimesR(g):size(rearbinarydata,2))=1;
                else
                    rearbinarydata(la,mattimesR(g):mattimesR(g+1))=1;
                end
            end
            
            
            %Odd indices: start times, Even indices:stop times
            gd=1;
            %If first index is even (stop time), make all values before that 1
            if rem(si(1),2)==0
                groombinarydata(la,1:mattimesS(1))=1;
                %Update future for loop index to 2 to begin at first start time
                gd=2;
            end
            
            %Go through all stereotimes and add 1's/0's to matrix
            for g=gd:2:length(si)
                %If last indice is out of bounds, it's a start time
                if g+1>length(si)
                    groombinarydata(la,mattimesS(g):size(groombinarydata,2))=1;
                else
                    groombinarydata(la,mattimesS(g):mattimesS(g+1))=1;
                end
            end
        end
    end
    
    
    %Convert reardata to smaller bins
    reardatabinned = zeros(size(rearbinarydata,1), 45000/bin);
    for b=1:45000/bin
        for trial=1:size(rearbinarydata,1)
            if any(rearbinarydata(trial,1+((b-1)*bin):b*bin)==1)
                reardatabinned(trial,b) = 1;
            end
        end
    end
    
    groomdatabinned = zeros(size(groombinarydata,1), 45000/bin);
    for b=1:45000/bin
        for trial=1:size(groombinarydata,1)
            if any(groombinarydata(trial,1+((b-1)*bin):b*bin)==1)
                groomdatabinned(trial,b) = 1;
            end
        end
    end
    
    %Get probability of grooming at every point by dividing by trials
    probrear(i,:)=mean(reardatabinned,1);
    probgroom(i,:)=mean(groomdatabinned,1);
    mouseid = strvcat(mouseid,sheet);

end

%%
save('CSStimProbRear.mat', 'probrear', 'mouseid');

