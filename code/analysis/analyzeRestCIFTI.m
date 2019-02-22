function analyzeRestCIFTI(subjectID, runName, varargin)

p = inputParser; p.KeepUnmatched = true;

p.addParameter('covariatesToAnalyze', {'pupilDiameter+pupilChange'}, @iscell);
p.parse(varargin{:});
%% Define paths
[ paths ] = definePaths(subjectID);

freeSurferDir = paths.freeSurferDir;
anatDir = paths.anatDir;
pupilDir = paths.pupilDir;
functionalDir = paths.functionalDir;
outputDir = paths.outputDir;

%% Get the data and organize it

%getSubjectData(subjectID, runName, 'downloadOnly', 'pupil');

%% Smooth the functional file
functionalFile = fullfile(functionalDir, [runName, '_Atlas_hp2000_clean.dtseries.nii']);
[ smoothedGrayordinates ] = smoothCIFTI(functionalFile);

% mean center the time series of each grayordinate
[ cleanedTimeSeriesMatrix ] = meanCenterTimeSeries(smoothedGrayordinates);

% make dumnmy voxel indices. this doesn't really apply for grayordinate
% based analysis, but the code is expecting the variable to at least
% exist
voxelIndices = [];

clear smoothedGrayordinates
%% Make our masks

savePath = anatDir;
maskList = {'V1d_lh_mask', 'V1d_rh_mask', 'V1v_lh_mask', 'V1v_rh_mask', 'V2d_lh_mask', 'V2d_rh_mask', 'V2v_lh_mask', 'V2v_rh_mask', 'V3d_lh_mask', 'V3d_rh_mask', 'V3v_lh_mask', 'V3v_rh_mask'};
areasList = {1, 2, 3};
anglesList = {[0 90], [90 180]};
eccenRange = [0 90];
laterality = {'lh', 'rh'};

for area = 1:length(areasList)
    
    for aa = 1:length(anglesList)
        
        for side = 1:length(laterality)
            
            if isequal(anglesList{aa}, [0 90])
                dorsalOrVentral = 'v';
            elseif isequal(anglesList{aa}, [90 180])
                dorsalOrVentral = 'd';
            end
            
            
            
            maskName = ['V', num2str(areasList{area}), dorsalOrVentral, '_', laterality{side}, '_mask'];
            [masks.(maskName)] = makeMaskFromRetinoCIFTI(areasList{area}, eccenRange, anglesList{aa}, laterality{side}, 'saveName', fullfile(savePath,[maskName, '.dscalar.nii']));
            
            
            
        end
        
    end
    
end

[masks.V1Combined] = makeMaskFromRetinoCIFTI(1, eccenRange, [0 180], 'combined', 'saveName', fullfile(savePath,'V1Combined.dscalar.nii'));


%% extract the time series from the mask
for area = 1:length(areasList)
    
    for aa = 1:length(anglesList)
        
        for side = 1:length(laterality)
            
            if isequal(anglesList{aa}, [0 90])
                dorsalOrVentral = 'v';
            elseif isequal(anglesList{aa}, [90 180])
                dorsalOrVentral = 'd';
            end
            
            
            maskName = ['V', num2str(areasList{area}), dorsalOrVentral, '_', laterality{side}, '_mask'];
            
            [ meanTimeSeries.(maskName) ] = extractTimeSeriesFromMaskCIFTI(masks.(maskName), cleanedTimeSeriesMatrix, 'whichCentralTendency', 'median', 'meanCenter', false);
            savePath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID);
            if ~exist(savePath, 'dir')
                mkdir(savePath);
            end
            save(fullfile(savePath, [runName '_timeSeriesCIFTI']), 'meanTimeSeries', '-v7.3');
            
        end
        
    end
    
end
% extract time series from all of v1
[ meanTimeSeries.V1Combined ] = extractTimeSeriesFromMaskCIFTI(masks.V1Combined, cleanedTimeSeriesMatrix, 'whichCentralTendency', 'median');





%% Correlate time series from different ROIs
desiredOrder = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
savePath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'correlationMatrices', subjectID);

saveName = fullfile(savePath, [subjectID, '_', runName, '_preEye']);

[ combinedCorrelationMatrix, acrossHemisphereCorrelationMatrix] = makeCorrelationMatrix(meanTimeSeries, 'desiredOrder', desiredOrder, 'saveName', saveName);
if ~exist(savePath, 'dir')
    mkdir(savePath);
end
save(fullfile(savePath, [runName, '_CIFTI']), 'combinedCorrelationMatrix', 'acrossHemisphereCorrelationMatrix', '-v7.3');

%% Remove eye signals from BOLD data
% make pupil regressors

[covariates] = makeEyeSignalCovariates(subjectID, runName);
covariatesToAnalyze = p.Results.covariatesToAnalyze;

% assemble regressors
regressors = [];

% if we're dealing with more than one eye signal, loop over each
multipleRegressorLabels = strsplit(covariatesToAnalyze{1}, '+');
for rr = 1:length(multipleRegressorLabels)
    regressors = [regressors;  covariates.([multipleRegressorLabels{rr}, 'Convolved']); covariates.(['firstDerivative', upper(multipleRegressorLabels{rr}(1)), multipleRegressorLabels{rr}(2:end), 'Convolved'])];
end

for area = 1:length(areasList)
    
    for aa = 1:length(anglesList)
        
        for side = 1:length(laterality)
            
            if isequal(anglesList{aa}, [0 90])
                dorsalOrVentral = 'v';
            elseif isequal(anglesList{aa}, [90 180])
                dorsalOrVentral = 'd';
            end
            
            
            
            maskName = ['V', num2str(areasList{area}), dorsalOrVentral, '_', laterality{side}, '_mask'];
            
            [ pupilFreeMeanTimeSeries.(maskName) ] = cleanTimeSeries( meanTimeSeries.(maskName), regressors', covariates.timebase);
            save(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID, [runName '_timeSeries_eyeSignalsRemoved_CIFTI']), 'pupilFreeMeanTimeSeries', '-v7.3');
            
            
            
        end
        
    end
    
end

[ pupilFreeMeanTimeSeries.V1Combined ] = cleanTimeSeries( meanTimeSeries.V1Combined, regressors', covariates.timebase);


%% Re-examine correlation of time series from different ROIs
saveName = fullfile(savePath, [subjectID, '_', runName, '_postEye']);
[ combinedCorrelationMatrix_postEye, acrossHemisphereCorrelationMatrix_postEye] = makeCorrelationMatrix(pupilFreeMeanTimeSeries, 'desiredOrder', desiredOrder, 'saveName', saveName);
save(fullfile(savePath, [runName, '_postEye_CIFTI']), 'combinedCorrelationMatrix_postEye', 'acrossHemisphereCorrelationMatrix_postEye', '-v7.3');
end