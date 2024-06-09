%% down sample to .5s bins for 2-way ANOVA in SPSS
% run after photometryProcessTrials

%allgroom = trace snippets during grooming trials
fnType = {'groom', 'face', 'body'};
x = linspace(-window,window,(window*2)*10);

baseline = [-pre:1/10:0];
baselineidx = floor((10*baseline)+(10*window));

datastart = baselineidx(1);
datastop = find(x < 25);
datastop = datastop(end);

xcrop = x(datastart:datastop);
xDS = resample(xcrop, 2, 10);
for t=1:size(fnType,2)
    trials = allgroom.(fnType{t});
    
    trialsDS = [];
    
    %crop to only show time that is plotted
    trialscrop = trials(:,datastart:datastop);
    
    for trial=1:size(trialscrop, 1)
        mouseDS = resample(trialscrop(trial,:), 2, 10);
        trialsDS = [trialsDS; mouseDS];
    end
    
    fnDS = strcat((fnType{t}), 'DS');
    
    allgroom.(fnDS) = trialsDS';
    
end