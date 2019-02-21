function analyzeRest(subjectID, runName, varargin)

p = inputParser; p.KeepUnmatched = true;
p.addParameter('visualizeAlignment',false, @islogical);
p.parse(varargin{:});

%% Define paths
[ paths ] = definePaths(subjectID);

freeSurferDir = paths.freeSurferDir;
anatDir = paths.anatDir;
pupilDir = paths.pupilDir;
functionalDir = paths.functionalDir;
outputDir = paths.outputDir;

%% Get the data and organize it

getSubjectData(subjectID, runName, 'downloadOnly', 'pupil');

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
            
            if strcmp(laterality{side}, 'lh')
                hemisphere = leftHemisphere;
            elseif strcmp(laterality{side}, 'rh')
                hemisphere = rightHemisphere;
            end
            
            maskName = ['V', num2str(areasList{area}), dorsalOrVentral, '_', laterality{side}, '_mask'];
            makeMaskFromRetinoCIFTI(areasList{area}, eccenRange, anglesList{aa}, laterality{side}, 'saveName', fullfile(savePath,[maskName, '.dscalar.nii']));
            
            
            
        end
        
    end
    
end

makeMaskFromRetino(1, eccenRange, [0 180], 'saveName', fullfile(savePath,'V1Combined.nii.gz'));


%% extract the time series from the mask
for area = 1:length(areasList)
    
    for aa = 1:length(anglesList)
        
        for side = 1:length(laterality)
            
            if isequal(anglesList{aa}, [0 90])
                dorsalOrVentral = 'v';
            elseif isequal(anglesList{aa}, [90 180])
                dorsalOrVentral = 'd';
            end
            
            if strcmp(laterality{side}, 'lh')
                hemisphere = leftHemisphere;
            elseif strcmp(laterality{side}, 'rh')
                hemisphere = rightHemisphere;
            end
            
            
            maskName = ['V', num2str(areasList{area}), dorsalOrVentral, '_', laterality{side}, '_mask'];
            
            [ meanTimeSeries.(maskName) ] = extractTimeSeriesFromMask( functionalScan, masks.(maskName), 'whichCentralTendency', 'median');
            savePath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID);
            if ~exist(savePath, 'dir')
                mkdir(savePath);
            end
            save(fullfile(savePath, [runName '_timeSeries']), 'meanTimeSeries', '-v7.3');
            
        end
        
    end
    
end
% extract time series from all of v1
[ meanTimeSeries.V1Combined ] = extractTimeSeriesFromMask( functionalScan, masks.V1Combined, 'whichCentralTendency', 'median');

% extract time series from white matter and ventricles to be used as
% nuisance regressors
[ meanTimeSeries.whiteMatter ] = extractTimeSeriesFromMask( functionalScan, whiteMatterMask, 'whichCentralTendency', 'median');
[ meanTimeSeries.ventricles ] = extractTimeSeriesFromMask( functionalScan, ventriclesMask, 'whichCentralTendency', 'median');
save(fullfile(savePath, [runName '_timeSeries']), 'meanTimeSeries', '-v7.3');


%% Clean time series from physio regressors

physioRegressors = load(fullfile(functionalDir, [runName, '_puls.mat']));
physioRegressors = physioRegressors.output;
motionTable = readtable((fullfile(functionalDir, [runName, '_Movement_Regressors.txt'])));
motionRegressors = table2array(motionTable(:,7:12));
regressors = [physioRegressors.all, motionRegressors];

% mean center these motion and physio regressors
for rr = 1:size(regressors,2)
    regressor = regressors(:,rr);
    regressor = regressor - nanmean(regressor);
    regressor = regressor ./ nanstd(regressor);
    regressors(:,rr) = regressor;
end

% also add the white matter and ventricular time series
regressors(:,end+1) = meanTimeSeries.whiteMatter;
regressors(:,end+1) = meanTimeSeries.ventricles;

TR = functionalScan.tr; % in ms
nFrames = functionalScan.nframes;

regressorTimebase = 0:TR:nFrames*TR-TR;

% remove all regressors that are all 0
emptyColumns = [];
for column = 1:size(regressors,2)
    if ~any(regressors(:,column))
        emptyColumns = [emptyColumns, column];
    end
end
regressors(:,emptyColumns) = [];

for area = 1:length(areasList)
    
    for aa = 1:length(anglesList)
        
        for side = 1:length(laterality)
            
            if isequal(anglesList{aa}, [0 90])
                dorsalOrVentral = 'v';
            elseif isequal(anglesList{aa}, [90 180])
                dorsalOrVentral = 'd';
            end
            
            if strcmp(laterality{side}, 'lh')
                %hemisphere = leftHemisphere;
            elseif strcmp(laterality{side}, 'rh')
                %hemisphere = rightHemisphere;
            end
            
            maskName = ['V', num2str(areasList{area}), dorsalOrVentral, '_', laterality{side}, '_mask'];
            
            
            [ cleanedMeanTimeSeries.(maskName) ] = cleanTimeSeries( meanTimeSeries.(maskName), regressors, regressorTimebase, 'meanCenterRegressors', false);
            save(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID, [runName '_timeSeries_physioMotionWMVCorrected']), 'cleanedMeanTimeSeries', '-v7.3');
            
            
            
        end
        
    end
    
end

[ cleanedMeanTimeSeries.V1Combined ] = cleanTimeSeries( meanTimeSeries.V1Combined, regressors, regressorTimebase);
save(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID, [runName '_timeSeries_physioMotionWMVCorrected']), 'cleanedMeanTimeSeries', '-v7.3');



%% Correlate time series from different ROIs
desiredOrder = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
[ combinedCorrelationMatrix, acrossHemisphereCorrelationMatrix] = makeCorrelationMatrix(cleanedMeanTimeSeries, 'desiredOrder', desiredOrder);
savePath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'correlationMatrices', subjectID);
if ~exist(savePath, 'dir')
    mkdir(savePath);
end
save(fullfile(savePath, runName), 'combinedCorrelationMatrix', 'acrossHemisphereCorrelationMatrix', '-v7.3');

%% Remove eye signals from BOLD data
% make pupil regressors

pupilResponse = load(fullfile(pupilDir, [runName, '_pupil.mat']));
pupilArea = pupilResponse.pupilData.initial.ellipses.values(:,3);
pupilRegressors = [pupilArea];
pupilTimebase = load(fullfile(pupilDir, [runName, '_timebase.mat']));
pupilTimebase = pupilTimebase.timebase.values';

for area = 1:length(areasList)
    
    for aa = 1:length(anglesList)
        
        for side = 1:length(laterality)
            
            if isequal(anglesList{aa}, [0 90])
                dorsalOrVentral = 'v';
            elseif isequal(anglesList{aa}, [90 180])
                dorsalOrVentral = 'd';
            end
            
            
            
            maskName = ['V', num2str(areasList{area}), dorsalOrVentral, '_', laterality{side}, '_mask'];
            
            [ pupilFreeMeanTimeSeries.(maskName) ] = cleanTimeSeries( cleanedMeanTimeSeries.(maskName), pupilRegressors, pupilTimebase);
            save(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID, [runName '_timeSeries_physioMotionWMVCorrected_eyeSignalsRemoved']), 'cleanedMeanTimeSeries', '-v7.3');
            
            
            
        end
        
    end
    
end

[ pupilFreeMeanTimeSeries.V1Combined ] = cleanTimeSeries( cleanedMeanTimeSeries.V1Combined, pupilRegressors, pupilTimebase);
save(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID, [runName '_timeSeries_physioMotionWMVCorrected_eyeSignalsRemoved']), 'cleanedMeanTimeSeries', '-v7.3');


%% Re-examine correlation of time series from different ROIs
[ combinedCorrelationMatrix_postEye, acrossHemisphereCorrelationMatrix_postEye] = makeCorrelationMatrix(pupilFreeMeanTimeSeries, 'desiredOrder', desiredOrder);
save(fullfile(savePath, [runName, '_postEye']), 'combinedCorrelationMatrix_postEye', 'acrossHemisphereCorrelationMatrix_postEye', '-v7.3');
end