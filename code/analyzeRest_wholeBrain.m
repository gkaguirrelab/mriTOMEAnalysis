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

regressorTimebase = 0:TR:nFrames*TR-TR;

% remove all regressors that are all 0
emptyColumns = [];
for column = 1:size(regressors,2)
    if ~any(regressors(:,column))
        emptyColumns = [emptyColumns, column];
    end
end
regressors(:,emptyColumns) = [];

[ cleanedFunctionalScan, betaVolume, rSquaredVolume, pearsonRVolume ] = cleanTimeSeries_wholeBrain( functionalScan, regressors, regressorTimebase, 'meanCenterRegressors', false);

savePath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID);
if ~exist(savePath,'dir')
    mkdir(savePath);
end

MRIwrite(cleanedFunctionalScan, fullfile(savePath, [runName '_physioMotionWMVCorrected']));
MRIwrite(betaVolume, fullfile(savePath, [runName '_beta_physioMotionWMV']));
MRIwrite(rSquaredVolume, fullfile(savePath, [runName '_rSquared_physioMotionWMV']));
MRIwrite(pearsonRVolume, fullfile(savePath, [runName '_pearsonR_physioMotionWMV']));

clear betaVolume rSquaredVolume pearsonRVolume functionalScan


%% Remove eye signals from BOLD data
% make pupil regressors
pupilDir = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID);

pupilResponse = load(fullfile(pupilDir, [runName, '_pupil.mat']));
pupilDiameter = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,4);

pupilTimebase = load(fullfile(pupilDir, [runName, '_timebase.mat']));
pupilTimebase = pupilTimebase.timebase.values';
[pupilDiameterConvolved] = convolveRegressorWithHRF(pupilDiameter, pupilTimebase);

[ cleanedFunctionalScan_eyeSignalsRemoved, betaVolume_eyeSignals, rSquaredVolume_eyeSignals, pearsonRVolume_eyeSignals ] = cleanTimeSeries_wholeBrain( cleanedFunctionalScan, pupilDiameter, pupilTimebase, 'meanCenterRegressors', true);

MRIwrite(cleanedFunctionalScan_eyeSignalsRemoved, fullfile(savePath, [runName '_physioMotionWMVCorrected']));
MRIwrite(betaVolume_eyeSignals, fullfile(savePath, [runName '_beta__eyeSignals']));
MRIwrite(rSquaredVolume_eyeSignals, fullfile(savePath, [runName '_rSquared__eyeSignals']));
MRIwrite(pearsonRVolume_eyeSignals, fullfile(savePath, [runName '_pearsonR__eyeSignals']));

end