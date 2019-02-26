function [ timeVaringCorrelation ] = calculateTimeVaryingCorrelation(timeSeriesOne, timeSeriesTwo, windowLength)

%{
subjectID = 'TOME_3005';
runName = 'rfMRI_REST_AP_Run1';
timeSeriesPath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'correlationMatrices', subjectID);
load(fullfile(savePath, [runName, '_CIFTI']));


%}


end