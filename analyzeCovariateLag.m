function [ covariateLag ] = analyzeCovariateLag(subjectID, runName, varargin)
%{

subjectID = 'TOME_3003';
runName = 'rfMRI_REST_AP_Run1';

[ covariateLag ] = analyzeCovariateLag(subjectID, runName);


%}

%% Input parser
p = inputParser; p.KeepUnmatched = true;

p.addParameter('covariateType', 'pupilDiameterConvolved', @ischar);
p.addParameter('lagRange', -2:0.1:2, @isnum);
p.addParameter('workbenchPath', '/Applications/workbench/bin_macosx64/', @ischar);


p.parse(varargin{:});

%% Load up the pupil data
[ covariates ] = makeEyeSignalCovariates(subjectID, runName);

pupilDiameterConvolved = covariates.pupilDiameterConvolved;
timebase = covariates.timebase;


%% Load up the mean BOLD time series for V1
% make V1 ROIs for left and right hemisphere




end