function analyzeRest_wholeBrain(subjectID, runName, varargin)

p = inputParser; p.KeepUnmatched = true;
p.addParameter('visualizeAlignment',false, @islogical);
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

%% Get white matter and ventricular signal
% make white matter and ventricular masks
targetFile = (fullfile(functionalDir, [runName, '_native.nii.gz']));

aparcAsegFile = fullfile(anatDir, [subjectID, '_aparc+aseg.nii.gz']);
[whiteMatterMask, ventriclesMask] = makeMaskOfWhiteMatterAndVentricles(aparcAsegFile, targetFile);


% extract time series from white matter and ventricles to be used as
% nuisance regressors
[ meanTimeSeries.whiteMatter ] = extractTimeSeriesFromMask( functionalScan, whiteMatterMask, 'whichCentralTendency', 'median');
[ meanTimeSeries.ventricles ] = extractTimeSeriesFromMask( functionalScan, ventriclesMask, 'whichCentralTendency', 'median');

%% Get gray matter mask
makeGrayMatterMask(subjectID);
structuralGrayMatterMaskFile = fullfile(anatDir, [subjectID '_GM.nii.gz']);
grayMatterMaskFile = fullfile(anatDir, [subjectID '_GM_resampled.nii.gz']);
[ grayMatterMask ] = resampleMRI(structuralGrayMatterMaskFile, targetFile, grayMatterMaskFile);

%% Extract time series of each voxel from gray matter mask
[ ~, rawTimeSeriesPerVoxel, voxelIndices ] = extractTimeSeriesFromMask( functionalScan, grayMatterMask);

%% Clean time series from physio regressors

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

savePath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID);
if ~exist(savePath,'dir')
    mkdir(savePath);
end


%% Remove eye signals from BOLD data
[ covariates ] = makeEyeSignalCovariates(subjectID, runName);

% pupil diameter
regressors = [covariates.pupilDiameterConvolved; covariates.firstDerivativePupilDiameterConvolved];    
[ ~, stats_pupilDiameter ] = cleanTimeSeries( cleanedTimeSeriesPerVoxel, regressors', pupilTimebase, 'meanCenterRegressors', true);
[ pupilDiameter_rSquared ] = makeWholeBrainMap(stats_pupilDiameter.rSquared', voxelIndices, functionalScan);
MRIwrite(pupilDiameter_rSquared, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName,'_pupilDiameter_rSquared.nii.gz']));
[ pupilDiameter_beta ] = makeWholeBrainMap(stats_pupilDiameter.beta, voxelIndices, functionalScan);
MRIwrite(pupilDiameter_beta, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_pupilDiameter_beta.nii.gz']));
[ pupilDiameter_pearsonR ] = makeWholeBrainMap(stats_pupilDiameter.pearsonR', voxelIndices, functionalScan);
MRIwrite(pupilDiameter_pearsonR, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_pupilDiameter_pearsonR.nii.gz']));

% pupil constriction
regressors = [covariates.constrictionsConvolved; covariates.firstDerivativeConstrictionsConvolved];
[ ~, stats_pupilConstriction ] = cleanTimeSeries( cleanedTimeSeriesPerVoxel, regressors', pupilTimebase, 'meanCenterRegressors', true);
[ pupilConstriction_rSquared ] = makeWholeBrainMap(stats_pupilConstriction.rSquared', voxelIndices, functionalScan);
MRIwrite(pupilConstriction_rSquared, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName,'_pupilConstriction_rSquared.nii.gz']));
[ pupilConstriction_beta ] = makeWholeBrainMap(stats_pupilConstriction.beta, voxelIndices, functionalScan);
MRIwrite(pupilConstriction_beta, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_pupilConstriction_beta.nii.gz']));
[ pupilConstriction_pearsonR ] = makeWholeBrainMap(stats_pupilConstriction.pearsonR', voxelIndices, functionalScan);
MRIwrite(pupilConstriction_pearsonR, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_pupilConstriction_pearsonR.nii.gz']));


% pupil dilation
regressors = [covariates.dilationsConvolved; covariates.firstDerivativeDilationsConvolved];
[ ~, stats_pupilDilation ] = cleanTimeSeries( cleanedTimeSeriesPerVoxel, regressors', pupilTimebase, 'meanCenterRegressors', true);
[ pupilDilation_rSquared ] = makeWholeBrainMap(stats_pupilDilation.rSquared', voxelIndices, functionalScan);
MRIwrite(pupilDilation_rSquared, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName,'_pupilDilation_rSquared.nii.gz']));
[ pupilDilation_beta ] = makeWholeBrainMap(stats_pupilDilation.beta, voxelIndices, functionalScan);
MRIwrite(pupilDilation_beta, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_pupilDilation_beta.nii.gz']));
[ pupilDilation_pearsonR ] = makeWholeBrainMap(stats_pupilDilation.pearsonR', voxelIndices, functionalScan);
MRIwrite(pupilDilation_pearsonR, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_pupilDilation_pearsonR.nii.gz']));


% pupil change
regressors = [covariates.pupilChangeConvolved; covariates.firstDerivativePupilChangeConvolved];
[ ~, stats_pupilChange ] = cleanTimeSeries( cleanedTimeSeriesPerVoxel, regressors', pupilTimebase, 'meanCenterRegressors', true);
[ pupilChange_rSquared ] = makeWholeBrainMap(stats_pupilChange.rSquared', voxelIndices, functionalScan);
MRIwrite(pupilChange_rSquared, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName,'_pupilChange_rSquared.nii.gz']));
[ pupilChange_beta ] = makeWholeBrainMap(stats_pupilChange.beta, voxelIndices, functionalScan);
MRIwrite(pupilChange_beta, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_pupilChange_beta.nii.gz']));
[ pupilChange_pearsonR ] = makeWholeBrainMap(stats_pupilChange.pearsonR', voxelIndices, functionalScan);
MRIwrite(pupilChange_pearsonR, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_pupilChange_pearsonR.nii.gz']));

% "saccades"
regressors = [covariates.eyeDisplacementConvolved; covariates.firstDerivativeEyeDisplacementConvolved];
[ ~, stats_eyeDisplacement ] = cleanTimeSeries( cleanedTimeSeriesPerVoxel, regressors', pupilTimebase, 'meanCenterRegressors', true);
[ eyeDisplacement_rSquared ] = makeWholeBrainMap(stats_eyeDisplacement.rSquared', voxelIndices, functionalScan);
MRIwrite(eyeDisplacement_rSquared, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName,'_eyeDisplacement_rSquared.nii.gz']));
[ eyeDisplacement_beta ] = makeWholeBrainMap(stats_eyeDisplacement.beta, voxelIndices, functionalScan);
MRIwrite(eyeDisplacement_beta, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_eyeDisplacement_beta.nii.gz']));
[ eyeDisplacement_pearsonR ] = makeWholeBrainMap(stats_eyeDisplacement.pearsonR', voxelIndices, functionalScan);
MRIwrite(eyeDisplacement_pearsonR, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_eyeDisplacement_pearsonR.nii.gz']));




end