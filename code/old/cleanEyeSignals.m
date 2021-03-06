function cleanEyeSignals(subjectList)

if isempty(subjectList)
    subjectList = {'TOME_3001', 'TOME_3002', 'TOME_3003', 'TOME_3004', 'TOME_3005', 'TOME_3007', 'TOME_3008', 'TOME_3009', 'TOME_3011', 'TOME_3012', 'TOME_3013', 'TOME_3014', 'TOME_3015', 'TOME_3016', 'TOME_3017', 'TOME_3018', 'TOME_3019', 'TOME_3020', 'TOME_3021', 'TOME_3022'};
end

%% assemble list of runs across subjects
counter = 1;
for ss = 1:length(subjectList)
    potentialRuns = dir(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectList{ss}, '*_physioMotionWMVCorrected.mat'));
    subjectID = subjectList{ss};
    
    for rr = 1:length(potentialRuns)
        subjectListPooled{counter} = subjectID;
        runListPooled{counter} = potentialRuns(rr).name;
        counter = counter + 1;
    end
    
    
end

%% copy over the pupil data
% to ensure we have the latest version
downloadPupil = false;

if downloadPupil
    
    for rr = 11:length(runListPooled)
        
        runName = strsplit(runListPooled{rr}, '_timeSeries');
        runName = runName{1};
        getSubjectData(subjectListPooled{rr}, runName, 'downloadOnly', 'pupil')
        
    end
    
end

%% look at variance explained by eye signals, averaged across subjects
rSquaredPooled = [];
for rr = 1:length(runListPooled)
    runName = strsplit(runListPooled{rr}, '_timeSeries');
    runName = runName{1};
    subjectID = subjectListPooled{rr};
    cleanedTimeSeriesStruct = load(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID, [runName '_timeSeries_physioMotionWMVCorrected.mat']));
    areasList = {1, 2, 3};
    anglesList = {[0 90], [90 180]};
    eccenRange = [0 20];
    laterality = {'lh', 'rh'};
    
    eyeSignalsRemovedCleanedMeanTimeSeries = [];
    
    for area = 1:length(areasList)
        
        for aa = 1:length(anglesList)
            
            for side = 1:length(laterality)
                
                if isequal(anglesList{aa}, [0 90])
                    dorsalOrVentral = 'v';
                elseif isequal(anglesList{aa}, [90 180])
                    dorsalOrVentral = 'd';
                end
                
                
                
                maskName = ['V', num2str(areasList{area}), dorsalOrVentral, '_', laterality{side}, '_mask'];
                
                cleanedTimeSeries = cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V1Combined;
                
                pupilResponse = [];
                pupilDiameter = [];
                pupilTimebase = [];
                azimuth = [];
                elevation = [];
                
                % load up the pupil data
                pupilDir = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID);
                
                pupilResponse = load(fullfile(pupilDir, [runName, '_pupil.mat']));
                pupilDiameter = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,4);
                
                pupilTimebase = load(fullfile(pupilDir, [runName, '_timebase.mat']));
                pupilTimebase = pupilTimebase.timebase.values';
                
                azimuth = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,1);
                elevation = pupilResponse.pupilData.radiusSmoothed.eyePoses.values(:,2);
                
                eyeDisplacement = (diff(azimuth).^2 + diff(elevation).^2).^(1/2);
                
                % get blinks
                controlFile = fopen(fullfile(pupilDir, [runName, '_controlFile.csv']));
                
                % import values in a cell with textscan
                instructionCell = textscan(controlFile,'%f%s%[^\n]','Delimiter',',');
                blinkRows = find(contains(instructionCell{2}, 'blink'));
                
                blinkFrames = [];
                for ii = blinkRows
                    blinkFrames = [blinkFrames, instructionCell{1}(blinkRows(ii))];
                end
                blinks = zeros(1,length(pupilTimebase));
                blinks(blinkFrames) = 1;
                fclose(controlFile);
                
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
                badIndices = find(pupilResponse.pupilData.radiusSmoothed.ellipses.RMSE > 3);
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
                
                
                regressors = [eyeDisplacementConvolved; firstDerivativeEyeDisplacementConvolved; pupilDiameterConvolved; firstDerivativePupilDiameterConvolved; blinksConvolved; firstDerivativeBlinksConvolved];
                
                
                
                
                
                [ eyeSignalsRemovedCleanedMeanTimeSeries.(maskName) ] = cleanTimeSeries( cleanedTimeSeriesStruct.cleanedMeanTimeSeries.(maskName), regressors', pupilTimebase);

            end
        end
    end
    
    save(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID, [runName '_timeSeries_physioMotionWMVCorrected_eyeSignalsRemoved']), 'eyeSignalsRemovedCleanedMeanTimeSeries', '-v7.3');

end

%% make average correlation matrix
desiredOrder = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};

for rr = 1:length(runListPooled)
    runName = strsplit(runListPooled{rr}, '_timeSeries');
    runName = runName{1};
    subjectID = subjectListPooled{rr};
    cleanedTimeSeries = load(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID, [runName '_timeSeries_physioMotionWMVCorrected_eyeSignalsRemoved']));
    cleanedTimeSeries = cleanedTimeSeries.eyeSignalsRemovedCleanedMeanTimeSeries;
    [ combinedCorrelationMatrix_postEye, acrossHemisphereCorrelationMatrix_postEye] = makeCorrelationMatrix(cleanedTimeSeries, 'desiredOrder', desiredOrder);
    save(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'correlationMatrices', subjectID, [runName '_postEye']), 'combinedCorrelationMatrix_postEye', 'acrossHemisphereCorrelationMatrix_postEye', '-v7.3');
end

end