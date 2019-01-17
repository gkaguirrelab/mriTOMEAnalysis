function analyzeRest_wholeBrain(subjectID, runName, varargin)
% Complete analysis pipeline for analyzing resting state data, ultimately
% producing maps
%
% Syntax:
%  analyzeRest_wholeBrain(subjectID, runName)
%
% Description:
%  This routine performs the analysis pipeline for functional BOLD data
%  from resting state runs. Basic analysis steps include to 1) download the
%  necessary data off of flywheel, 2) register the functional volume to the
%  structural volume in subject native space, 3) extract white matter and
%  ventricular signals to be used as nuisance regressors, 4) extract time
%  series from each gray matter voxel in the functional volume, 5) regress
%  out signals from physio, motion, white matter, and ventricles to yield
%  cleaned time series, and 6) regress out a series of eye signals extracted
%  from pupillometry and create maps out of these statistics.
%
%  This routien also requires several pieces of pre-installed software.
%  These include FSL and AFNI.
%
% Inputs:
%  subjectID:           - a string that identifies the relevant subject (i.e.
%                         'TOME_3040'
%  runName:             - a string that identifies the relevant run (i.e.
%                         'rfMRI_REST_AP_Run3')
%
% Optional key-value pairs:
%  skipPhysioMotionWMVRegression  - a logical, with false set as the
%                         default. If true, regressors will be created out
%                         of motion parameters, physiology parameters, and
%                         mean white matter and ventricular signals. One
%                         reason to is when using output from ICAFix, which
%                         we believe will have already dealed with these
%                         nuisance signals.
% Outputs:
%  None. Several maps are saved out to Dropbox, however.

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

% getSubjectData(subjectID, runName);

%% Register functional scan to anatomical scan

[ ~ ] = registerFunctionalToAnatomical(subjectID, runName);

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
clear grayMatterMask
savePath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID);
if ~exist(savePath,'dir')
    mkdir(savePath);
end
save(fullfile(savePath, [runName, '_voxelTimeSeries']), 'rawTimeSeriesPerVoxel', 'voxelIndices', '-v7.3');
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
        regressorMean = nanmean(regressor);
        regressor = regressor - regressorMean;
        regressor = regressor ./ regressorMean;
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
else
    cleanedTimeSeriesPerVoxel = rawTimeSeriesPerVoxel;
    clear rawTimeSeriesPerVoxel
end


%% Remove eye signals from BOLD data
[ covariates ] = makeEyeSignalCovariates(subjectID, runName);

% pupil diameter
regressors = [covariates.pupilDiameterConvolved; covariates.firstDerivativePupilDiameterConvolved];
[ ~, stats_pupilDiameter ] = cleanTimeSeries( cleanedTimeSeriesPerVoxel, regressors', covariates.pupilTimebase, 'meanCenterRegressors', true);
[ pupilDiameter_rSquared ] = makeWholeBrainMap(stats_pupilDiameter.rSquared', voxelIndices, functionalScan);
MRIwrite(pupilDiameter_rSquared, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName,'_pupilDiameter_rSquared.nii.gz']));
[ pupilDiameter_beta ] = makeWholeBrainMap(stats_pupilDiameter.beta, voxelIndices, functionalScan);
MRIwrite(pupilDiameter_beta, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_pupilDiameter_beta.nii.gz']));
[ pupilDiameter_pearsonR ] = makeWholeBrainMap(stats_pupilDiameter.pearsonR', voxelIndices, functionalScan);
MRIwrite(pupilDiameter_pearsonR, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_pupilDiameter_pearsonR.nii.gz']));
clear stats_pupilDiameter pupilDiameter_rSquared pupilDiameter_beta pupilDiameter_pearsonR regressors

% pupil change
regressors = [covariates.pupilChangeConvolved; covariates.firstDerivativePupilChangeConvolved];
[ ~, stats_pupilChange ] = cleanTimeSeries( cleanedTimeSeriesPerVoxel, regressors', covariates.pupilTimebase, 'meanCenterRegressors', true);
[ pupilChange_rSquared ] = makeWholeBrainMap(stats_pupilChange.rSquared', voxelIndices, functionalScan);
MRIwrite(pupilChange_rSquared, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName,'_pupilChange_rSquared.nii.gz']));
[ pupilChange_beta ] = makeWholeBrainMap(stats_pupilChange.beta, voxelIndices, functionalScan);
MRIwrite(pupilChange_beta, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_pupilChange_beta.nii.gz']));
[ pupilChange_pearsonR ] = makeWholeBrainMap(stats_pupilChange.pearsonR', voxelIndices, functionalScan);
MRIwrite(pupilChange_pearsonR, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_pupilChange_pearsonR.nii.gz']));
clear stats_pupilChange pupilChange_rSquared pupilChange_beta pupilChange_pearsonR regressors


% rectified pupil change
regressors = [covariates.rectifiedPupilChangeConvolved; covariates.firstDerivativeRectifiedPupilChangeConvolved];
[ ~, stats_rectifiedPupilChange ] = cleanTimeSeries( cleanedTimeSeriesPerVoxel, regressors', covariates.pupilTimebase, 'meanCenterRegressors', true);
[ rectifiedPupilChange_rSquared ] = makeWholeBrainMap(stats_rectifiedPupilChange.rSquared', voxelIndices, functionalScan);
MRIwrite(rectifiedPupilChange_rSquared, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName,'_rectifiedPupilChange_rSquared.nii.gz']));
[ rectifiedPupilChange_beta ] = makeWholeBrainMap(stats_rectifiedPupilChange.beta, voxelIndices, functionalScan);
MRIwrite(rectifiedPupilChange_beta, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_rectifiedPupilChange_beta.nii.gz']));
[ rectifiedPupilChange_pearsonR ] = makeWholeBrainMap(stats_rectifiedPupilChange.pearsonR', voxelIndices, functionalScan);
MRIwrite(rectifiedPupilChange_pearsonR, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_rectifiedPupilChange_pearsonR.nii.gz']));
clear stats_rectifiedPupilChange rectifiedPupilChange_rSquared rectifiedPupilChange_beta rectifiedPupilChange_pearsonR regressors


% "saccades"
regressors = [covariates.eyeDisplacementConvolved; covariates.firstDerivativeEyeDisplacementConvolved];
[ ~, stats_eyeDisplacement ] = cleanTimeSeries( cleanedTimeSeriesPerVoxel, regressors', covariates.pupilTimebase, 'meanCenterRegressors', true);
[ eyeDisplacement_rSquared ] = makeWholeBrainMap(stats_eyeDisplacement.rSquared', voxelIndices, functionalScan);
MRIwrite(eyeDisplacement_rSquared, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName,'_eyeDisplacement_rSquared.nii.gz']));
[ eyeDisplacement_beta ] = makeWholeBrainMap(stats_eyeDisplacement.beta, voxelIndices, functionalScan);
MRIwrite(eyeDisplacement_beta, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_eyeDisplacement_beta.nii.gz']));
[ eyeDisplacement_pearsonR ] = makeWholeBrainMap(stats_eyeDisplacement.pearsonR', voxelIndices, functionalScan);
MRIwrite(eyeDisplacement_pearsonR, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_eyeDisplacement_pearsonR.nii.gz']));
clear stats_eyeDisplacement eyeDisplacement_rSquared eyeDisplacement_beta eyeDisplacement_pearsonR regressors


% bandpassed (between 0.01 and 0.1 Hz) pupil diameter
regressors = [covariates.pupilDiameterBandpassedConvolved; covariates.firstDerivativePupilDiameterBandpassedConvolved];
[ ~, stats_pupilDiameterBandpassed ] = cleanTimeSeries( cleanedTimeSeriesPerVoxel, regressors', covariates.pupilTimebase, 'meanCenterRegressors', true);
[ pupilDiameterBandpassed_rSquared ] = makeWholeBrainMap(stats_pupilDiameterBandpassed.rSquared', voxelIndices, functionalScan);
MRIwrite(pupilDiameterBandpassed_rSquared, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName,'_pupilDiameterBandpassed_rSquared.nii.gz']));
[ pupilDiameterBandpassed_beta ] = makeWholeBrainMap(stats_pupilDiameterBandpassed.beta, voxelIndices, functionalScan);
MRIwrite(pupilDiameterBandpassed_beta, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_pupilDiameterBandpassed_beta.nii.gz']));
[ pupilDiameterBandpassed_pearsonR ] = makeWholeBrainMap(stats_pupilDiameterBandpassed.pearsonR', voxelIndices, functionalScan);
MRIwrite(pupilDiameterBandpassed_pearsonR, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_pupilDiameterBandpassed_pearsonR.nii.gz']));
clear stats_pupilDiameterBandpassed pupilDiameterBandpassed_rSquared pupilDiameterBandpassed_beta pupilDiameterBandpassed_pearsonR regressors


% bandpassed (between 0.01 and 0.1 Hz) pupil change
regressors = [covariates.pupilChangeBandpassedConvolved; covariates.firstDerivativePupilChangeBandpassedConvolved];
[ ~, stats_pupilChangeBandpassed ] = cleanTimeSeries( cleanedTimeSeriesPerVoxel, regressors', covariates.pupilTimebase, 'meanCenterRegressors', true);
[ pupilChangeBandpassed_rSquared ] = makeWholeBrainMap(stats_pupilChangeBandpassed.rSquared', voxelIndices, functionalScan);
MRIwrite(pupilChangeBandpassed_rSquared, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName,'_pupilChangeBandpassed_rSquared.nii.gz']));
[ pupilChangeBandpassed_beta ] = makeWholeBrainMap(stats_pupilChangeBandpassed.beta, voxelIndices, functionalScan);
MRIwrite(pupilChangeBandpassed_beta, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_pupilChangeBandpassed_beta.nii.gz']));
[ pupilChangeBandpassed_pearsonR ] = makeWholeBrainMap(stats_pupilChangeBandpassed.pearsonR', voxelIndices, functionalScan);
MRIwrite(pupilChangeBandpassed_pearsonR, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_pupilChangeBandpassed_pearsonR.nii.gz']));
clear stats_pupilChangeBandpassed pupilChangeBandpassed_rSquared pupilChangeBandpassed_beta pupilChangeBandpassed_pearsonR regressors


% bandpassed (between 0.01 and 0.1 Hz) rectified pupil change
regressors = [covariates.rectifiedPupilChangeBandpassedConvolved; covariates.firstDerivativeRectifiedPupilChangeBandpassedConvolved];
[ ~, stats_rectifiedPupilChangeBandpassed ] = cleanTimeSeries( cleanedTimeSeriesPerVoxel, regressors', covariates.pupilTimebase, 'meanCenterRegressors', true);
[ rectifiedPupilChangeBandpassed_rSquared ] = makeWholeBrainMap(stats_rectifiedPupilChangeBandpassed.rSquared', voxelIndices, functionalScan);
MRIwrite(rectifiedPupilChangeBandpassed_rSquared, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName,'_rectifiedPupilChangeBandpassed_rSquared.nii.gz']));
[ rectifiedPupilChangeBandpassed_beta ] = makeWholeBrainMap(stats_rectifiedPupilChangeBandpassed.beta, voxelIndices, functionalScan);
MRIwrite(rectifiedPupilChangeBandpassed_beta, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_rectifiedPupilChangeBandpassed_beta.nii.gz']));
[ rectifiedPupilChangeBandpassed_pearsonR ] = makeWholeBrainMap(stats_rectifiedPupilChangeBandpassed.pearsonR', voxelIndices, functionalScan);
MRIwrite(rectifiedPupilChangeBandpassed_pearsonR, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_rectifiedPupilChangeBandpassed_pearsonR.nii.gz']));
clear stats_rectifiedPupilChangeBandpassed rectifiedPupilChangeBandpassed_rSquared rectifiedPupilChangeBandpassed_beta rectifiedPupilChangeBandpassed_pearsonR regressors

clear functionalScan
clear cleanedTimeSeriesPerVoxel
clear covariates

end