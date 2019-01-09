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

% pupil change
pupilChange = diff(pupilDiameter);
pupilChange = [NaN; pupilChange];

% rectified pupil change
rectifiedPupilChange = abs(diff(pupilDiameter));
rectifiedPupilChange = [NaN; rectifiedPupilChange];

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
[rectifiedPupilChangeConvolved] = convolveRegressorWithHRF(rectifiedPupilChange, pupilTimebase);
[eyeDisplacementConvolved] = convolveRegressorWithHRF(eyeDisplacement, pupilTimebase);
[blinksConvolved] = convolveRegressorWithHRF(blinks', pupilTimebase);

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
covariates.pupilTimebase = pupilTimebase;

%% Try bandpass filtering the raw pupil diameter in an attempt to replicate prior work from Schnieder and Yellin
% interpolate NaN values
badIndices = find(pupilResponse.pupilData.radiusSmoothed.ellipses.RMSE > 3);
pupilDiameter = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,4);
pupilDiameter(badIndices) = NaN;
notNan = ~isnan(pupilDiameter);
myFit = fit(pupilTimebase(notNan)',pupilResponse.pupilData.radiusSmoothed.eyePoses.values(notNan,4),'linearinterp');
dataStruct.timebase = pupilTimebase';
dataStruct.values = myFit(dataStruct.timebase)';
ts = timeseries(dataStruct.values,dataStruct.timebase);
tsOut = idealfilter(ts,[0.001/1000 0.01/1000],'notch');
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
[ pupilDiameterBanpassedConvolved ] = convolveRegressorWithHRF(pupilDiameterBandpassed', pupilTimebase);
firstDerivativePupilDiameterBandpassedConvolved = diff(pupilDiameterBanpassedConvolved);
firstDerivativePupilDiameterBandpassedConvolved = [NaN, firstDerivativePupilDiameterBandpassedConvolved];
covariates.pupilDiameterBanpassedConvolved = pupilDiameterBanpassedConvolved;
covariates.firstDerivativePupilDiameterBandpassedConvolved = firstDerivativePupilDiameterBandpassedConvolved;

pupilChangeBandpassed = diff(pupilDiameterBandpassed);
pupilChangeBandpassed = [NaN, pupilChangeBandpassed];
[ pupilChangeBandpassedConvolved ] = convolveRegressorWithHRF(pupilChangeBandpassed', pupilTimebase);
firstDerivativePupilChangeBandpassedConvolved = diff(pupilChangeBandpassedConvolved);
firstDerivativePupilChangeBandpassedConvolved =  [NaN, firstDerivativePupilChangeBandpassedConvolved];
covariates.pupilChangeBandpassedConvolved = pupilChangeBandpassedConvolved;
covariates.firstDerivativePupilChangeBandpassedConvolved = firstDerivativePupilChangeBandpassedConvolved;

rectifiedPupilChangeBandpassed = abs(diff(pupilDiameterBandpassed));
rectifiedPupilChangeBandpassed = [NaN, rectifiedPupilChangeBandpassed];
[ rectifiedPupilChangeBandpassedConvolved ] = convolveRegressorWithHRF(rectifiedPupilChangeBandpassed', pupilTimebase);
firstDerivativeRectifiedPupilChangeBandpassed = diff(rectifiedPupilChangeBandpassedConvolved);
firstDerivativeRectifiedPupilChangeBandpassed = [NaN, firstDerivativeRectifiedPupilChangeBandpassed];
covariates.rectifiedPupilChangeBandpassed = rectifiedPupilChangeBandpassed;
covariates.firstDerivativeRectifiedPupilChangeBandpassed = firstDerivativeRectifiedPupilChangeBandpassed;




end