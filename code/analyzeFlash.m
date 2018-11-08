function analyzeFlash(subjectID, runName, varargin)

p = inputParser; p.KeepUnmatched = true;
p.addParameter('visualizeAlignment',false, @islogical);
p.addParameter('freeSurferDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID, '/freeSurfer'),  @isstring);
p.addParameter('anatDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);
p.addParameter('pupilDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);
p.addParameter('functionalDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID),  @isstring);
p.addParameter('outputDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);


p.parse(varargin{:});

%% Get the data and organize it

%% Register functional scan to anatomical scan

[ functionalScan ] = registerFunctionalToAnatomical(subjectID, runName);

%% Make our masks
% and resample them to the EPI resolution

angles = MRIread(fullfile(p.Results.anatDir, [subjectID, '_native.template_angle.nii.gz']));

eccen = MRIread(fullfile(p.Results.anatDir, [subjectID, '_native.template_eccen.nii.gz']));

areas = MRIread(fullfile(p.Results.anatDir, [subjectID, '_native.template_areas.nii.gz']));
rightHemisphere = MRIread(fullfile(p.Results.anatDir, [subjectID, '_rh.ribbon.nii.gz']));
leftHemisphere = MRIread(fullfile(p.Results.anatDir, [subjectID, '_lh.ribbon.nii.gz']));

targetFile = (fullfile(p.Results.functionalDir, [runName, '_native.nii.gz']));

savePath = p.Results.anatDir;
maskList = {'V1d_lh_mask', 'V1d_rh_mask', 'V1v_lh_mask', 'V1v_rh_mask', 'V2d_lh_mask', 'V2d_rh_mask', 'V2v_lh_mask', 'V2v_rh_mask', 'V3d_lh_mask', 'V3d_rh_mask', 'V3v_lh_mask', 'V3v_rh_mask'};
areasList = {1, 2, 3};
anglesList = {[0 90], [90 180]};
eccenRange = [0 20];
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
            makeMaskFromRetino(eccen, areas, angles, areasList{area}, eccenRange, anglesList{aa}, savePath, 'laterality', hemisphere, 'saveName', [maskName, '.nii.gz']);
            [ masks.(maskName) ] = resample(fullfile(savePath, [maskName, '.nii.gz']), targetFile, fullfile(savePath, [maskName, '_downsampled.nii.gz']));


            
        end
        
    end

end


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

            save(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID, [runName '_timeSeries']), 'meanTimeSeries', '-v7.3');
            
        end
        
    end

end


%% Clean time series from physio regressors

physioRegressors = load(fullfile(p.Results.functionalDir, [runName, '_puls.mat']));
physioRegressors = physioRegressors.output;
motionTable = readtable((fullfile(p.Results.functionalDir, [runName, '_Movement_Regressors.txt'])));
motionRegressors = table2array(motionTable(:,7:12));
regressors = [physioRegressors.all, motionRegressors];

TR = functionalScan.tr; % in ms
nFrames = functionalScan.nframes;

regressorTimebase = 0:TR:nFrames*TR-TR;

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
            
            
            [ cleanedMeanTimeSeries.(maskName) ] = cleanTimeSeries( meanTimeSeries.(maskName), regressors, regressorTimebase);
            save(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID, [runName '_timeSeries_physioMotionCorrected']), 'cleanedMeanTimeSeries', '-v7.3');

            
            
        end
        
    end
    
end



%% Correlate time series from different ROIs
desiredOrder = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
makeCorrelationMatrix(cleanedMeanTimeSeries, 'desiredOrder', desiredOrder);

%% Remove eye signals from BOLD data
% make pupil regressors

pupilResponse = load(fullfile(p.Results.pupilDir, [runName, '_pupil.mat']));
pupilArea = pupilResponse.pupilData.initial.ellipses.values(:,3);
pupilRegressors = [pupilArea];
pupilTimebase = load(fullfile(p.Results.pupilDir, [runName, '_timebase.mat']));
pupilTimebase = pupilTimebase.timebase.values';

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
            
            [ pupilFreeMeanTimeSeries.(maskName) ] = cleanTimeSeries( cleanedMeanTimeSeries.(maskName), pupilRegressors, pupilTimebase);
            save(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID, [runName '_timeSeries_physioMotionCorrected_eyeSignalsRemoved']), 'cleanedMeanTimeSeries', '-v7.3');

            
            
        end
        
    end
    
end

%% Re-examine correlation of time series from different ROIs
makeCorrelationMatrix(pupilFreeMeanTimeSeries, 'desiredOrder', desiredOrder);

end