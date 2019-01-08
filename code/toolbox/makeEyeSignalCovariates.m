function [ covariates ] = makeEyeSignalCovariates(subjectID, runName)
%
%
% Examples:
%{
    subjectID = 'TOME_3003';
    runName = 'rfMRI_REST_AP_Run1';
    covariates = makeEyeSignalCovariates(subjectID, runName);
%}

%% Setup
% find the data, load it up
pupilDir = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID);
pupilResponse = load(fullfile(pupilDir, [runName, '_pupil.mat']));

% create timebase which applies to all covariates
pupilTimebase = load(fullfile(pupilDir, [runName, '_timebase.mat']));
pupilTimebase = pupilTimebase.timebase.values';

% determine which indices have poor pupil fits. we will censor out these
% data points for each covariate
badIndices = find(pupilResponse.pupilData.radiusSmoothed.ellipses.RMSE > 3);

%% Create the different covariates
% pupil diameter
pupilDiameter = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,4);
pupilDiameter(badIndices) = NaN;

% rectified pupil change
pupilChange = abs(diff(pupilDiameter));
pupilChange = [NaN; pupilChange];

% "saccades"
azimuth = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,1);
azimuth(badIndices) = NaN;
elevation = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,2);
elevation(badIndices) = NaN;
eyeDisplacement = (diff(azimuth).^2 + diff(elevation).^2).^(1/2);
eyeDisplacement = [NaN; eyeDisplacement];

% blinks
controlFile = fopen(fullfile(pupilDir, [runName, '_controlFile.csv']));
instructionCell = textscan(controlFile,'%f%s%[^\n]','Delimiter',',');
blinkRows = find(contains(instructionCell{2}, 'blink'));
blinkFrames = [];
for ii = blinkRows
    blinkFrames = [blinkFrames, instructionCell{1}(blinkRows(ii))];
end
blinks = zeros(1,length(pupilTimebase));
blinks(blinkFrames) = 1;
fclose(controlFile);

%% Convolve with HRF
[pupilDiameterConvolved] = convolveRegressorWithHRF(pupilDiameter, pupilTimebase);
[pupilChangeConvolved] = convolveRegressorWithHRF(pupilChange, pupilTimebase);
[eyeDisplacementConvolved] = convolveRegressorWithHRF(eyeDisplacement, pupilTimebase);
[blinksConvolved] = convolveRegressorWithHRF(blinks', pupilTimebase);

%% Make first derivative of convolved HRF to account for temporal timing differences

firstDerivativePupilDiameterConvolved = diff(pupilDiameterConvolved);
firstDerivativePupilDiameterConvolved = [NaN, firstDerivativePupilDiameterConvolved];
firstDerivativePupilChangeConvolved = diff(pupilChangeConvolved);
firstDerivativePupilChangeConvolved = [NaN, firstDerivativePupilChangeConvolved];
firstDerivativeEyeDisplacementConvolved = diff(eyeDisplacementConvolved);
firstDerivativeEyeDisplacementConvolved = [NaN, firstDerivativeEyeDisplacementConvolved];
firstDerivativeBlinksConvolved = diff(blinksConvolved);
firstDerivativeBlinksConvolved = [NaN, firstDerivativeBlinksConvolved];

%% Package them up
covariates = [];
covariates.pupilDiameterConvolved = pupilDiameterConvolved;
covariates.firstDerivativePupilDiameterConvolved = firstDerivativePupilDiameterConvolved;
covariates.pupilChangeConvolved = pupilChangeConvolved;
covariates.firstDerivativePupilChangeConvolved = firstDerivativePupilChangeConvolved;
covariates.eyeDisplacementConvolved = eyeDisplacementConvolved;
covariates.firstDerivativeEyeDisplacementConvolved = firstDerivativeEyeDisplacementConvolved;
covariates.blinksConvolved = blinksConvolved;
covariates.firstDerivativeBlinksConvolved = firstDerivativeBlinksConvolved;
covariates.pupilTimebase = pupilTimebase;


end