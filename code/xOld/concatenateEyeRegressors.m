function [ concatenatedEyeRegressors ] = concatenateEyeRegressors(subjectID, runNamesInOrder)

% Example:
%{
    subjectID = 'TOME_3003';
    runNames{1} = 'rfMRI_REST_AP_Run1'; runNames{2} = 'rfMRI_REST_PA_Run2'; runNames{3} = 'rfMRI_REST_AP_Run3'; runNames{4} = 'rfMRI_REST_PA_Run4';
    [ concatenatedEyeRegressors ] = concatenateEyeRegressors(subjectID, runNames)
%}

paths = definePaths(subjectID);
%% Find the relevant data files
% get the eye signal covariates from the first run to use as a template
[ ~, singleRunUnconvolvedCovariates ] = makeEyeSignalCovariates(subjectID, runNamesInOrder{1});
covariateTypes = fieldnames(singleRunUnconvolvedCovariates);
for ii = 1:length(covariateTypes)
    if ~contains(covariateTypes{ii}, 'timebase')
        concatenatedEyeRegressors.(covariateTypes{ii}) = [];
    end
end

%% Concatenate each covariate together
% after removing the timepoints before or after the functional scan itself
newTimebase = [];
for rr = 1:length(runNamesInOrder)
    % figure out which number run this is
    splitFileName = strsplit(runNamesInOrder{rr}, 'Run');
    runNumber = str2num(splitFileName{2}(1));
    temporalOffset = ((runNumber - 1) * 336000);
    
    % load original timebase
    [ convolvedCovariates, unconvolvedCovariates ] = makeEyeSignalCovariates(subjectID, runNamesInOrder{rr});
    timebase = convolvedCovariates.pupilTimebase;
    
    % adjust timebase
    shiftedTimebase = timebase + temporalOffset;
    firstTimepoint = temporalOffset;
    lastTimepoint = temporalOffset + 335200;
    earlyIndices = find(shiftedTimebase < firstTimepoint);
    lateIndices = find(shiftedTimebase > lastTimepoint);
    shiftedTimebase([earlyIndices, lateIndices]) = [];
    newTimebase = [newTimebase, shiftedTimebase];
    
    for ii = 1:length(covariateTypes)
        response = unconvolvedCovariates.(covariateTypes{ii});
        
        
        
        % censor pupil values occuring before and after the BOLD run
        
        response([earlyIndices, lateIndices]) = [];
        
        
        concatenatedEyeRegressors.(covariateTypes{ii}) = [concatenatedEyeRegressors.(covariateTypes{ii}), response];
    end
end

%% resample the covariates at the temporal resolution of the functional scan
for ii = 1:length(covariateTypes)
    temporalFit = tfeIAMP('verbosity','none');
    
    
    originalStruct.values =  concatenatedEyeRegressors.(covariateTypes{ii});
    originalStruct.timebase = newTimebase;
    desiredTimebase = 0:800:1680*800-800;
    [resampledStruct] = temporalFit.resampleTimebase(originalStruct, desiredTimebase, 'resampleMethod', 'resample');
    
    meanValue = nanmean(resampledStruct.values);
    concatenatedEyeRegressors.(covariateTypes{ii}) = (resampledStruct.values - meanValue)./meanValue;
    NaNIndices = find(isnan(concatenatedEyeRegressors.(covariateTypes{ii})));
    concatenatedEyeRegressors.(covariateTypes{ii})(NaNIndices) = 0;
    [convolvedCovariate] = convolveRegressorWithHRF(concatenatedEyeRegressors.(covariateTypes{ii})', resampledStruct.timebase);
    concatenatedEyeRegressors.([covariateTypes{ii}, 'Convolved']) = convolvedCovariate;
end

end