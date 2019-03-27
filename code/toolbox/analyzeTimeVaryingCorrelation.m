function [ pooledTimeVaryingCorrelationStruct ] = analyzeTimeVaryingCorrelation(subjectID, runName, varargin)

%{
close all
subjectID = 'TOME_3005';
runNames = getRunsPerSubject('TOME_3005');

plotFig = figure; hold on;

pooledTimeVaryingCorrelationStruct.homotopic.correlationValues = [];
pooledTimeVaryingCorrelationStruct.hierarchical.correlationValues = [];
pooledTimeVaryingCorrelationStruct.background.correlationValues = [];
pooledTimeVaryingCorrelationStruct.homotopic.pupilValues = [];
pooledTimeVaryingCorrelationStruct.hierarchical.pupilValues = [];
pooledTimeVaryingCorrelationStruct.background.pupilValues = [];

for rr = 1:length(runNames);
    runName = runNames{rr};
    [ pooledTimeVaryingCorrelationStruct] = analyzeTimeVaryingCorrelation(subjectID, runName, 'plotHandle', plotFig, 'pooledTimeVaryingCorrelationStruct', pooledTimeVaryingCorrelationStruct, 'correlationMethod', 'jumpingWindowPearson');
end
subplot(1,3,1);
makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.homotopic.pupilValues, pooledTimeVaryingCorrelationStruct.homotopic.correlationValues)
subplot(1,3,2);
makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.hierarchical.pupilValues, pooledTimeVaryingCorrelationStruct.hierarchical.correlationValues)
subplot(1,3,3);
makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.background.pupilValues, pooledTimeVaryingCorrelationStruct.background.correlationValues)


mtdPlotFig = figure; hold on;
for rr = 1:length(runNames);
    runName = runNames{rr};
    analyzeTimeVaryingCorrelation(subjectID, runName, 'plotHandle', mtdPlotFig, 'correlationMethod', 'mtd')
end
%}
%% Input parser
p = inputParser; p.KeepUnmatched = true;

p.addParameter('correlationMethod', 'slidingWindowPearson', @ischar);
p.addParameter('normalizeTimeVaryingCorrelation', false, @islogical);
p.addParameter('windowLength', 50, @isnumeric);
p.addParameter('plotHandle', [], @ishandle);
p.addParameter('pooledTimeVaryingCorrelationStruct', [], @isstruct);
p.addParameter('TR', 800, @isnumeric);

p.parse(varargin{:});

%% Define the connections of interest
homotopicConnections = { ...
    'V3d_lh+V3v_lh', ...
    'V2d_lh+V2v_lh', ...
    'V1d_lh+V1v_lh', ...
    'V3d_rh+V3v_rh', ...
    'V2d_rh+V2v_rh', ...
    'V1d_rh+V1v_rh', ...
    'V3d_lh+V3d_rh', ...
    'V3v_lh+V3v_rh', ...
    'V3v_lh+V3d_rh', ...
    'V3d_lh+V3v_rh', ...
    'V2d_lh+V2d_rh', ...
    'V2v_lh+V2v_rh', ...
    'V2v_lh+V2d_rh', ...
    'V2d_lh+V2v_rh', ...
    'V1d_lh+V1d_rh', ...
    'V1v_lh+V1v_rh', ...
    'V1v_lh+V1d_rh', ...
    'V1d_lh+V1v_rh', ...
    };
hierarchicalConnections = { ...
    'V3v_lh+V2v_lh', ...
    'V3v_lh+V1v_lh', ...
    'V2v_lh+V1v_lh', ...
    'V3d_lh+V2d_lh', ...
    'V3d_lh+V1d_lh', ...
    'V2d_lh+V1d_lh', ...
    'V3v_rh+V2v_rh', ...
    'V3v_rh+V1v_rh', ...
    'V2v_rh+V1v_rh', ...
    'V3d_rh+V2d_rh', ...
    'V3d_rh+V1d_rh', ...
    'V2d_rh+V1d_rh', ...
    };
backgroundConnections = { ...
    'V3v_lh+V2d_lh', ...
    'V3v_lh+V1d_lh', ...
    'V2v_lh+V3d_lh', ...
    'V2v_lh+V1d_lh', ...
    'V1v_lh+V3d_lh', ...
    'V1v_lh+V2d_lh', ...
    'V3v_rh+V2d_rh', ...
    'V3v_rh+V1d_rh', ...
    'V2v_rh+V3d_rh', ...
    'V2v_rh+V1d_rh', ...
    'V1v_rh+V3d_rh', ...
    'V1v_rh+V2d_rh', ...
    'V3v_rh+V2d_lh', ...
    'V3v_rh+V1d_lh', ...
    'V2v_rh+V3d_lh', ...
    'V2v_rh+V1d_lh', ...
    'V1v_rh+V3d_lh', ...
    'V1v_rh+V2d_lh', ...
    'V3v_lh+V2d_rh', ...
    'V3v_lh+V1d_rh', ...
    'V2v_lh+V3d_rh', ...
    'V2v_lh+V1d_rh', ...
    'V1v_lh+V3d_rh', ...
    'V1v_lh+V2d_rh', ...
    };

allConnections = {homotopicConnections{:}, hierarchicalConnections{:}, backgroundConnections{:}};
connectionTypes = [];
for aa = 1:length(homotopicConnections)
    connectionTypes{end+1} = 'homotopic';
end
for bb = 1:length(hierarchicalConnections)
    connectionTypes{end+1} = 'hierarchical';
end
for cc = 1:length(backgroundConnections)
    connectionTypes{end+1} = 'background';
end






%% Load up data about this run

% load the time series
timeSeriesPath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID);
load(fullfile(timeSeriesPath, [runName, '_timeSeriesCIFTI'])); % loads up a struct named meanTimeSeries

% create time base
maskNames = fieldnames(meanTimeSeries);
TR = p.Results.TR;
timebase = 0:TR:TR*length(meanTimeSeries.(maskNames{1})) - TR;

%% Loop over connections and calculate time varying correlation
timeVaryingCorrelations = [];
for ii = 1:length(allConnections)
    splitConnections = strsplit(allConnections{ii}, '+');
    regionOne = splitConnections{1};
    regionTwo = splitConnections{2};
    
    timeVaryingCorrelations{end+1} = calculateTimeVaryingCorrelation(meanTimeSeries.([regionOne, '_mask']), meanTimeSeries.([regionTwo, '_mask']), p.Results.windowLength, 'correlationMethod', p.Results.correlationMethod, 'normalizeTimeVaryingCorrelation', p.Results.normalizeTimeVaryingCorrelation);
    
end



%% Plot to summarize and stash the output
if isempty(p.Results.plotHandle)
    plotFig = figure; hold on;
end

if isempty(p.Results.pooledTimeVaryingCorrelationStruct)
    pooledTimeVaryingCorrelationStruct.homotopic.correlationValues = [];
    pooledTimeVaryingCorrelationStruct.hierarchical.correlationValues = [];
    pooledTimeVaryingCorrelationStruct.background.correlationValues = [];
    pooledTimeVaryingCorrelationStruct.homotopic.pupilValues = [];
    pooledTimeVaryingCorrelationStruct.hierarchical.pupilValues = [];
    pooledTimeVaryingCorrelationStruct.background.pupilValues = [];
else
    pooledTimeVaryingCorrelationStruct = p.Results.pooledTimeVaryingCorrelationStruct;
end

if ~strcmp(p.Results.correlationMethod, 'jumpingWindowPearson')
    % Get pupil time series
    [ covariates ] = makeEyeSignalCovariates(subjectID, runName);
    pupilStruct = [];
    % resample the pupil data to the same temporal resolution as the BOLD data
    pupilStruct.timebase = covariates.timebase;
    pupilStruct.values = covariates.pupilDiameterConvolved;
    temporalFit = tfeIAMP('verbosity','none');
    pupilStruct = temporalFit.resampleTimebase(pupilStruct, timebase, 'resampleMethod', 'resample');
    for ii = 1:length(timeVaryingCorrelations)
        
        % determine which subplot we're adding to
        if strcmp(connectionTypes{ii}, 'homotopic')
            subplotValue = 1;
        elseif strcmp(connectionTypes{ii}, 'hierarchical')
            subplotValue = 2;
        elseif strcmp(connectionTypes{ii}, 'background')
            subplotValue = 3;
        end
        subplot(1,3,subplotValue); hold on;
        
        % do the plotting
        plot(pupilStruct.values, timeVaryingCorrelations{ii}, '.', 'Color', 'k');
        
        % stash the result
        pooledTimeVaryingCorrelationStruct.(connectionTypes{ii}).correlationValues = [pooledTimeVaryingCorrelationStruct.(connectionTypes{ii}).correlationValues, timeVaryingCorrelations{ii}];
        pooledTimeVaryingCorrelationStruct.(connectionTypes{ii}).pupilValues = [pooledTimeVaryingCorrelationStruct.(connectionTypes{ii}).pupilValues, pupilStruct.values];
    end
else
    % on the basis of the BOLD time series, determine the pupil time series
    % indices that correspond to the indices used to determine the
    % jumpingWindowCorrelation
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
    [ covariates, unconvovledCovariates ] = makeEyeSignalCovariates(subjectID, runName);
    pupilStruct = [];
    % resample the pupil data to the same temporal resolution as the BOLD data
    pupilStruct.timebase = covariates.timebase;
    pupilStruct.values = unconvovledCovariates.pupilDiameter;
    for ii = 1:size(windowIndices,1)
        startingTime = timebase(windowIndices(ii,1));
        endingTime = timebase(windowIndices(ii,2));
        [~, startingPupilIndex ] = min(abs(pupilStruct.timebase - startingTime));
        [~, endingPupilIndex ] = min(abs(pupilStruct.timebase - endingTime));
        
        pupilValues(ii) = nanmean(pupilStruct.values(startingPupilIndex:endingPupilIndex));
        
    end
    
    for ii = 1:length(timeVaryingCorrelations)
        
        % determine which subplot we're adding to
        if strcmp(connectionTypes{ii}, 'homotopic')
            subplotValue = 1;
        elseif strcmp(connectionTypes{ii}, 'hierarchical')
            subplotValue = 2;
        elseif strcmp(connectionTypes{ii}, 'background')
            subplotValue = 3;
        end
        subplot(1,3,subplotValue); hold on;
        
        plot(pupilValues, timeVaryingCorrelations{ii}, '.', 'Color', 'k');
        
    end
    
end
ax1 = subplot(1,3,1);
title('Homotopic')
xlabel('Pupil Diameter Convolved (mm)');
ylabel(p.Results.correlationMethod);

ax2 = subplot(1,3,2);
title('Hierarchical')
xlabel('Pupil Diameter Convolved (mm)');
ylabel(p.Results.correlationMethod);

ax3 = subplot(1,3,3);
title('Background')
xlabel('Pupil Diameter Convolved (mm)');
ylabel(p.Results.correlationMethod);

linkaxes([ax1, ax2, ax3]);

end