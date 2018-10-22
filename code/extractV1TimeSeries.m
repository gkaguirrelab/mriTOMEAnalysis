function [ meanV1TimeSeries] = extractV1TimeSeries(subjectID, varargin)
p = inputParser; p.KeepUnmatched = true;
p.addParameter('visualizeAlignment',false, @islogical);
p.parse(varargin{:});

%% Get the subject's data
freeSurferDir = '~/Downloads/TOME_3003/T1w';
anatDir = '~/Downloads/TOME_3003/T1w';
functionalDir = '~/Downloads/TOME_3003_flash/tfMRI_FLASH_PA_run2';
outputDir = '~/Desktop';
runName = 'tfMRI_FLASH_PA_run2';



%% Run FreeSurfer bit
system(['bash makeV1Mask.sh ', subjectID, ' ', anatDir, ' ', freeSurferDir, ' ', functionalDir, ' ', outputDir, ' ', runName]);

%% Verify alignment
if p.Results.visualizeAlignment
    system(['export FREESURFER_HOME=/Applications/freesurfer; source $FREESURFER_HOME/SetUpFreeSurfer.sh; freeview -v ' anatDir, '/T1w1_gdc.nii.gz ', functionalDir, '/rfMRI_REST_AP_Run1_gdc.nii.gz ', outputDir, '/', subjectID, '_lh_v1_register_restAsTarg_identity_nearest.nii.gz'])
end

%% MATLAB stuffs
% after we've made the V1 mask, lets start figuring out the timeseries 
lhV1Mask = MRIread(fullfile(outputDir, [subjectID '_' runName '_lh_v1_registeredToFunctional.nii.gz']));
rhV1Mask = MRIread(fullfile(outputDir, [subjectID '_' runName '_rh_v1_registeredToFunctional.nii.gz']));

combinedV1Mask.vol = rhV1Mask.vol + lhV1Mask.vol;
MRIwrite(combinedV1Mask, fullfile(outputDir, [subjectID '_' runName '_bothHemispheres_v1_registeredToFunctional.nii.gz']));

restScan = MRIread(fullfile(functionalDir, [runName, '_gdc.nii.gz']));
v1TimeSeries = combinedV1Mask.vol.*restScan.vol; % still contains voxels with 0s

% convert 4D matrix to 2D matrix, where each row is a separate time series
% corresponding to a different voxel in the mask

% dimensions of our functional data
nXIndices = size(v1TimeSeries, 1);
nYIndices = size(v1TimeSeries, 2);
nZIndices = size(v1TimeSeries, 3);
nTRs = size(v1TimeSeries, 4);

% variable to pool voxels that have not been masked out
v1TimeSeriesCollapsed = [];
nNonZeroVoxel = 1;

for xx = 1:nXIndices
    for yy = 1:nYIndices
        for zz = 1:nZIndices
            if ~isempty(find([v1TimeSeries(xx,yy,zz,:)] ~= 0))
                for tr = 1:nTRs
                    % stash voxels that hvae not been masked out
                    v1TimeSeriesCollapsed(nNonZeroVoxel, tr) = v1TimeSeries(xx,yy,zz,tr);
                end
                nNonZeroVoxel = nNonZeroVoxel + 1;
            end
        end
    end
end

% take the mean
meanV1TimeSeries = mean(v1TimeSeriesCollapsed,1);

% load in pupil data
load('~/Dropbox (Aguirre-Brainard Lab)/MELA_analysis/restingTOMEAnalysis/rfMRI_REST_AP_run01_pupil.mat')

                

%% stuff that didn't work
% keeping it around in case there are useful notes

% % setup subject dir for FreeSurfer
% export SUBJECTS_DIR=~/Downloads/TOME_3003/T1w
% 
% % figure out the transformation matrix from free surfer space to HCP space
% bbregister --s TOME_3003 --mov ~/Downloads/TOME_3003/T1w/T1w1_gdc_LIA.nii.gz --reg ~/Desktop/register_LIA.dat --t1 --init-fsl
% 
% % FreeSurfer output is in LIA format, so convert HCP to that
% mri_convert --in_orientation LIA ~/Downloads/TOME_3003_functional/rfMRI_REST_AP_Run1/rfMRI_REST_AP_Run1_gdc.nii.gz ~/Downloads/TOME_3003_functional/rfMRI_REST_AP_Run1/rfMRI_REST_AP_Run1_gdc_LIA.nii.gz
% 
% % use this transfomation to  transform the mask of V1 in freeSurfer space
% % to HCP space
% mri_label2vol --label ~/Downloads/TOME_3003/T1w/TOME_3003/label/lh.V1.label --temp ~/Downloads/TOME_3003_functional/rfMRI_REST_AP_Run1/rfMRI_REST_AP_Run1_gdc_LIA.nii.gz --o ~/Desktop/lhv1mask_withRegistration_LIA.nii.gz --reg ~/Desktop/register_LIA.dat
% 
% %mri_convert -ns 1 -rl ~/Downloads/TOME_3003_functional/rfMRI_REST_AP_Run1/rfMRI_REST_AP_Run1_gdc.nii.gz ~/Desktop/lh_v1mask.nii.gz ~/Desktop/lh_v1mask_rl.nii.gz
% 
% 
% 
% % different approach
% % figure out the transformation matrix from free surfer space to HCP space
% bbregister --s TOME_3003 --mov ~/Downloads/TOME_3003/T1w/T1w1_gdc.nii.gz --reg ~/Desktop/register.dat --t1 --init-fsl
% 
% mri_label2vol --label ~/Downloads/TOME_3003/T1w/TOME_3003/label/lh.V1.label --temp ~/Downloads/TOME_3003/T1w/TOME_3003/mri/orig.mgz --o ~/Desktop/lhv1mask_FS.nii.gz --identity
% 
% mri_vol2vol --mov ~/Desktop/lhv1mask_FS.nii.gz --targ ~/Downloads/TOME_3003/T1w/T1w1_gdc.nii.gz --reg ~/Desktop/register.dat --o ~/Desktop/lhv1mask_inSubjectSpace.nii.gz --inv
% mri_vol2vol  --reg ~/Desktop/register.dat --mov ~/Desktop/lhv1mask_FS.nii.gz --o ~/Desktop/lhv1mask_inSubjectSpace.nii.gz --inv

% attempt at downsampling
% mri_convert -vs 2 2 2 ~/Desktop/lh_v1_register.nii.gz ~/Desktop/lh_v1_register_downsampled.nii.gz
% unforunately, this gives us a mask that doesn't match the dimensinos of
% the functional scan -- this is not a good attempt

end

