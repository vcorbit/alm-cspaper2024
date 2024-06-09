# alm-cspaper2024
Code used for analysis done in Corbit, et al., 2024

***Optogenetic behavior synchronization and analysis code***
ChR2StimProbGroomStereotype20PulsesExclSeiz.m: takes behavioral scoring event log excel sheet form Noldus Observer (one sheet per video/mouse) and calculates probability of behavior aligned to each trial of laser delivery. Designed to analyze scoring data that also includes marked pre-seizure activity (to exclude) and the stereotypies seen in the ALM-CS optogenetic stimulation experiments. 
ChR2StimProbRearGroom20Pulses.m: takes behavioral scoring event log excel sheet form Noldus Observer (one sheet per video/mouse) and calculates probability of behavior aligned to each trial of laser delivery. Designed to analyze scoring data that also includes rearing.
ChR2StimProbAnyGroomGroomTrials021919.m: takes behavioral scoring event log excel sheet form Noldus Observer (one sheet per video/mouse) and calculates probability of behavior aligned to each trial of laser delivery. Designed to analyze scoring data that also includes “pseudogrooming” seen during laser trials in CS optogenetic stimulation experiments.

***Photometry analysis code***
photometryStep1AlignTraces_allbehav.m: takes in photometry calcium data and manually scored behavior data (Observer) and aligns them relative to the experimental session time
photometryStep1AlignTraces_locomotion.m: takes in photometry calcium data and position tracking data (Ethovision) and aligns them relative to the experimental session time
photometryStep2GetTraces.m: pre-processes calcium data traces for later use
photometryProcessTrials.m: align processed calcium data with behavior trials and plot
downsampleforStats.m: downsamples behavior-aligned photometry traces in order to run stats on 0.5s bins
photometryGetQuartilesAligned2Stop.m: aligns photometry data to behavior trials but groups trials based on bout length quartiles
photometryStatsFromQuartiles.m: runs on quartiles data to quantify peaks in the traces and run group statistics
plotBoutLengthHistFromQuartiles.m: runs on quartile data to create histogram showing all bout lengths used in analysis

***Posture tracking (SLEAP) analysis and classifer code***
getBehavTS_CSstim.py/getBehavTS_ALM-CSstim.py: takes in SLEAP posture tracking and associated manual behavior scoring timestamps for preprocessing and alignment
getFeatures_CSstim.py/getFeatures_ALM-CSstim.py: calculates features for classifier model based on posture tracking data
classifiermodel.py: trains and tests a SVC multi-class model to quantify distinctness of evoked grooming behavior to natural grooming
