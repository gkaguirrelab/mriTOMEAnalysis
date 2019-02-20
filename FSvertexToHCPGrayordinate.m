workbenchPath = '/Applications/workbench/bin_macosx64/';

% paths = definePaths(subjectID);
% templateFile = fullfile(anatDir, 'template.dscalar.nii');
% savePath = fullFile(anatDir);

% savePath = '/Users/harrisonmcadams/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/wholeBrain/TOME_3033/';
templateFile =('/Users/harrisonmcadams/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/wholeBrain/TOME_3033/rfMRI_REST_PA_Run4_pupilDiameter+pupilChange_firstDerivativePupilDiameter_beta.dscalar.nii');
% system(['bash ', workbenchPath, 'wb_command -cifti-convert -to-text ', templateFile, ' ', fullfile(savePath, 'grayordinateTemplate.txt')]);
% 
% grayordinates = readtable(fullfile(savePath, 'grayordinateTemplate.txt'));
% grayordinates = table2array(grayordinates);

% lfrom the above example, it's clear that there are 91281 grayordinatees
% in total. let's seee where #1 is
% figure out where template file lives. we'll stash temporary results
% there
template = zeros(91282, 1);
template(1:30000) = 1;
%template = 1:91282;
[ savePath ] = fileparts(templateFile);


% write out the stats to a text file
dlmwrite(fullfile(savePath, 'stats.txt'), template, 'delimiter','\t')
% make the dscalar file
system(['bash ', workbenchPath, 'wb_command -cifti-convert -from-text "', fullfile(savePath, 'stats.txt'), '" "', templateFile, '" "', fullfile(savePath, 'grayordinateTemplate.dscalar.nii'), '"']);


% source: https://wiki.humanconnectome.org/download/attachments/63078513/Resampling-FreeSurfer-HCP.pdf

%% convert visual area benson map to gifti
% specify the files
subjectID = 'benson';
paths = definePaths(subjectID);
templateSurfFile = fullfile(paths.anatDir, 'all-template-2.5.sym.mgh');
templateGIFTIFile = fullfile(paths.anatDir, 'bensonTemplate.surf.gii');

% convert files from .mgh to GIFTI
subjectID = 'standard-mesh-atlases';
paths = definePaths(subjectID);
for hemisphere = {'L', 'R'}
currentSphereFile = fullfile(paths.anatDir, 
newSphereFile = 
currentAreFile = 
newAreaFile = 
system(['export FREESURFER_HOME=/Applications/freesurfer; source $FREESURFER_HOME/SetUpFreeSurfer.sh; mri_convert "', templateSurfFile, '" "', templateGIFTIFile, '"']);

% resample the template onto the fs_LR mesh
