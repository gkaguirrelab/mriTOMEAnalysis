subjectID = 'TOME_3003';
runName = 'rfMRI_REST_AP_Run3';
functionalScan = MRIread('/Users/harrisonmcadams/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3003/tfMRI_FLASH_PA_run2_native.nii.gz');
load('/Users/harrisonmcadams/Dropbox (Aguirre-Brainard Lab)/MELA_analysis/mriTOMEAnalysis/wholeBrain/resting/TOME_3003/rfMRI_REST_AP_Run1_voxelTimeSeries.mat')


savePath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID);
if ~exist(savePath,'dir')
    mkdir(savePath);
end
save(fullfile(savePath, [runName, '_voxelTimeSeries']), 'rawTimeSeriesPerVoxel', 'voxelIndices', '-v7.3');
%% Clean time series from physio regressors




%% Remove eye signals from BOLD data
[ covariates ] = makeEyeSignalCovariates(subjectID, runName);

% pupil diameter
regressors = [covariates.pupilDiameterConvolved; covariates.firstDerivativePupilDiameterConvolved];    
[ ~, stats_pupilDiameter ] = cleanTimeSeries( rawTimeSeriesPerVoxel, regressors', covariates.pupilTimebase, 'meanCenterRegressors', true);
[ pupilDiameter_beta ] = makeWholeBrainMap(stats_pupilDiameter.beta, voxelIndices, functionalScan);
MRIwrite(pupilDiameter_beta, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_pupilDiameter_beta.nii.gz']));
[ pupilDiameter_pearsonR ] = makeWholeBrainMap(stats_pupilDiameter.pearsonR', voxelIndices, functionalScan);
MRIwrite(pupilDiameter_pearsonR, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName, '_pupilDiameter_pearsonR.nii.gz']));
