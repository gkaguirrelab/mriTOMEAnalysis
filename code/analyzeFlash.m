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

eccenRange = [0 20];

% v1 regions
areaNum = 1;
anglesRange = [0 90]; % ventral
laterality = 'rh';
saveName = ['V', num2str(areaNum), '_eccen', num2str(eccenRange(1)), '-', num2str(eccenRange(2)), '_angles', num2str(anglesRange(1)), '-', num2str(anglesRange(2)), '_', laterality];
makeMaskFromRetino(eccen, areas, angles, areaNum, eccenRange, anglesRange, savePath, 'laterality', rightHemisphere, 'saveName', [saveName, '.nii.gz']);
[ V1v_rh_mask ] = resample(fullfile(savePath, [saveName, '.nii.gz']), targetFile, fullfile(savePath, [saveName, '_downsampled.nii.gz']));

areaNum = 1;
anglesRange = [0 90]; % ventral
laterality = 'lh';
saveName = ['V', num2str(areaNum), '_eccen', num2str(eccenRange(1)), '-', num2str(eccenRange(2)), '_angles', num2str(anglesRange(1)), '-', num2str(anglesRange(2)), '_', laterality];
makeMaskFromRetino(eccen, areas, angles, areaNum, eccenRange, anglesRange, savePath, 'laterality', leftHemisphere, 'saveName', [saveName, '.nii.gz']);
[ V1v_lh_mask ] = resample(fullfile(savePath, [saveName, '.nii.gz']), targetFile, fullfile(savePath, [saveName, '_downsampled.nii.gz']));


areaNum = 1;
anglesRange = [90 180]; % dorsal
laterality = 'rh';
saveName = ['V', num2str(areaNum), '_eccen', num2str(eccenRange(1)), '-', num2str(eccenRange(2)), '_angles', num2str(anglesRange(1)), '-', num2str(anglesRange(2)), '_', laterality];
makeMaskFromRetino(eccen, areas, angles, areaNum, eccenRange, anglesRange, savePath, 'laterality', rightHemisphere, 'saveName', [saveName, '.nii.gz']);
[ V1d_rh_mask ] = resample(fullfile(savePath, [saveName, '.nii.gz']), targetFile, fullfile(savePath, [saveName, '_downsampled.nii.gz']));


areaNum = 1;
anglesRange = [90 180]; % dorsal
laterality = 'lh';
saveName = ['V', num2str(areaNum), '_eccen', num2str(eccenRange(1)), '-', num2str(eccenRange(2)), '_angles', num2str(anglesRange(1)), '-', num2str(anglesRange(2)), '_', laterality];
makeMaskFromRetino(eccen, areas, angles, areaNum, eccenRange, anglesRange, savePath, 'laterality', leftHemisphere, 'saveName', [saveName, '.nii.gz']);
[ V1d_lh_mask ] = resample(fullfile(savePath, [saveName, '.nii.gz']), targetFile, fullfile(savePath, [saveName, '_downsampled.nii.gz']));

% v2 regions
areaNum = 2;
anglesRange = [0 90]; % ventral
laterality = 'rh';
saveName = ['V', num2str(areaNum), '_eccen', num2str(eccenRange(1)), '-', num2str(eccenRange(2)), '_angles', num2str(anglesRange(1)), '-', num2str(anglesRange(2)), '_', laterality];
makeMaskFromRetino(eccen, areas, angles, areaNum, eccenRange, anglesRange, savePath, 'laterality', rightHemisphere, 'saveName', [saveName, '.nii.gz']);
[ V2v_rh_mask ] = resample(fullfile(savePath, [saveName, '.nii.gz']), targetFile, fullfile(savePath, [saveName, '_downsampled.nii.gz']));

areaNum = 2;
anglesRange = [0 90]; % ventral
laterality = 'lh';
saveName = ['V', num2str(areaNum), '_eccen', num2str(eccenRange(1)), '-', num2str(eccenRange(2)), '_angles', num2str(anglesRange(1)), '-', num2str(anglesRange(2)), '_', laterality];
makeMaskFromRetino(eccen, areas, angles, areaNum, eccenRange, anglesRange, savePath, 'laterality', leftHemisphere, 'saveName', [saveName, '.nii.gz']);
[ V2v_lh_mask ] = resample(fullfile(savePath, [saveName, '.nii.gz']), targetFile, fullfile(savePath, [saveName, '_downsampled.nii.gz']));

areaNum = 2;
anglesRange = [90 180]; % dorsal
laterality = 'rh';
saveName = ['V', num2str(areaNum), '_eccen', num2str(eccenRange(1)), '-', num2str(eccenRange(2)), '_angles', num2str(anglesRange(1)), '-', num2str(anglesRange(2)), '_', laterality];
makeMaskFromRetino(eccen, areas, angles, areaNum, eccenRange, anglesRange, savePath, 'laterality', rightHemisphere, 'saveName', [saveName, '.nii.gz']);
[ V2d_rh_mask ] = resample(fullfile(savePath, [saveName, '.nii.gz']), targetFile, fullfile(savePath, [saveName, '_downsampled.nii.gz']));

areaNum = 2;
anglesRange = [90 180]; % dorsal
laterality = 'lh';
saveName = ['V', num2str(areaNum), '_eccen', num2str(eccenRange(1)), '-', num2str(eccenRange(2)), '_angles', num2str(anglesRange(1)), '-', num2str(anglesRange(2)), '_', laterality];
makeMaskFromRetino(eccen, areas, angles, areaNum, eccenRange, anglesRange, savePath, 'laterality', leftHemisphere, 'saveName', [saveName, '.nii.gz']);
[ V2d_lh_mask ] = resample(fullfile(savePath, [saveName, '.nii.gz']), targetFile, fullfile(savePath, [saveName, '_downsampled.nii.gz']));

% v3 regions
areaNum = 3;
anglesRange = [0 90]; % ventral
laterality = 'rh';
saveName = ['V', num2str(areaNum), '_eccen', num2str(eccenRange(1)), '-', num2str(eccenRange(2)), '_angles', num2str(anglesRange(1)), '-', num2str(anglesRange(2)), '_', laterality];
makeMaskFromRetino(eccen, areas, angles, areaNum, eccenRange, anglesRange, savePath, 'laterality', rightHemisphere, 'saveName', [saveName, '.nii.gz']);
[ V3v_rh_mask ] = resample(fullfile(savePath, [saveName, '.nii.gz']), targetFile, fullfile(savePath, [saveName, '_downsampled.nii.gz']));

areaNum = 3;
anglesRange = [0 90]; % ventral
laterality = 'lh';
saveName = ['V', num2str(areaNum), '_eccen', num2str(eccenRange(1)), '-', num2str(eccenRange(2)), '_angles', num2str(anglesRange(1)), '-', num2str(anglesRange(2)), '_', laterality];
makeMaskFromRetino(eccen, areas, angles, areaNum, eccenRange, anglesRange, savePath, 'laterality', leftHemisphere, 'saveName', [saveName, '.nii.gz']);
[ V3v_lh_mask ] = resample(fullfile(savePath, [saveName, '.nii.gz']), targetFile, fullfile(savePath, [saveName, '_downsampled.nii.gz']));

areaNum = 3;
anglesRange = [90 180]; % dorsal
laterality = 'rh';
saveName = ['V', num2str(areaNum), '_eccen', num2str(eccenRange(1)), '-', num2str(eccenRange(2)), '_angles', num2str(anglesRange(1)), '-', num2str(anglesRange(2)), '_', laterality];
makeMaskFromRetino(eccen, areas, angles, areaNum, eccenRange, anglesRange, savePath, 'laterality', rightHemisphere, 'saveName', [saveName, '.nii.gz']);
[ V3d_rh_mask ] = resample(fullfile(savePath, [saveName, '.nii.gz']), targetFile, fullfile(savePath, [saveName, '_downsampled.nii.gz']));

areaNum = 3;
anglesRange = [90 180]; % dorsal
laterality = 'lh';
saveName = ['V', num2str(areaNum), '_eccen', num2str(eccenRange(1)), '-', num2str(eccenRange(2)), '_angles', num2str(anglesRange(1)), '-', num2str(anglesRange(2)), '_', laterality];
makeMaskFromRetino(eccen, areas, angles, areaNum, eccenRange, anglesRange, savePath, 'laterality', leftHemisphere, 'saveName', [saveName, '.nii.gz']);
[ V3d_lh_mask ] = resample(fullfile(savePath, [saveName, '.nii.gz']), targetFile, fullfile(savePath, [saveName, '_downsampled.nii.gz']));

%% extract the time series from the mask
maskList = {'V1d_lh_mask', 'V1d_rh_mask', 'V1v_lh_mask', 'V1v_rh_mask', 'V2d_lh_mask', 'V2d_rh_mask', 'V2v_lh_mask', 'V2v_rh_mask', 'V3d_lh_mask', 'V3d_rh_mask', 'V3v_lh_mask', 'V3v_rh_mask'};

savePath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID);

[ meanTimeSeries.V1d_rh_mask ] = extractTimeSeriesFromMask( functionalScan, V1d_rh_mask, 'whichCentralTendency', 'median', 'savePath', savePath);
[ meanTimeSeries.V1d_lh_mask ] = extractTimeSeriesFromMask( functionalScan, V1d_lh_mask, 'whichCentralTendency', 'median', 'savePath', savePath);
[ meanTimeSeries.V1v_rh_mask ] = extractTimeSeriesFromMask( functionalScan, V1v_rh_mask, 'whichCentralTendency', 'median', 'savePath', savePath);
[ meanTimeSeries.V1v_lh_mask ] = extractTimeSeriesFromMask( functionalScan, V1v_lh_mask, 'whichCentralTendency', 'median', 'savePath', savePath);

[ meanTimeSeries.V2d_rh_mask ] = extractTimeSeriesFromMask( functionalScan, V2d_rh_mask, 'whichCentralTendency', 'median', 'savePath', savePath);
[ meanTimeSeries.V2d_lh_mask ] = extractTimeSeriesFromMask( functionalScan, V2d_lh_mask, 'whichCentralTendency', 'median', 'savePath', savePath);
[ meanTimeSeries.V2v_rh_mask ] = extractTimeSeriesFromMask( functionalScan, V2v_rh_mask, 'whichCentralTendency', 'median', 'savePath', savePath);
[ meanTimeSeries.V2v_lh_mask ] = extractTimeSeriesFromMask( functionalScan, V2v_lh_mask, 'whichCentralTendency', 'median', 'savePath', savePath);

[ meanTimeSeries.V3d_rh_mask ] = extractTimeSeriesFromMask( functionalScan, V3d_rh_mask, 'whichCentralTendency', 'median', 'savePath', savePath);
[ meanTimeSeries.V3d_lh_mask ] = extractTimeSeriesFromMask( functionalScan, V3d_lh_mask, 'whichCentralTendency', 'median', 'savePath', savePath);
[ meanTimeSeries.V3v_rh_mask ] = extractTimeSeriesFromMask( functionalScan, V3v_rh_mask, 'whichCentralTendency', 'median', 'savePath', savePath);
[ meanTimeSeries.V3v_lh_mask ] = extractTimeSeriesFromMask( functionalScan, V3v_lh_mask, 'whichCentralTendency', 'median', 'savePath', savePath);
%% Extract V1 time series

[ meanV1TimeSeries, v1TimeSeriesCollapsed_meanCentered, voxelIndices, combinedV1Mask, functionalScan ] = extractV1TimeSeries(subjectID, 'runName', runName);

%% Clean time series from physio regressors
[] = cleanTimeSeries

%% Correlate time series from different ROIs

%% Remove eye signals from BOLD data
[] = cleanTimeSeries


%% Re-examine correlation of time series from different ROIs

%% analyze that time series via IAMP

runIAMPForFlash(subjectID, v1TimeSeriesCollapsed_meanCentered, voxelIndices, combinedV1Mask, functionalScan, 'runName', runName);
end