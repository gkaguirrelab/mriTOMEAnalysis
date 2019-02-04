function [ covariateLag ] = analyzeCovariateLag(subjectID, runName, varargin)
%{

subjectID = 'TOME_3003';
runName = 'rfMRI_REST_AP_Run1';

[ covariateLag ] = analyzeCovariateLag(subjectID, runName);


%}

%% Input parser
p = inputParser; p.KeepUnmatched = true;

p.addParameter('covariateType', 'pupilDiameterConvolved', @ischar);
p.addParameter('lagRange', -10000:100:10000, @isnum);
p.addParameter('workbenchPath', '/Applications/workbench/bin_macosx64/', @ischar);
p.addParameter('demoLagDirectionality', false, @islogical);


p.parse(varargin{:});

%% Load up the pupil data
[ covariates ] = makeEyeSignalCovariates(subjectID, runName);

pupilDiameterConvolved = covariates.pupilDiameterConvolved;
timebase = covariates.timebase;


%% Load up the mean BOLD time series for V1

paths = definePaths(subjectID);

% make V1 ROIs for left and right hemisphere
% make left hemisphere ROI
system(['bash ', p.Results.workbenchPath, 'wb_command -gifti-label-to-roi "', fullfile(paths.anatDir, [subjectID, '.L.BA.32k_fs_LR.label.gii']), '" "', fullfile(paths.anatDir, 'LV1.shape.gii'), '" -name L_V1']);
% make right hemisphere ROI
system(['bash ', p.Results.workbenchPath, 'wb_command -gifti-label-to-roi "', fullfile(paths.anatDir, [subjectID, '.R.BA.32k_fs_LR.label.gii']), '" "', fullfile(paths.anatDir, 'RV1.shape.gii'), '" -name R_V1']);

% extract mean time series from each visual cortex ROI
system(['bash ', p.Results.workbenchPath, 'wb_command -cifti-average-dense-roi "', fullfile(paths.functionalDir, 'combinedV1MeanTimeSeries.mean.nii'), '" -left-roi "', fullfile(paths.anatDir, 'LV1.shape.gii'), '" -right-roi "', fullfile(paths.anatDir, 'RV1.shape.gii'), '" -cifti "', fullfile(paths.functionalDir, [runName, '_Atlas_hp2000_clean.dtseries.nii']), '"']);

% convert dscalar file to text file so we can read it into matlab
system(['bash ', p.Results.workbenchPath, 'wb_command -cifti-convert -to-text "', fullfile(paths.functionalDir, 'combinedV1MeanTimeSeries.mean.nii'), '" "', fullfile(paths.functionalDir, 'combinedV1MeanTimeSeries.txt'), '"']);

% load text file containing mean time series into matlab
meanV1TimeSeries = readtable(fullfile(paths.functionalDir, 'combinedV1MeanTimeSeries.txt'), 'ReadVariableNames', false);
meanV1TimeSeries = table2array(meanV1TimeSeries);

% also make some parietal ROIs. In our group average map, the inferior
% parietal lobule have a strong and positive relationship between BOLD and
% pupil data. I believe that one atlas lists angualr and supramarginal gyri
% as the regions of interest.
% left angular
system(['bash ', p.Results.workbenchPath, 'wb_command -gifti-label-to-roi "', fullfile(paths.anatDir, [subjectID, '.L.aparc.a2009s.32k_fs_LR.label.gii']), '" "', fullfile(paths.anatDir, 'L_G_pariet_inf-Angular.shape.gii'), '" -name L_G_pariet_inf-Angular']);

% right angular
system(['bash ', p.Results.workbenchPath, 'wb_command -gifti-label-to-roi "', fullfile(paths.anatDir, [subjectID, '.R.aparc.a2009s.32k_fs_LR.label.gii']), '" "', fullfile(paths.anatDir, 'R_G_pariet_inf-Angular.shape.gii'), '" -name R_G_pariet_inf-Angular']);

% left supramarginal
system(['bash ', p.Results.workbenchPath, 'wb_command -gifti-label-to-roi "', fullfile(paths.anatDir, [subjectID, '.L.aparc.a2009s.32k_fs_LR.label.gii']), '" "', fullfile(paths.anatDir, 'L_G_pariet_inf-Supramar.shape.gii'), '" -name L_G_pariet_inf-Supramar']);

% right supramarginal
system(['bash ', p.Results.workbenchPath, 'wb_command -gifti-label-to-roi "', fullfile(paths.anatDir, [subjectID, '.R.aparc.a2009s.32k_fs_LR.label.gii']), '" "', fullfile(paths.anatDir, 'R_G_pariet_inf-Supramar.shape.gii'), '" -name R_G_pariet_inf-Supramar']);

% extract mean time series from each IPL
system(['bash ', p.Results.workbenchPath, 'wb_command -cifti-average-dense-roi "', fullfile(paths.functionalDir, 'combinedIPLMeanTimeSeries.mean.nii'), '" -left-roi "', fullfile(paths.anatDir, 'L_G_pariet_inf-Supramar.shape.gii'),'" -right-roi "', fullfile(paths.anatDir, 'R_G_pariet_inf-Supramar.shape.gii'), '" -cifti "', fullfile(paths.functionalDir, [runName, '_Atlas_hp2000_clean.dtseries.nii']), '"']);

% convert dscalar file to text file so we can read it into matlab
system(['bash ', p.Results.workbenchPath, 'wb_command -cifti-convert -to-text "', fullfile(paths.functionalDir, 'combinedIPLMeanTimeSeries.mean.nii'), '" "', fullfile(paths.functionalDir, 'combinedIPLMeanTimeSeries.txt'), '"']);

% load text file containing mean time series into matlab
meanIPLTimeSeries = readtable(fullfile(paths.functionalDir, 'combinedIPLMeanTimeSeries.txt'), 'ReadVariableNames', false);
meanIPLTimeSeries = table2array(meanIPLTimeSeries);

%% Loop over different lag values
V1CorrelationValues = [];
IPLCorrelationValues = [];
for tt = p.Results.lagRange
    lag = tt;
    % resample the pupil data to the same temporal resolution as the BOLD data
    pupilStruct.timebase = timebase + lag;
    pupilStruct.values = pupilDiameterConvolved;
    
    TR = 800; % in milliseconds
    nTRs = 420;
    fMRITimebase = 0:TR:nTRs*TR-TR;
    
    temporalFit = tfeIAMP('verbosity','none');
    
    pupilStruct = temporalFit.resampleTimebase(pupilStruct, fMRITimebase, 'resampleMethod', 'resample');
    
    % examine the correlation between convolved pupil time series and fMRI
    % signal
    
    correlationMatrix = corrcoef(pupilStruct.values, meanV1TimeSeries, 'rows', 'complete');
    V1CorrelationValues(end+1) = correlationMatrix(2);
    
    correlationMatrix = corrcoef(pupilStruct.values, meanIPLTimeSeries, 'rows', 'complete');
    IPLCorrelationValues(end+1) = correlationMatrix(2);
end

% plot results
plotFig = figure;
plot(p.Results.lagRange, V1CorrelationValues);
hold on;
plot(p.Results.lagRange, IPLCorrelationValues);
legend('V1', 'IPL');

%% Demo which direction positive lag goes, if desired
if p.Results.demoLagDirectionality
    plotFig = figure;
    hold on;
    plot(timebase, pupilDiameterConvolved);
    plot(timebase+1000, pupilDiameterConvolved);
    plot(timebase-1000, pupilDiameterConvolved);
    
    legend('Original Time Series', 'Positive Lag', 'Negative Lag')
    
    
end


end