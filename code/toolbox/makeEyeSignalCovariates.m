function [ covariates, unconvolvedCovariates ] = makeEyeSignalCovariates(subjectID, runName)
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
if contains(runName, 'hp2000_clean')
    splitRunName = strsplit(runName, '_hp2000_clean');
    runName = splitRunName{1};
end
pupilResponse = load(fullfile(pupilDir, [runName, '_pupil.mat']));

% create timebase which applies to all covariates
pupilTimebase = load(fullfile(pupilDir, [runName, '_timebase.mat']));
pupilTimebase = pupilTimebase.timebase.values';

% determine which indices have poor pupil fits. we will censor out these
% data points for each covariate
badIndices = find(pupilResponse.pupilData.radiusSmoothed.ellipses.RMSE > 3);

%% Create the different covariates
% pupil diameter
pupilDiameter = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,4)';
pupilDiameter(badIndices) = NaN;

% pupil change
pupilChange = diff(pupilDiameter);
pupilChange = [NaN, pupilChange];

% rectified pupil change
rectifiedPupilChange = abs(diff(pupilDiameter));
rectifiedPupilChange = [NaN, rectifiedPupilChange];

% "saccades"
azimuth = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,1)';
azimuth(badIndices) = NaN;
elevation = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,2)';
elevation(badIndices) = NaN;
eyeDisplacement = (diff(azimuth).^2 + diff(elevation).^2).^(1/2);
eyeDisplacement = [NaN, eyeDisplacement];

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

% PUI
PUI1000 = movstd(pupilDiameter, 1000, 'omitnan');
PUI10000 = movstd(pupilDiameter, 10000, 'omitnan');
PUI100 = movstd(pupilDiameter, 100, 'omitnan');
PUI5000 = movstd(pupilDiameter, 5000, 'omitnan');

%dilations
dilations = zeros(1,length(pupilChange));
dilations(find(pupilChange > 0)) = pupilChange(find(pupilChange > 0));

% constrictions
constrictions = zeros(1, length(pupilChange));
constrictions(find(pupilChange < 0)) = pupilChange(find(pupilChange < 0));



%% Convolve with HRF
[pupilDiameterConvolved] = convolveRegressorWithHRF(pupilDiameter, pupilTimebase);
[pupilChangeConvolved] = convolveRegressorWithHRF(pupilChange, pupilTimebase);
[rectifiedPupilChangeConvolved] = convolveRegressorWithHRF(rectifiedPupilChange, pupilTimebase);
[eyeDisplacementConvolved] = convolveRegressorWithHRF(eyeDisplacement, pupilTimebase);
[blinksConvolved] = convolveRegressorWithHRF(blinks, pupilTimebase);
[PUI1000Convolved] = convolveRegressorWithHRF(PUI1000, pupilTimebase);
[PUI10000Convolved] = convolveRegressorWithHRF(PUI10000, pupilTimebase);
[PUI100Convolved] = convolveRegressorWithHRF(PUI100, pupilTimebase);
[PUI5000Convolved] = convolveRegressorWithHRF(PUI5000, pupilTimebase);
[dilationsConvolved ] = convolveRegressorWithHRF(dilations, pupilTimebase);
[constrictionsConvolved] = convolveRegressorWithHRF(constrictions, pupilTimebase);


%% Make first derivative of convolved HRF to account for temporal timing differences

firstDerivativePupilDiameterConvolved = diff(pupilDiameterConvolved);
firstDerivativePupilDiameterConvolved = [NaN, firstDerivativePupilDiameterConvolved];
firstDerivativePupilChangeConvolved = diff(pupilChangeConvolved);
firstDerivativePupilChangeConvolved = [NaN, firstDerivativePupilChangeConvolved];
firstDerivativeRectifiedPupilChangeConvolved = diff(rectifiedPupilChangeConvolved);
firstDerivativeRectifiedPupilChangeConvolved = [NaN, firstDerivativeRectifiedPupilChangeConvolved];
firstDerivativeEyeDisplacementConvolved = diff(eyeDisplacementConvolved);
firstDerivativeEyeDisplacementConvolved = [NaN, firstDerivativeEyeDisplacementConvolved];
firstDerivativeBlinksConvolved = diff(blinksConvolved);
firstDerivativeBlinksConvolved = [NaN, firstDerivativeBlinksConvolved];
firstDerivativePUI1000Convolved = diff(PUI1000Convolved);
firstDerivativePUI1000Convolved = [NaN, firstDerivativePUI1000Convolved];
firstDerivativePUI10000Convolved = diff(PUI10000Convolved);
firstDerivativePUI10000Convolved = [NaN, firstDerivativePUI10000Convolved];
firstDerivativePUI100Convolved = diff(PUI100Convolved);
firstDerivativePUI100Convolved = [NaN, firstDerivativePUI100Convolved];
firstDerivativePUI5000Convolved = diff(PUI5000Convolved);
firstDerivativePUI5000Convolved = [NaN, firstDerivativePUI5000Convolved];
firstDerivativeDilationsConvolved = diff(dilationsConvolved);
firstDerivativeDilationsConvolved = [NaN, firstDerivativeDilationsConvolved];
firstDerivativeConstrictionsConvolved = diff(constrictionsConvolved);
firstDerivativeConstrictionsConvolved = [NaN, firstDerivativeConstrictionsConvolved];
%% Package them up
covariates = [];
covariates.pupilDiameterConvolved = pupilDiameterConvolved;
covariates.firstDerivativePupilDiameterConvolved = firstDerivativePupilDiameterConvolved;
covariates.pupilChangeConvolved = pupilChangeConvolved;
covariates.firstDerivativePupilChangeConvolved = firstDerivativePupilChangeConvolved;
covariates.rectifiedPupilChangeConvolved = rectifiedPupilChangeConvolved;
covariates.firstDerivativeRectifiedPupilChangeConvolved = firstDerivativeRectifiedPupilChangeConvolved;
covariates.eyeDisplacementConvolved = eyeDisplacementConvolved;
covariates.firstDerivativeEyeDisplacementConvolved = firstDerivativeEyeDisplacementConvolved;
covariates.blinksConvolved = blinksConvolved;
covariates.firstDerivativeBlinksConvolved = firstDerivativeBlinksConvolved;
covariates.PUI1000Convolved = PUI1000Convolved;
covariates.firstDerivativePUI1000Convolved = firstDerivativePUI1000Convolved;
covariates.PUI10000Convolved = PUI10000Convolved;
covariates.firstDerivativePUI10000Convolved = firstDerivativePUI10000Convolved;
covariates.PUI100Convolved = PUI100Convolved;
covariates.firstDerivativePUI100Convolved = firstDerivativePUI100Convolved;
covariates.PUI5000Convolved = PUI5000Convolved;
covariates.firstDerivativePUI5000Convolved = firstDerivativePUI5000Convolved;
covariates.dilationsConvolved = dilationsConvolved;
covariates.firstDerivativeDilationsConvolved = firstDerivativeDilationsConvolved;
covariates.constrictionsConvolved = constrictionsConvolved;
covariates.firstDerivativeConstrictionsConvolved = firstDerivativeConstrictionsConvolved;
covariates.timebase = pupilTimebase;

%% Try bandpass filtering the raw pupil diameter in an attempt to replicate prior work from Schnieder and Yellin
% interpolate NaN values
badIndices = find(pupilResponse.pupilData.radiusSmoothed.ellipses.RMSE > 3);
pupilDiameterForBandpassed = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,4)';
pupilDiameterForBandpassed(badIndices) = NaN;
notNan = ~isnan(pupilDiameterForBandpassed);
myFit = fit(pupilTimebase(notNan)',pupilResponse.pupilData.radiusSmoothed.eyePoses.values(notNan,4),'linearinterp');
dataStruct.timebase = pupilTimebase';
dataStruct.values = myFit(dataStruct.timebase)';
ts = timeseries(dataStruct.values,dataStruct.timebase);
tsOut = idealfilter(ts,[0.001/1000 0.01/1000],'pass');
k=permute(tsOut.Data,[1 3 2]);
filtData.timebase = tsOut.Time';
filtData.values = k+nanmean((pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,4)));

% plot to show comparison
plot = false;
if (plot)
    plotFig = figure;
    subplot(1,2,1);
    plot(pupilTimebase, pupilDiameter);
    hold on
    plot(filtData.timebase, filtData.values);
    legend('Unfiltered', 'Bandpass Filtered')
    xlabel('Time (ms)')
    ylabel('Pupil Diameter (mm)')
    
    % demonstrate efficacy of filter
    psdStructPreFilter = calcOneSidedPSD(dataStruct,'meanCenter',true);
    psdStructPostFilter = calcOneSidedPSD(filtData,'meanCenter',true);
    subplot(1,2,2);
    semilogx(psdStructPreFilter.timebase,psdStructPreFilter.values);
    hold on
    semilogx(psdStructPostFilter.timebase,psdStructPostFilter.values);
    legend('Unfiltered', 'Bandpass Filtered')
end

%% Make covariates that have been bandpass filtered
pupilDiameterBandpassed = filtData.values;
[ pupilDiameterBandpassedConvolved ] = convolveRegressorWithHRF(pupilDiameterBandpassed, pupilTimebase);
firstDerivativePupilDiameterBandpassedConvolved = diff(pupilDiameterBandpassedConvolved);
firstDerivativePupilDiameterBandpassedConvolved = [NaN, firstDerivativePupilDiameterBandpassedConvolved];
covariates.pupilDiameterBandpassedConvolved = pupilDiameterBandpassedConvolved;
covariates.firstDerivativePupilDiameterBandpassedConvolved = firstDerivativePupilDiameterBandpassedConvolved;

pupilChangeBandpassed = diff(pupilDiameterBandpassed);
pupilChangeBandpassed = [NaN, pupilChangeBandpassed];
[ pupilChangeBandpassedConvolved ] = convolveRegressorWithHRF(pupilChangeBandpassed, pupilTimebase);
firstDerivativePupilChangeBandpassedConvolved = diff(pupilChangeBandpassedConvolved);
firstDerivativePupilChangeBandpassedConvolved =  [NaN, firstDerivativePupilChangeBandpassedConvolved];
covariates.pupilChangeBandpassedConvolved = pupilChangeBandpassedConvolved;
covariates.firstDerivativePupilChangeBandpassedConvolved = firstDerivativePupilChangeBandpassedConvolved;

rectifiedPupilChangeBandpassed = abs(diff(pupilDiameterBandpassed));
rectifiedPupilChangeBandpassed = [NaN, rectifiedPupilChangeBandpassed];
[ rectifiedPupilChangeBandpassedConvolved ] = convolveRegressorWithHRF(rectifiedPupilChangeBandpassed, pupilTimebase);
firstDerivativeRectifiedPupilChangeBandpassedConvolved = diff(rectifiedPupilChangeBandpassedConvolved);
firstDerivativeRectifiedPupilChangeBandpassedConvolved = [NaN, firstDerivativeRectifiedPupilChangeBandpassedConvolved];
covariates.rectifiedPupilChangeBandpassedConvolved = rectifiedPupilChangeBandpassed;
covariates.firstDerivativeRectifiedPupilChangeBandpassedConvolved = firstDerivativeRectifiedPupilChangeBandpassedConvolved;

%% Package up the unconvolved covariates
unconvolvedCovariates.pupilDiameter = pupilDiameter;
unconvolvedCovariates.pupilChange = pupilChange;
unconvolvedCovariates.rectifiedPupilChange = rectifiedPupilChange;
unconvolvedCovariates.eyeDisplacement = eyeDisplacement;
unconvolvedCovariates.pupilDiameterBandpassed = pupilDiameterBandpassed;
unconvolvedCovariates.pupilChangeBandpassed = pupilChangeBandpassed;
unconvolvedCovariates.rectifiedPupilChangeBandpassed = rectifiedPupilChangeBandpassed;
unconvolvedCovariates.dilations = dilations;
unconvolvedCovariates.constrictions = constrictions;
unconvolvedCovariates.blinks = blinks;

end