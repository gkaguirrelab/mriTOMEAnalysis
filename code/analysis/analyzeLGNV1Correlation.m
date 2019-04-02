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
    [ pooledTimeVaryingCorrelationStruct] = analyzeLGNV1Correlation(subjectID, runName, 'plotHandle', plotFig, 'pooledTimeVaryingCorrelationStruct', pooledTimeVaryingCorrelationStruct, 'correlationMethod', 'jumpingWindowPearson', 'pupilMetric', 'mean');
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

if ~strcmp(p.Results.correlationMethod, 'jumpingWindowPearson')
    % Get pupil time series
    [ covariates, unconvolvedCovariates ] = makeEyeSignalCovariates(subjectID, runName);
    pupilStruct = [];
    % resample the pupil data to the same temporal resolution as the BOLD data
    pupilStruct.timebase = covariates.timebase;
    pupilStruct.values = unconvolvedCovariates.pupilDiameter;
    temporalFit = tfeIAMP('verbosity','none');
    pupilStruct = temporalFit.resampleTimebase(pupilStruct, timebase, 'resampleMethod', 'resample');
else
    startingIndex = 1;
    windowIndices = [];
    rowNumber = 1;
    while startingIndex + p.Results.windowLength <= length(timebase)
        endingIndex = startingIndex + p.Results.windowLength - 1;
        windowIndices(rowNumber,1) = startingIndex;
        windowIndices(rowNumber,2) = endingIndex;
        
        % adjust starting index for next iteration
        startingIndex = startingIndex + p.Results.windowLength;
        
        rowNumber = rowNumber + 1;
    end
    [ covariates, unconvolvedCovariates ] = makeEyeSignalCovariates(subjectID, runName);
    pupilStruct = [];
    % resample the pupil data to the same temporal resolution as the BOLD data
    pupilStruct.timebase = covariates.timebase;
    pupilStruct.values = unconvolvedCovariates.pupilDiameter;
    for ii = 1:size(windowIndices,1)
        startingTime = timebase(windowIndices(ii,1));
        endingTime = timebase(windowIndices(ii,2));
        [~, startingPupilIndex ] = min(abs(pupilStruct.timebase - startingTime));
        [~, endingPupilIndex ] = min(abs(pupilStruct.timebase - endingTime));
        
        if strcmp(p.Results.pupilMetric, 'mean')
            pupilValues(ii) = nanmean(pupilStruct.values(startingPupilIndex:endingPupilIndex));
        elseif strcmp(p.Results.pupilMetric, 'std')
            pupilValues(ii) = nanstd(pupilStruct.values(startingPupilIndex:endingPupilIndex));
        end
        
    end
    pupilStruct.values = pupilValues;
end

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
if strcmp(p.Results.pupilMetric, 'mean')
    xlabel('Pupil size (mm)');
else
    xlabel('Pupil STD (mm)');
end
    
ylabel(p.Results.correlationMethod);

end