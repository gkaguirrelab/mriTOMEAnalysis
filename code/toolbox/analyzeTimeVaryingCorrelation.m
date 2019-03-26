function analyzeTimeVaryingCorrelation(subjectID, runName, varargin)

%{
subjectID = 'TOME_3005';
runName = 'rfMRI_REST_AP_Run1';
analyzeTimeVaryingCorrelation(subjectID, runName)
%}
%% Input parser
p = inputParser; p.KeepUnmatched = true;

p.addParameter('correlationMethod', 'slidingWindowPearson', @ischar);
p.addParameter('normalizeTimeVaryingCorrelation', false, @islogical);
p.addParameter('windowLength', 50, @isnumeric);
p.addParameter('TR', 800, @isnumeric);

p.parse(varargin{:});

%% Define the connections of interest
connections = { ...
    'V3d_lh+V3v_lh'};
connectionTypes = { ...
    'homotopic'};


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
for ii = 1:length(connections)
    splitConnections = strsplit(connections{ii}, '+');
    regionOne = splitConnections{1};
    regionTwo = splitConnections{2};
    
    timeVaryingCorrelations{end+1} = calculateTimeVaryingCorrelation(meanTimeSeries.([regionOne, '_mask']), meanTimeSeries.([regionTwo, '_mask']), p.Results.windowLength, 'correlationMethod', p.Results.correlationMethod, 'normalizeTimeVaryingCorrelation', p.Results.normalizeTimeVaryingCorrelation);
    
end

%% Get pupil time series
[ covariates ] = makeEyeSignalCovariates(subjectID, runName);
pupilStruct = [];
% resample the pupil data to the same temporal resolution as the BOLD data
pupilStruct.timebase = covariates.timebase;
pupilStruct.values = covariates.pupilDiameterConvolved;
temporalFit = tfeIAMP('verbosity','none');
pupilStruct = temporalFit.resampleTimebase(pupilStruct, timebase, 'resampleMethod', 'resample');

%% Plot to summarize
plotFig = figure; hold on;

for ii = 1:length(timeVaryingCorrelations)
    
    % determine which subplot we're adding to
    if strcmp(connectionTypes{ii}, 'homotopic')
        subplotValue = 1;
    elseif strcmp(connectionTypes{ii}, 'heterotopic')
        subplotValue = 2;
    end
    subplot(1,2,subplotValue); hold on;
    
    % do the plotting
    plot(pupilStruct.values, timeVaryingCorrelations{ii}, '.');
    
end

xlabel('Pupil Diameter Convolved (mm)');
ylabel(p.Results.correlationMethod);

end