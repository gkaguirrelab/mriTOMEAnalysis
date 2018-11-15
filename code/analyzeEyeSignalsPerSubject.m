function analyzeEyeSignalsPerSubject(subjectID, varargin)
p = inputParser; p.KeepUnmatched = true;
p.addParameter('whichRegressors','pupilDiameter', @ischar);
p.addParameter('RMSEThreshold',2, @isnum);

p.parse(varargin{:});

%% We know TOME_3005 to be a good subject in terms of pupillometry quality, so how does it look?
potentialRuns = dir(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID, '*physioMotionCorrected.mat'));
for rr = 1:length(potentialRuns)
    runNameFull = potentialRuns(rr).name;
    runNameSplit = strsplit(runNameFull, '.');
    runName = runNameSplit{1};
    cleanedTimeSeriesStruct = load(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID, potentialRuns(rr).name));
    pooledCleanedTimeSeries.(subjectID).(runName) = cleanedTimeSeriesStruct.cleanedMeanTimeSeries;
end

pupilDir = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID);
runNames = fieldnames(pooledCleanedTimeSeries.(subjectID));
pooledRSquared = [];
for rr = 1:length(runNames)
    runNameClean = strsplit(runNames{rr}, '_timeSeries');
    runNameClean = runNameClean{1};
    cleanedTimeSeries = pooledCleanedTimeSeries.(subjectID).(runNames{rr}).V1Combined;
    pupilResponse = [];
    pupilDiameter = [];
    pupilTimebase = [];
    azimuth = [];
    elevation = [];
    
    % load up the pupil data
    pupilResponse = load(fullfile(pupilDir, [runNameClean, '_pupil.mat']));
    pupilDiameter = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,4);
    
    pupilTimebase = load(fullfile(pupilDir, [runNameClean, '_timebase.mat']));
    pupilTimebase = pupilTimebase.timebase.values';
    
    azimuth = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,1);
    elevation = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,2);
    
    eyeDisplacement = (diff(azimuth).^2 + diff(elevation).^2).^(1/2);
    
    % get blinks
    controlFile = fopen(fullfile(pupilDir, [runNameClean, '_controlFile.csv']));

    % import values in a cell with textscan
    instructionCell = textscan(controlFile,'%f%s%[^\n]','Delimiter',',');
    blinkRows = find(contains(instructionCell{2}, 'blink'));
    
    blinkFrames = [];
    for ii = blinkRows
        blinkFrames = [blinkFrames, instructionCell{1}(blinkRows(ii))];
    end
    blinks = zeros(1,length(pupilTimebase));
    blinks(blinkFrames) = 1;
    
    % interpolate pupil diameter
    theNans = [];
    NaNIndices = [];
    theNaNs = isnan(pupilDiameter);
    NaNIndices = find(isnan(pupilDiameter));
    
    if sum(theNaNs) ~=0
        x = pupilDiameter;
        x(theNaNs) = interp1(pupilTimebase(~theNaNs), pupilDiameter(~theNaNs), pupilTimebase(theNaNs), 'linear');
        pupilDiameter = x;
    end
    
    % interpolate eye position
    theNans = [];
    NaNIndices = [];
    theNaNs = isnan(azimuth);
    NaNIndices = find(isnan(azimuth));
    
    if sum(theNaNs) ~=0
        x = azimuth;
        x(theNaNs) = interp1(pupilTimebase(~theNaNs), azimuth(~theNaNs), pupilTimebase(theNaNs), 'linear');
        azimuth = x;
    end
    
    theNans = [];
    NaNIndices = [];
    theNaNs = isnan(elevation);
    NaNIndices = find(isnan(elevation));
    
    if sum(theNaNs) ~=0
        x = elevation;
        x(theNaNs) = interp1(pupilTimebase(~theNaNs), elevation(~theNaNs), pupilTimebase(theNaNs), 'linear');
        elevation = x;
    end
    
    theNans = [];
    NaNIndices = [];
    theNaNs = isnan(eyeDisplacement);
    NaNIndices = find(isnan(eyeDisplacement));
    
    if sum(theNaNs) ~=0
        x = eyeDisplacement;
        x(theNaNs) = interp1(pupilTimebase(~theNaNs), eyeDisplacement(~theNaNs), pupilTimebase(theNaNs), 'linear');
        eyeDisplacement = x;
    end
    eyeDisplacement = [0; eyeDisplacement];
    
    % convolve regressors
    [pupilDiameterConvolved] = convolveRegressorWithHRF(pupilDiameter, pupilTimebase);
    [elevationConvolved] = convolveRegressorWithHRF(elevation, pupilTimebase);
    [azimuthConvolved] = convolveRegressorWithHRF(azimuth, pupilTimebase);
    [eyeDisplacementConvolved] = convolveRegressorWithHRF(eyeDisplacement, pupilTimebase);
    [blinksConvolved] = convolveRegressorWithHRF(blinks', pupilTimebase);

    
    % get first derivative of regressors
    firstDerivativePupilDiameterConvolved = diff(pupilDiameterConvolved);
    firstDerivativePupilDiameterConvolved = [NaN, firstDerivativePupilDiameterConvolved];
    
    firstDerivativeElevationConvolved = diff(elevationConvolved);
    firstDerivativeElevationConvolved = [NaN, firstDerivativeElevationConvolved];
    
    firstDerivativeAzimuthConvolved = diff(azimuthConvolved);
    firstDerivativeAzimuthConvolved = [NaN, firstDerivativeAzimuthConvolved];
    
    firstDerivativeEyeDisplacementConvolved = diff(eyeDisplacementConvolved);
    firstDerivativeEyeDisplacementConvolved = [NaN, firstDerivativeEyeDisplacementConvolved];
    
    firstDerivativeBlinksConvolved = diff(blinksConvolved);
    firstDerivativeBlinksConvolved = [NaN, firstDerivativeBlinksConvolved];
    
    
    
    
    
    % remove bad data points on the basis of RMSE
    badIndices = find(pupilResponse.pupilData.radiusSmoothed.ellipses.RMSE > p.Results.RMSEThreshold);
    % combine these bad data points with original NaNs
    badIndices = [badIndices; NaNIndices];
    
    pupilDiameterConvolved(badIndices) = NaN;
    firstDerivativePupilDiameterConvolved(badIndices) = NaN;
    
    azimuthConvolved(badIndices) = NaN;
    firstDerivativeAzimuthConvolved(badIndices) = NaN;
    
    elevationConvolved(badIndices) = NaN;
    firstDerivativeElevationConvolved(badIndices) = NaN;
    
    eyeDisplacementConvolved(badIndices) = NaN;
    firstDerivativeEyeDiscplacementConvolved(badIndices) = NaN;
    
    blinksConvolved(badIndices) = NaN;
    firstDerivativeBlinksConvolved(badIndices) = NaN;
    
    % assemble regressor variable
    if strcmp(p.Results.whichRegressors, 'pupilDiameter')
        regressors = [pupilDiameterConvolved; firstDerivativePupilDiameterConvolved];
    elseif strcmp(p.Results.whichRegressors, 'eyePosition')
        regressors = [elevationConvolved; firstDerivativeElevationConvolved; azimuthConvolved; firstDerivativeAzimuthConvolved];
        
    elseif strcmp(p.Results.whichRegressors, 'eyeDisplacement')
        regressors = [eyeDisplacementConvolved; firstDerivativeEyeDisplacementConvolved];
    elseif strcmp(p.Results.whichRegressors, 'blinks')
        regressors = [blinksConvolved; firstDerivativeBlinksConvolved];
    elseif strcmp(p.Results.whichRegressors, 'allRegressors')
        %regressors = [elevationConvolved; firstDerivativeElevationConvolved; azimuthConvolved; firstDerivativeAzimuthConvolved; pupilDiameterConvolved; firstDerivativePupilDiameterConvolved];
        regressors = [eyeDisplacementConvolved; firstDerivativeEyeDisplacementConvolved; pupilDiameterConvolved; firstDerivativePupilDiameterConvolved];

    end
    
    
    
    [ ~, stats ] = cleanTimeSeries( cleanedTimeSeries, regressors', pupilTimebase);
    pooledRSquared(end + 1) = stats.rSquared;
end


%% Report
fprintf('%s explains %.1f%% of variance for %s\n', p.Results.whichRegressors, mean(pooledRSquared)*100, subjectID);






end