function analyzeFlash(subjectID, timeSeriesAccumulator, voxelIndices, v1Mask, flashScan, varargin)
p = inputParser; p.KeepUnmatched = true;
p.addParameter('outputDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flashAnalysis/', subjectID), @isstring);
p.addParameter('runName','rfMRI_REST_AP_Run1', @ischar);




p.parse(varargin{:});


TR = 0.8*1000;
% make stimulus struct
deltaT = 0.1*1000;
totalTime = 336*1000;
stimulusStruct.timebase = 0:deltaT:totalTime-TR;
segmentLength = 12*1000;
numberOfBlocks = totalTime/segmentLength;
stimulusStruct.values = zeros(1,length(stimulusStruct.timebase));

for bb = 1:numberOfBlocks
    firstIndex = find(stimulusStruct.timebase == (bb - 1) * segmentLength);
    secondIndex = find(stimulusStruct.timebase == (bb) * segmentLength) - 1;
    if isempty(secondIndex)
        secondIndex = length(stimulusStruct.timebase);
    end
    if round(bb/2) == bb/2
        stimulusStruct.values(firstIndex:secondIndex) = 1;
    end
    
end


temporalFit = tfeIAMP('verbosity','none');

TR = 0.800;

% make stimulus timebase
deltaT = 800;
totalTime = 420*deltaT;
responseStruct.timebase = linspace(0,totalTime-deltaT,totalTime/deltaT);
thePacket.kernel = [];
thePacket.metaData = [];

thePacket.stimulus.values = stimulusStruct.values;
thePacket.stimulus.timebase = stimulusStruct.timebase;
thePacket.response.timebase = responseStruct.timebase;

defaultParamsInfo.nInstances = 1;

%% Loop over voxels and fit the IAMP model on each voxel's timeseries
for vv = 1:size(timeSeriesAccumulator,1)
    
    
    % get the data for a single voxel
    runData = timeSeriesAccumulator(vv,:);
    
    % convert to percent signal change relative to the mean
    voxelMeanVec = mean(runData,2);
    PSC = 100*((runData - voxelMeanVec)./voxelMeanVec);
    
    thePacket.response.values = PSC;
    
    % TFE linear regression here
    [paramsFit,fVal,modelResponseStruct] = temporalFit.fitResponse(thePacket,...
        'defaultParamsInfo', defaultParamsInfo, 'searchMethod','linearRegression','errorType','1-r2');
    
    betas(vv) = paramsFit.paramMainMatrix;
    
end

%% make an image
betaVol = v1Mask;
for vv = 1:size(timeSeriesAccumulator, 1)
    
    betaVol.vol(voxelIndices{vv}(1), voxelIndices{vv}(2), voxelIndices{vv}(3)) = betas(vv);
    
end

% figure out the run name to save the file appropriately
runName = flashScan.fspec;
runName = strsplit(runName, '/');
runName = runName{end};
runName = strsplit(runName, '.');
runName = runName{1};

if ~exist(p.Results.outputDir, 'dir')
    mkdir(p.Results.outputDir);
end

MRIwrite(betaVol, fullfile(p.Results.outputDir, [subjectID '_' runName '.nii.gz']));


end