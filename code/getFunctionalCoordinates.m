function [ functionalCoordinates ] = getFunctionalCoordinates( anatomicalCoordinates, subjectID, varargin )

p = inputParser; p.KeepUnmatched = true;
p.addParameter('visualizeAlignment',false, @islogical);
p.addParameter('freeSurferDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID, '/freeSurfer'),  @isstring);
p.addParameter('anatDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);
p.addParameter('functionalDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID),  @isstring);
p.addParameter('outputDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);
p.addParameter('runName','rfMRI_REST_AP_Run1', @ischar);


p.parse(varargin{:});


% make a mask of the voxel in question in anatomical space
anatomicalScan = MRIread(fullfile(p.Results.anatDir, 'T1w_acpc_dc_restore.nii.gz'));
blankAnatomicalScan = anatomicalScan;
blankAnatomicalScan.vol = zeros(size(anatomicalScan.vol));
blankAnatomicalScan.vol(anatomicalCoordinates(2), anatomicalCoordinates(1), anatomicalCoordinates(3)) = 1;
% blankAnatomicalScan.vol(anatomicalCoordinates(2)+1, anatomicalCoordinates(1), anatomicalCoordinates(3)) = 1;
% blankAnatomicalScan.vol(anatomicalCoordinates(2)-1, anatomicalCoordinates(1), anatomicalCoordinates(3)) = 1;
% blankAnatomicalScan.vol(anatomicalCoordinates(2), anatomicalCoordinates(1)+1, anatomicalCoordinates(3)) = 1;
% blankAnatomicalScan.vol(anatomicalCoordinates(2), anatomicalCoordinates(1)-1, anatomicalCoordinates(3)) = 1;
% blankAnatomicalScan.vol(anatomicalCoordinates(2), anatomicalCoordinates(1), anatomicalCoordinates(3)+1) = 1;
% blankAnatomicalScan.vol(anatomicalCoordinates(2), anatomicalCoordinates(1), anatomicalCoordinates(3)-1) = 1;
blankAnatomicalScan.vol(anatomicalCoordinates(2)-2:anatomicalCoordinates(2)+2, anatomicalCoordinates(1)-2:anatomicalCoordinates(1)+2, anatomicalCoordinates(3)-2:anatomicalCoordinates(3)+2) = 1;




blankAnatomicalScan.fspec = fullfile(p.Results.anatDir, 'eyeMask_anatomical.nii.gz');
MRIwrite(blankAnatomicalScan, fullfile(p.Results.anatDir, 'eyeMask_anatomical.nii.gz'));

targetFile = '/Users/harrisonmcadams/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3003/tfMRI_FLASH_PA_run2_native.nii.gz';

[ resampledEyeMask ] = resample(fullfile(p.Results.anatDir, 'eyeMask_anatomical.nii.gz'), targetFile, fullfile(p.Results.anatDir, 'eyeMask_functional.nii.gz'));

end
