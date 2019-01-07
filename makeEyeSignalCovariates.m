function [ covariates ] = makeEyeSignalCovariates(subjectID, runName)

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

% pupil change
pupilChange = diff(pupilDiameter);
pupilChange = [NaN; pupilChange];

% constrictions
constrictions = zeros(1, length(pupilChange));
constrictions(find(pupilChange < 0)) = pupilChange(find(pupilChange < 0));

% dilations
dilations(find(pupilChange > 0)) = pupilChange(find(pupilChange > 0));
dilations = zeros(1,length(pupilChange));

% "saccades"
azimuth = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,1);
azimuth(badIndices) = NaN;
elevation = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,2);
elevation(badIndices) = NaN;
eyeDisplacement = (diff(azimuth).^2 + diff(elevation).^2).^(1/2);
eyeDisplacement = [NaN; eyeDisplacement];

%% Convolve with HRF
[pupilDiameterConvolved] = convolveRegressorWithHRF(pupilDiameter, pupilTimebase);
[constrictionsConvolved] = convolveRegressorWithHRF(constrictions', pupilTimebase);
[dilationsConvolved] = convolveRegressorWithHRF(dilations', pupilTimebase);
[pupilChangeConvolved] = convolveRegressorWithHRF(pupilChange, pupilTimebase);
[eyeDisplacementConvolved] = convolveRegressorWithHRF(eyeDisplacement, pupilTimebase);

%% Make first derivative of convolved HRF to account for temporal timing differences

firstDerivativePupilDiameterConvolved = diff(pupilDiameterConvolved);
firstDerivativePupilDiameterConvolved = [NaN, firstDerivativePupilDiameterConvolved];
firstDerivativeConstrictionsConvolved = diff(constrictionsConvolved);
firstDerivativeConstrictionsConvolved = [NaN, firstDerivativeConstrictionsConvolved];
firstDerivativeDilationsConvolved = diff(dilationsConvolved);
firstDerivativeDilationsConvolved = [NaN, firstDerivativeDilationsConvolved];
firstDerivativePupilChangeConvolved = diff(pupilChangeConvolved);
firstDerivativePupilChangeConvolved = [NaN, firstDerivativePupilChangeConvolved];
firstDerivativeEyeDisplacementConvolved = diff(eyeDisplacementConvolved);
firstDerivativeEyeDisplacementConvolved = [NaN, firstDerivativeEyeDisplacementConvolved];

%% Package them up
covariates = [];
covariates.pupilDiameterConvolved = pupilDiameterConvolved;
covariates.firstDerivativePupilDiameterConvolved = firstDerivativePupilDiameterConvolved;
covariates.constrictionsConvolved = constrictionsConvolved;
covariates.firstDerivativeConstrictionsConvolved = firstDerivativeConstrictionsConvolved;
covariates.dilationsConvolved = dilationsConvolved;
covariates.firstDerivativeDilationsConvolved = firstDerivativeDilationsConvolved;
covariates.pupilChangeConvolved = pupilChangeConvolved;
covariates.firstDerivativePupilChangeConvolved = firstDerivativePupilChangeConvolved;
covariates.eyeDisplacementConvolved = eyeDisplacementConvolved;
covariates.firstDerivativeEyeDisplacementConvolved = firstDerivativeEyeDisplacementConvolved;


end