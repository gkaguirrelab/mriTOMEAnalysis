function runIAMPForFlash(subjectID, timeSeriesAccumulator, voxelIndices, v1Mask, flashScan, varargin)
p = inputParser; p.KeepUnmatched = true;
p.addParameter('outputDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flashAnalysis/', subjectID), @isstring);
p.addParameter('physioDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);
p.addParameter('runName','rfMRI_REST_AP_Run1', @ischar);




p.parse(varargin{:});

%% create the stimulus struct
TR = 0.8*1000;
% make stimulus struct
% use same deltaT as the TR, so all of our regressors are on the same
% timebase
deltaT = 0.8*1000;
totalTime = 336*1000;
stimulusStruct.timebase = 0:deltaT:totalTime-TR;

% light-on or light-off segments last 12 seconds
segmentLength = 12*1000;
numberOfBlocks = totalTime/segmentLength;
stimulusStruct.values = zeros(1,length(stimulusStruct.timebase));

% actually make the stimulus profile. we find the boundaries of the 12-s
% chunks, then make the values in between 1 if it's an even-numbered chunk
% otherwise they're left as 0.
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

% mean-center this stimulus profile
stimulusStruct.values = stimulusStruct.values - 0.5;

% convolve stimulus profile with HRF
% first make HRF
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
thePacket.stimulus = stimulusStruct;
thePacket.stimulus.values = conv(thePacket.stimulus.values, kernelStruct.values, 'full')*(thePacket.stimulus.timebase(2) - thePacket.stimulus.timebase(1));
thePacket.stimulus.values = thePacket.stimulus.values(1:length(thePacket.stimulus.timebase));


temporalFit = tfeIAMP('verbosity','none');



% start assembling the packet
responseStruct.timebase = stimulusStruct.timebase;
thePacket.kernel = [];
thePacket.metaData = [];

thePacket.stimulus.values = stimulusStruct.values;
thePacket.stimulus.timebase = stimulusStruct.timebase;
thePacket.response.timebase = responseStruct.timebase;




%% Make physio regressors
% load up the physio results
load(fullfile(p.Results.physioDir, [p.Results.runName, '_puls.mat'])); 
confoundRegressors = output.all;

% normalize the regressors
confoundRegressors = confoundRegressors - nanmean(confoundRegressors);
confoundRegressors = confoundRegressors ./ nanstd(confoundRegressors);

% add these regressors to our thePacket.stimulus struct
nRegressors = size(confoundRegressors, 2);
for nn = 1:nRegressors
    thePacket.stimulus.values(end+1,:) = confoundRegressors(:,nn)';
end

% figure out how many rows of stimulus.values we have, AKA how many
% different regressors we're working
defaultParamsInfo.nInstances = size(thePacket.stimulus.values,1);


%% Loop over voxels and fit the IAMP model on each voxel's timeseries
for vv = 1:size(timeSeriesAccumulator,1)
    
    
    thePacket.response.values = timeSeriesAccumulator(vv,:);
    
    % TFE linear regression here
    [paramsFit,fVal,modelResponseStruct] = temporalFit.fitResponse(thePacket,...
        'defaultParamsInfo', defaultParamsInfo, 'searchMethod','linearRegression','errorType','1-r2');
    
    % save out all of the beta weights
    betas(vv,:) = paramsFit.paramMainMatrix;
    rSquared(vv) = 1 - fVal;
    
end

%% make an image
betaNames{1} = 'stimulusProfile';
covariateNames = fieldnames(output);
for bb = 2:(size(betas, 2))
    betaNames{bb} = covariateNames{bb+3};
end

betaVol = [];
for bb = 1:size(betas,2)
    betaVol = v1Mask;
    for vv = 1:size(timeSeriesAccumulator, 1)
        
        betaVol.vol(voxelIndices{vv}(1), voxelIndices{vv}(2), voxelIndices{vv}(3)) = betas(vv,bb);
        
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
    
    
    
    MRIwrite(betaVol, fullfile(p.Results.outputDir, [subjectID '_' runName, '_', betaNames{bb}, 'offFirst.nii.gz']));
end

rSquaredVol = v1Mask;
for vv = 1:size(timeSeriesAccumulator, 1)
    
    rSquaredVol.vol(voxelIndices{vv}(1), voxelIndices{vv}(2), voxelIndices{vv}(3)) = rSquared(vv);
    
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



MRIwrite(rSquaredVol, fullfile(p.Results.outputDir, [subjectID '_' runName, '_', 'rSquared_offFirst.nii.gz']));


end