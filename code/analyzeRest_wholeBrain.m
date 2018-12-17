function analyzeRest_wholeBrain(subjectID, runName, varargin)

p = inputParser; p.KeepUnmatched = true;
p.addParameter('visualizeAlignment',false, @islogical);
p.addParameter('freeSurferDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID, '/freeSurfer'),  @isstring);
p.addParameter('anatDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);
p.addParameter('pupilDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);
p.addParameter('functionalDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID),  @isstring);
p.addParameter('outputDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);


p.parse(varargin{:});

%% Get the data and organize it

%getSubjectData(subjectID, runName);

%% Register functional scan to anatomical scan

[ functionalScan ] = registerFunctionalToAnatomical(subjectID, runName);

%% Get white matter and ventricular signal
% make white matter and ventricular masks
targetFile = (fullfile(p.Results.functionalDir, [runName, '_native.nii.gz']));

aparcAsegFile = fullfile(p.Results.anatDir, [subjectID, '_aparc+aseg.nii.gz']);
[whiteMatterMask, ventriclesMask] = makeMaskOfWhiteMatterAndVentricles(aparcAsegFile, targetFile);


% extract time series from white matter and ventricles to be used as
% nuisance regressors
[ meanTimeSeries.whiteMatter ] = extractTimeSeriesFromMask( functionalScan, whiteMatterMask, 'whichCentralTendency', 'median');
[ meanTimeSeries.ventricles ] = extractTimeSeriesFromMask( functionalScan, ventriclesMask, 'whichCentralTendency', 'median');

%% Get gray matter mask
makeGrayMatterMask(subjectID);
structuralGrayMatterMaskFile = fullfile(p.Results.anatDir, [subjectID '_GM.nii.gz']);
grayMatterMaskFile = fullfile(p.Results.anatDir, [subjectID '_GM_resampled.nii.gz']);
[ grayMatterMask ] = resampleMRI(structuralGrayMatterMaskFile, targetFile, grayMatterMaskFile);

%% Extract time series of each voxel from gray matter mask
[ ~, rawTimeSeriesPerVoxel, voxelIndices ] = extractTimeSeriesFromMask( functionalScan, grayMatterMask);

%% Clean time series from physio regressors

physioRegressors = load(fullfile(p.Results.functionalDir, [runName, '_puls.mat']));
physioRegressors = physioRegressors.output;
motionTable = readtable((fullfile(p.Results.functionalDir, [runName, '_Movement_Regressors.txt'])));
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
% make pupil regressors
pupilDir = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID);

pupilResponse = load(fullfile(pupilDir, [runName, '_pupil.mat']));
pupilDiameter = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,4);

pupilTimebase = load(fullfile(pupilDir, [runName, '_timebase.mat']));
pupilTimebase = pupilTimebase.timebase.values';
[pupilDiameterConvolved] = convolveRegressorWithHRF(pupilDiameter, pupilTimebase);

[ ~, stats_eyeSignals ] = cleanTimeSeries( cleanedTimeSeriesPerVoxel, pupilDiameter, pupilTimebase, 'meanCenterRegressors', true);

[ pupilDiameter_rSquared ] = makeWholeBrainMap(stats_eyeSignals.rSquared, voxelIndices, functionalScan);
MRIwrite(pupilDiameter_rSquared, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, 'pupilDiameter_rSquared.nii.gz'));

[ pupilDiameter_beta ] = makeWholeBrainMap(stats_eyeSignals.beta, voxelIndices, functionalScan);
MRIwrite(pupilDiameter_beta, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, 'pupilDiameter_beta.nii.gz'));

[ pupilDiameter_pearsonR ] = makeWholeBrainMap(stats_eyeSignals.pearsonR, voxelIndices, functionalScan);
MRIwrite(pupilDiameter_pearsonR, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, 'pupilDiameter_pearsonR.nii.gz'));



end