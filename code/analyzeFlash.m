function analyzeFlash(subjectID, runName)
%% Get the data and organize it

%% Extract V1 time series
[ meanV1TimeSeries, v1TimeSeriesCollapsed_meanCentered, voxelIndices, combinedV1Mask, functionalScan ] = extractV1TimeSeries(subjectID, 'runName', runName);

%% analyze that time series via IAMP

runIAMPForFlash(subjectID, v1TimeSeriesCollapsed_meanCentered, voxelIndices, combinedV1Mask, functionalScan, 'runName', runName);
end