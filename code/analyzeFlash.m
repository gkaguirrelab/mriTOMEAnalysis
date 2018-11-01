function analyzeFlash(subjectID, timeSeriesAccumulator, voxelIndices, v1Mask, flashScan, output, varargin)
p = inputParser; p.KeepUnmatched = true;
p.addParameter('outputDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flashAnalysis/', subjectID), @isstring);
p.addParameter('runName','rfMRI_REST_AP_Run1', @ischar);




p.parse(varargin{:});


TR = 0.8*1000;
% make stimulus struct
deltaT = 0.8*1000;
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


% make the HRF
%% convolve stimulus profile with HRF
% make HRF
hrfParams.gamma1 = 6;   % positive gamma parameter (roughly, time-to-peak in secs)
hrfParams.gamma2 = 12;  % negative gamma parameter (roughly, time-to-peak in secs)
hrfParams.gammaScale = 10; % scaling factor between the positive and negative gamma componenets

kernelStruct.timebase=stimulusStruct.timebase;

% The timebase is converted to seconds within the function, as the gamma
% parameters are defined in seconds.
hrf = gampdf(kernelStruct.timebase/1000, hrfParams.gamma1, 1) - ...
    gampdf(kernelStruct.timebase/1000, hrfParams.gamma2, 1)/hrfParams.gammaScale;
kernelStruct.values=hrf;

% Normalize the kernel to have unit amplitude
[ kernelStruct ] = normalizeKernelArea( kernelStruct );

% convolve the HRF with our stimulus profile
thePacket.stimulus.values = conv(thePacket.stimulus.values, kernelStruct.values, 'full')*(thePacket.stimulus.timebase(2) - thePacket.stimulus.timebase(1));
thePacket.stimulus.values = thePacket.stimulus.values(1:length(thePacket.stimulus.timebase));

%% Make physio regressors
% load up the physio results
confoundRegressors = output.all;

% normalize the regressors
confoundRegressors = confoundRegressors - nanmean(confoundRegressors);
confoundRegressors = confoundRegressors ./ nanstd(confoundRegressors);

% add these regressors to our thePacket.stimulus struct
nRegressors = size(confoundRegressors, 2);
for nn = 1:nRegressors
    thePacket.stimulus.values(end+1,:) = confoundRegressors(:,nn)';
end


defaultParamsInfo.nInstances = size(thePacket.stimulus.values,1);


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
    
    betas(vv,:) = paramsFit.paramMainMatrix;
    
end

%% make an image
betaVol = v1Mask;
for vv = 1:size(timeSeriesAccumulator, 1)
    
    betaVol.vol(voxelIndices{vv}(1), voxelIndices{vv}(2), voxelIndices{vv}(3)) = betas(vv,1);
    
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