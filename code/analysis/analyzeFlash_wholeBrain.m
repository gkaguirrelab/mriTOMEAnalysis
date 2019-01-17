function analyzeRest_wholeBrain(subjectID, runName, varargin)

%% Input parser
p = inputParser; p.KeepUnmatched = true;

p.addParameter('skipPhysioMotionWMVRegression', false, @islogical);

p.parse(varargin{:});

%% Define paths
[ paths ] = definePaths(subjectID);

freeSurferDir = paths.freeSurferDir;
anatDir = paths.anatDir;
pupilDir = paths.pupilDir;
functionalDir = paths.functionalDir;
outputDir = paths.outputDir;

%% Get the data and organize it

%getSubjectData(subjectID, runName);

%% Register functional scan to anatomical scan

[ functionalScan ] = registerFunctionalToAnatomical(subjectID, runName);

%% Smooth functional scan
functionalFile = fullfile(functionalDir, [runName, '_native.nii.gz']);
[ functionalScan ] = smoothMRI(functionalFile);

%% Get white matter and ventricular signal
% make white matter and ventricular masks
targetFile = (fullfile(functionalDir, [runName, '_native.nii.gz']));

aparcAsegFile = fullfile(anatDir, [subjectID, '_aparc+aseg.nii.gz']);
if ~(p.Results.skipPhysioMotionWMVRegression)
    
    [whiteMatterMask, ventriclesMask] = makeMaskOfWhiteMatterAndVentricles(aparcAsegFile, targetFile);
    
    
    % extract time series from white matter and ventricles to be used as
    % nuisance regressors
    [ meanTimeSeries.whiteMatter ] = extractTimeSeriesFromMask( functionalScan, whiteMatterMask, 'whichCentralTendency', 'median');
    [ meanTimeSeries.ventricles ] = extractTimeSeriesFromMask( functionalScan, ventriclesMask, 'whichCentralTendency', 'median');
    clear whiteMatterMask ventriclesMask
end
%% Get gray matter mask
makeGrayMatterMask(subjectID);
structuralGrayMatterMaskFile = fullfile(anatDir, [subjectID '_GM.nii.gz']);
grayMatterMaskFile = fullfile(anatDir, [subjectID '_GM_resampled.nii.gz']);
[ grayMatterMask ] = resampleMRI(structuralGrayMatterMaskFile, targetFile, grayMatterMaskFile);

%% Extract time series of each voxel from gray matter mask
[ ~, rawTimeSeriesPerVoxel, voxelIndices ] = extractTimeSeriesFromMask( functionalScan, grayMatterMask);

%% Clean time series from physio regressors
if ~(p.Results.skipPhysioMotionWMVRegression)
    physioRegressors = load(fullfile(functionalDir, [runName, '_puls.mat']));
    physioRegressors = physioRegressors.output;
    motionTable = readtable((fullfile(functionalDir, [runName, '_Movement_Regressors.txt'])));
    motionRegressors = table2array(motionTable(:,7:12));
    regressors = [physioRegressors.all, motionRegressors];
    
    % mean center these motion and physio regressors
    for rr = 1:size(regressors,2)
        regressor = regressors(:,rr);
        regressor = regressor - nanmean(regressor);
        regressor = regressor ./ nanstd(regressor);
        nanIndices = find(isnan(regressor));
        regressor(nanIndices) = 0;
        regressors(:,rr) = regressor;
    end
    
    % also add the white matter and ventricular time series
    regressors(:,end+1) = meanTimeSeries.whiteMatter;
    regressors(:,end+1) = meanTimeSeries.ventricles;
    
    TR = functionalScan.tr; % in ms
    nFrames = functionalScan.nframes;
    
    regressorsTimebase = 0:TR:nFrames*TR-TR;
    
    % remove all regressors that are all 0
    emptyColumns = [];
    for column = 1:size(regressors,2)
        if ~any(regressors(:,column))
            emptyColumns = [emptyColumns, column];
        end
    end
    regressors(:,emptyColumns) = [];
    
    [ cleanedTimeSeriesPerVoxel, stats_physioMotionWMV ] = cleanTimeSeries( rawTimeSeriesPerVoxel, regressors, regressorsTimebase, 'meanCenterRegressors', false);
    clear stats_physioMotionWMV rawTimeSeriesPerVoxel meanTimeSeries regressors
    
    savePath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'flash', subjectID);
    if ~exist(savePath,'dir')
        mkdir(savePath);
    end
else
    cleanedTimeSeriesPerVoxel = rawTimeSeriesPerVoxel;
    clear rawTimeSeriesPerVoxel
end


%% fit flash stimulus profile
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
[ flashConvolved ] = convolveRegressorWithHRF(stimulusStruct.values', stimulusStruct.timebase);
[~, stats_flash] = cleanTimeSeries( cleanedTimeSeriesPerVoxel, flashConvolved', stimulusStruct.timebase, 'meanCenterRegressors', false);
[ flash_rSquared ] = makeWholeBrainMap(stats_flash.rSquared', voxelIndices, functionalScan);
MRIwrite(flash_rSquared, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'flash', subjectID, [runName,'_flash_rSquared.nii.gz']));
[ flash_beta ] = makeWholeBrainMap(stats_flash.beta, voxelIndices, functionalScan);
MRIwrite(flash_beta, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'flash', subjectID, [runName, '_flash_beta.nii.gz']));
[ flash_pearsonR ] = makeWholeBrainMap(stats_flash.pearsonR', voxelIndices, functionalScan);
MRIwrite(flash_pearsonR, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'flash', subjectID, [runName, '_flash_pearsonR.nii.gz']));


end