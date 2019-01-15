function [ concatenatedEyeRegressors ] = concatenateEyeRegressors(subjectID, scanType)

paths = definePaths(subjectID);
%load('/Users/harrisonmcadams/Dropbox (Aguirre-Brainard Lab)/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3003/tfMRI_FLASH_PA_run2_timebase.mat')
%% Find the relevant data files

potentialRunTimebases = dir(fullfile(paths.pupilDir, ['*', scanType, '*_timebase.mat']));
%plotFig = figure;
%hold on
newTimebase = [];
newPupilRadius = [];
for rr = 1:length(potentialRunTimebases)
    % figure out which number run this is
    splitFileName = strsplit(potentialRunTimebases(rr).name, 'Run');
    runNumber = str2num(splitFileName{2}(1));
    temporalOffset = ((runNumber - 1) * 336000);
    
    % load original timebase
    load(fullfile(paths.pupilDir, potentialRunTimebases(rr).name));
    
    % adjust timebase
    shiftedTimebase = timebase.values + temporalOffset;
    
    % load pupil time series
    load(fullfile(paths.pupilDir, [splitFileName{1}, 'run', num2str(runNumber), '_pupil.mat']));
    pupilRadius = pupilData.radiusSmoothed.eyePoses.values(:,4);
    
    
    
    % censor pupil values occuring before and after the BOLD run
    firstTimepoint = temporalOffset;
    lastTimepoint = temporalOffset + 335200;
    earlyIndices = find(shiftedTimebase < firstTimepoint);
    lateIndices = find(shiftedTimebase > lastTimepoint);
    shiftedTimebase([earlyIndices; lateIndices]) = [];
    pupilRadius([earlyIndices; lateIndices]) = [];
    
    newTimebase = [newTimebase; shiftedTimebase];
    newPupilRadius = [newPupilRadius; pupilRadius];
    
    %plot(shiftedTimebase, pupilRadius)
    
end

temporalFit = tfeIAMP('verbosity','none');
originalStruct.values = newPupilRadius';
originalStruct.timebase = newTimebase';
desiredTimebase = 0:800:1680*800-800;
[resampledStruct] = temporalFit.resampleTimebase(originalStruct, desiredTimebase);

meanPupilRadius = nanmean(resampledStruct.values);
pupilDiameterPercentageChange = (resampledStruct.values - meanPupilRadius)./meanPupilRadius;
NaNIndices = find(isnan(pupilDiameterPercentageChange));
pupilDiameterPercentageChange(NaNIndices) = 0;
csvwrite(fullfile(paths.pupilDir, 'eyeRegressors.csv'), pupilDiameterPercentageChange');

end