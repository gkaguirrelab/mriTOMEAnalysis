function analyzeEyeSignals()




%% get cleaned time series
potentialSubjects = dir(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries'));
for ss = 1:length(potentialSubjects)
    potentialRuns = dir(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', potentialSubjects(ss).name, '*physioMotionCorrected.mat'));
    subjectID = potentialSubjects(ss).name;
    if ~strcmp(subjectID, 'TOME_3003')
        for rr = 1:length(potentialRuns)
            runNameFull = potentialRuns(rr).name;
            runNameSplit = strsplit(runNameFull, '.');
            runName = runNameSplit{1};
            cleanedTimeSeriesStruct = load(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', potentialSubjects(ss).name,potentialRuns(rr).name));
            pooledCleanedTimeSeries.(subjectID).(runName) = cleanedTimeSeriesStruct.cleanedMeanTimeSeries;
        end
    end
end

regionsWeCareAbout = {'V1d_lh_mask', 'V1v_rh_mask', 'V1d_lh_mask', 'V1d_rh_mask'};

%% Unshifted pupil diameter
subjectIDs = fieldnames(pooledCleanedTimeSeries);
pooledRSquared = [];
for ss = 1:length(subjectIDs)
    runNames = fieldnames(pooledCleanedTimeSeries.(subjectIDs{ss}));
    pupilDir = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectIDs{ss});
    for rr = 1:length(runNames)
        for ROI = 1:length(regionsWeCareAbout)
            try
                runNameClean = strsplit(runNames{rr}, '_timeSeries');
                runNameClean = runNameClean{1};
                cleanedTimeSeries = pooledCleanedTimeSeries.(subjectIDs{ss}).(runNames{rr}).(regionsWeCareAbout{ROI});
                
                pupilResponse = [];
                pupilDiameter = [];
                pupilTimebase = [];
                
                % load up the pupil data
                pupilResponse = load(fullfile(pupilDir, [runNameClean, '_pupil.mat']));
                pupilDiameter = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,4);
                
                pupilTimebase = load(fullfile(pupilDir, [runNameClean, '_timebase.mat']));
                pupilTimebase = pupilTimebase.timebase.values';
                
                theNaNs = isnan(pupilDiameter);
                NaNIndices = find(isnan(pupilDiameter));
                
                if sum(theNaNs) ~=0
                    x = pupilDiameter;
                    x(theNaNs) = interp1(pupilTimebase(~theNaNs), pupilDiameter(~theNaNs), pupilTimebase(theNaNs), 'linear');
                    pupilDiameter = x;
                end
                
                
                
                
                % convolve with HRF
                hrfParams.gamma1 = 6;   % positive gamma parameter (roughly, time-to-peak in secs)
                hrfParams.gamma2 = 12;  % negative gamma parameter (roughly, time-to-peak in secs)
                hrfParams.gammaScale = 10; % scaling factor between the positive and negative gamma componenets
                
                kernelStruct.timebase=linspace(0,15999,16000);
                
                % The timebase is converted to seconds within the function, as the gamma
                % parameters are defined in seconds.
                hrf = gampdf(kernelStruct.timebase/1000, hrfParams.gamma1, 1) - ...
                    gampdf(kernelStruct.timebase/1000, hrfParams.gamma2, 1)/hrfParams.gammaScale;
                kernelStruct.values=hrf;
                
                % Normalize the kernel to have unit amplitude
                [ kernelStruct ] = normalizeKernelArea( kernelStruct );
                temporalFit = tfeIAMP('verbosity','none');
                
                startingPupilValue = pupilDiameter(1);
                responseStruct.values = pupilDiameter' - startingPupilValue;
                responseStruct.timebase = pupilTimebase;
                [convResponseStruct,resampledKernelStruct] = temporalFit.applyKernel(responseStruct,kernelStruct);
                % censor out values less than the time of the kernel
                [value, index] = min(abs(pupilTimebase - (16000+pupilTimebase(1))));
                %convResponseStruct.values(1:index) = NaN;
                
                
                % Normalize the kernel to have unit amplitude
                %[ kernelStruct ] = normalizeKernelArea( kernelStruct );
                %pupilDiameterConvolved = conv(pupilDiameter', kernelStruct.values, 'full')*(pupilTimebase(2) - pupilTimebase(1));
                pupilDiameterConvolved = convResponseStruct.values + startingPupilValue;
                
                % remove bad data points
                RMSEThreshold = prctile(pupilResponse.pupilData.radiusSmoothed.ellipses.RMSE, 90);
                badIndices = find(pupilResponse.pupilData.radiusSmoothed.ellipses.RMSE > RMSEThreshold);
                badIndices = [badIndices; NaNIndices];
                pupilDiameterConvolved(badIndices) = NaN;
                
                
                
                
                
                
                
                [ ~, stats ] = cleanTimeSeries( cleanedTimeSeries, pupilDiameterConvolved', pupilTimebase+1000);
                pooledRSquared(end + 1) = stats.rSquared;
            catch
            end
            
        end
        
    end
end

meanRSquaredUnshiftedPupil = mean(pooledRSquared);
fprintf('Pupil diameter explains %.1f%% of variance across subjects\n', meanRSquaredUnshiftedPupil*100);

%% Shifted pupil diameter
subjectIDs = fieldnames(pooledCleanedTimeSeries);
pooledRSquared = [];
timeShift = -1000;
for ss = 1:length(subjectIDs)
    runNames = fieldnames(pooledCleanedTimeSeries.(subjectIDs{ss}));
    pupilDir = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectIDs{ss});
    for rr = 1:length(runNames)
        for ROI = 1:length(regionsWeCareAbout)
            try
                runNameClean = strsplit(runNames{rr}, '_timeSeries');
                runNameClean = runNameClean{1};
                cleanedTimeSeries = pooledCleanedTimeSeries.(subjectIDs{ss}).(runNames{rr}).(regionsWeCareAbout{ROI});
                
                % load up the pupil data
                pupilResponse = load(fullfile(pupilDir, [runNameClean, '_pupil.mat']));
                pupilDiameter = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,4);
                
                % remove bad data points
                %RMSEThreshold = prctile(pupilResponse.pupilData.radiusSmoothed.ellipses.RMSE, 90);
                %badIndices = find(pupilResponse.pupilData.radiusSmoothed.ellipses.RMSE > RMSEThreshold);
                %pupilDiameter(badIndices) = NaN;
                
                pupilTimebase = load(fullfile(pupilDir, [runNameClean, '_timebase.mat']));
                pupilTimebase = pupilTimebase.timebase.values';
                pupilTimebase = pupilTimebase + timeShift;
                
                
                [ ~, stats ] = cleanTimeSeries( cleanedTimeSeries, pupilDiameter, pupilTimebase);
                pooledRSquared(end + 1) = stats.rSquared;
            catch
            end
            
        end
        
    end
end

meanRSquaredShiftedPupil = mean(pooledRSquared);

%% Unshifted pupil derivative
subjectIDs = fieldnames(pooledCleanedTimeSeries);
pooledRSquared = [];
timeShift = 0;
for ss = 1:length(subjectIDs)
    runNames = fieldnames(pooledCleanedTimeSeries.(subjectIDs{ss}));
    pupilDir = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectIDs{ss});
    for rr = 1:length(runNames)
        for ROI = 1:length(regionsWeCareAbout)
            try
                runNameClean = strsplit(runNames{rr}, '_timeSeries');
                runNameClean = runNameClean{1};
                cleanedTimeSeries = pooledCleanedTimeSeries.(subjectIDs{ss}).(runNames{rr}).(regionsWeCareAbout{ROI});
                
                % load up the pupil data
                pupilResponse = load(fullfile(pupilDir, [runNameClean, '_pupil.mat']));
                pupilDiameter = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,4);
                pupilDeritative = diff(pupilDiameter);
                pupilDeritative(end+1) = 0;
                pupilTimebase = load(fullfile(pupilDir, [runNameClean, '_timebase.mat']));
                pupilTimebase = pupilTimebase.timebase.values';
                pupilTimebase = pupilTimebase + timeShift;
                
                
                [ ~, stats ] = cleanTimeSeries( cleanedTimeSeries, pupilDeritative, pupilTimebase);
                pooledRSquared(end + 1) = stats.rSquared;
            catch
            end
            
        end
        
    end
end

meanRSquaredUnshiftedPupilDeritative = mean(pooledRSquared);

%% Shifted pupil derivative
subjectIDs = fieldnames(pooledCleanedTimeSeries);
pooledRSquared = [];
timeShift = 1000;
for ss = 1:length(subjectIDs)
    runNames = fieldnames(pooledCleanedTimeSeries.(subjectIDs{ss}));
    pupilDir = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectIDs{ss});
    for rr = 1:length(runNames)
        for ROI = 1:length(regionsWeCareAbout)
            try
                runNameClean = strsplit(runNames{rr}, '_timeSeries');
                runNameClean = runNameClean{1};
                cleanedTimeSeries = pooledCleanedTimeSeries.(subjectIDs{ss}).(runNames{rr}).(regionsWeCareAbout{ROI});
                
                % load up the pupil data
                pupilResponse = load(fullfile(pupilDir, [runNameClean, '_pupil.mat']));
                pupilDiameter = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,4);
                pupilDeritative = diff(pupilDiameter);
                pupilDeritative(end+1) = 0;
                pupilTimebase = load(fullfile(pupilDir, [runNameClean, '_timebase.mat']));
                pupilTimebase = pupilTimebase.timebase.values';
                pupilTimebase = pupilTimebase + timeShift;
                
                
                [ ~, stats ] = cleanTimeSeries( cleanedTimeSeries, pupilDeritative, pupilTimebase);
                pooledRSquared(end + 1) = stats.rSquared;
            catch
            end
            
        end
        
    end
end

meanRSquaredShiftedPupilDeritative = mean(pooledRSquared);

%% Report
fprintf('Pupil diameter explains %.1f%% of variance across subjects\n', meanRSquaredUnshiftedPupil*100);
fprintf('Time-shifted Pupil diameter explains %.1f%% of variance across subjects\n', meanRSquaredShiftedPupil*100);
fprintf('Pupil derivative explains %.1f%% of variance across subjects\n', meanRSquaredUnshiftedPupilDeritative*100);
fprintf('Time-shifted Pupil derivative explains %.1f%% of variance across subjects\n', meanRSquaredShiftedPupilDeritative*100);





end