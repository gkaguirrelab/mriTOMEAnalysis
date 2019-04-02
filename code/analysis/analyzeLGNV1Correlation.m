function [pooledTimeVaryingCorrelationStruct ] = analyzeLGNV1Correlation(subjectID, runName, varargin)

%{
close all
subjectID = 'TOME_3004';
runNames = getRunsPerSubject('TOME_3004');

plotFig = figure; hold on;

pooledTimeVaryingCorrelationStruct.correlationValues = [];
pooledTimeVaryingCorrelationStruct.pupilValues = [];

for rr = 1:length(runNames);
    runName = runNames{rr};
    [ pooledTimeVaryingCorrelationStruct] = analyzeLGNV1Correlation(subjectID, runName, 'plotHandle', plotFig, 'pooledTimeVaryingCorrelationStruct', pooledTimeVaryingCorrelationStruct, 'correlationMethod', 'slidingWindowPearson', 'pupilMetric', 'mean');
end
makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.pupilValues, pooledTimeVaryingCorrelationStruct.correlationValues)
%}

%% Input parser
p = inputParser; p.KeepUnmatched = true;

p.addParameter('correlationMethod', 'slidingWindowPearson', @ischar);
p.addParameter('pupilMetric', 'mean', @ischar);
p.addParameter('linkAxes', true, @islogical);
p.addParameter('normalizeTimeVaryingCorrelation', false, @islogical);
p.addParameter('combineWithinConnectionType', true, @islogical);
p.addParameter('windowLength', 50, @isnumeric);
p.addParameter('plotHandle', [], @ishandle);
p.addParameter('pooledTimeVaryingCorrelationStruct', [], @isstruct);
p.addParameter('TR', 800, @isnumeric);

p.parse(varargin{:});

%% Create mean LGN time series
% load up functional CIFTI
paths = definePaths(subjectID);
grayordinates = loadCIFTI(fullfile(paths.anatDir, [runName, '_Atlas_hp2000_clean.dtseries.nii']));

% make LGN mask
[ LGNMask ] = makeLGNMaskCIFTI;

% extract time series from maks
[LGNMeanTimeSeries, ~] = extractTimeSeriesFromMaskCIFTI(LGNMask, grayordinates);

% create time base
TR = p.Results.TR;
timebase = 0:TR:TR*length(LGNMeanTimeSeries) - TR;

%% Load up mean V1 time series
% make V1 mask
areaNum = 1;
eccenRange = [0 90];
anglesRange = [0 180];
hemisphere = 'combined';
threshold = 0.9;
[~, userID] = system('whoami');
userID = strtrim(userID);
pathToBensonMasks = fullfile('/Users', userID, 'Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/benson/');
pathToBensonMappingFile = fullfile('/Users', userID, 'Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/benson/indexMapping.mat');
pathToTemplateFile = fullfile('/Users', userID, 'Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/benson/template.dscalar.nii');
[ V1Mask ] = makeMaskFromRetinoCIFTI(areaNum, eccenRange, anglesRange, hemisphere, 'pathToBensonMasks', pathToBensonMasks, 'pathToTemplateFile', pathToTemplateFile, 'pathToBensonMappingFile', pathToBensonMappingFile, 'threshold', threshold);

% extract time series from mask
[ V1MeanTimeSeries, ~] = extractTimeSeriesFromMaskCIFTI(V1Mask, grayordinates);

%% Calculate time varying correlation
timeVaryingCorrelation = calculateTimeVaryingCorrelation(V1MeanTimeSeries, LGNMeanTimeSeries, p.Results.windowLength, 'correlationMethod', p.Results.correlationMethod, 'normalizeTimeVaryingCorrelation', p.Results.normalizeTimeVaryingCorrelation);

%% Extract pupil size over the same time window
% Get pupil time series
[ covariates, unconvolvedCovariates ] = makeEyeSignalCovariates(subjectID, runName);
pupilStruct = [];
% resample the pupil data to the same temporal resolution as the BOLD data
pupilStruct.timebase = covariates.timebase;
pupilStruct.values = unconvolvedCovariates.pupilDiameter;
temporalFit = tfeIAMP('verbosity','none');
pupilStruct = temporalFit.resampleTimebase(pupilStruct, timebase, 'resampleMethod', 'resample');

%% Stash the result
if isempty(p.Results.pooledTimeVaryingCorrelationStruct)
    pooledTimeVaryingCorrelationStruct.correlationValues = [];
    pooledTimeVaryingCorrelationStruct.pupilValues = [];
else
    pooledTimeVaryingCorrelationStruct = p.Results.pooledTimeVaryingCorrelationStruct;
end

pooledTimeVaryingCorrelationStruct.correlationValues = timeVaryingCorrelation;
pooledTimeVaryingCorrelationStruct.pupilValues = pupilStruct.values;

%% Plot to summarize
if isempty(p.Results.plotHandle)
    plotFig = figure; hold on;
end

plot(pupilStruct.values, timeVaryingCorrelation, '.', 'Color', 'k');

end