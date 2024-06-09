%load quartile data in MATLAB

allbouts = [];
edges = [1:1:45];
for q=1:size(quartile,2)
    allbouts = [allbouts; quartile(q).boutlengths];
    
end

figure
b = histogram(allbouts, edges, 'FaceColor', [191/255, 49/255, 145/255]);
xlim([0 31])