function analyzeFlash(subjectID, runName)
%% Get the data and organize it

%% Register functional scan to anatomical scan

[ functionalScan ] = registerFunctionalToAnatomical(subjectID, runName);

%% Make our masks
% and resample them to the EPI resolution

angles = MRIread('/Users/harrisonmcadams/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3003/TOME_3003_native.template_angle.nii.gz');
eccen = MRIread('/Users/harrisonmcadams/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3003/TOME_3003_native.template_eccen.nii.gz');
areas = MRIread('/Users/harrisonmcadams/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3003/TOME_3003_native.template_areas.nii.gz');
rightHemisphere = MRIread('/Users/harrisonmcadams/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3003/TOME_3003_rh.ribbon.nii.gz');
leftHemisphere = MRIread('/Users/harrisonmcadams/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3003/TOME_3003_lh.ribbon.nii.gz');

targetFile = '/Users/harrisonmcadams/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3003/tfMRI_FLASH_PA_run2_native.nii.gz';

savePath = '/Users/harrisonmcadams/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3003/';
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
            saveName = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID, [maskName '_timeSeries']);

            [ meanTimeSeries.(maskName) ] = extractTimeSeriesFromMask( functionalScan, masks.(maskName), 'whichCentralTendency', 'median', 'saveName', saveName);


            
        end
        
    end

end


%% Clean time series from physio regressors

physioRegressors = load('/Users/harrisonmcadams/Dropbox (Aguirre-Brainard Lab)/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3003/tfMRI_FLASH_PA_run2_puls.mat');
physioRegressors = physioRegressors.output;

regressors = physioRegressors.all;

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
            
            [ cleanedMeanTimeSeries.(maskName) ] = cleanTimeSeries( meanTimeSeries.(maskName), regressors);
            
            
            
        end
        
    end
    
end


[ cleanedMeanTimeSeries.V1d_rh_mask ] = cleanTimeSeries( meanTimeSeries.V1d_rh_mask, regressors);

%% Correlate time series from different ROIs
desiredOrder = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
makeCorrelationMatrix(cleanedMeanTimeSeries, 'desiredOrder', desiredOrder);

%% Remove eye signals from BOLD data
[] = cleanTimeSeries


%% Re-examine correlation of time series from different ROIs

%% analyze that time series via IAMP

runIAMPForFlash(subjectID, v1TimeSeriesCollapsed_meanCentered, voxelIndices, combinedV1Mask, functionalScan, 'runName', runName);
end