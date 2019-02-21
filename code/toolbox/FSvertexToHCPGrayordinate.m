%
% workbenchPath = '/Applications/workbench/bin_macosx64/';
%
% % paths = definePaths(subjectID);
% % templateFile = fullfile(anatDir, 'template.dscalar.nii');
% % savePath = fullFile(anatDir);
%
% % savePath = '/Users/harrisonmcadams/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/wholeBrain/TOME_3033/';
% templateFile =('/Users/harrisonmcadams/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/wholeBrain/TOME_3033/rfMRI_REST_PA_Run4_pupilDiameter+pupilChange_firstDerivativePupilDiameter_beta.dscalar.nii');
% % system(['bash ', workbenchPath, 'wb_command -cifti-convert -to-text ', templateFile, ' ', fullfile(savePath, 'grayordinateTemplate.txt')]);
% %
% % grayordinates = readtable(fullfile(savePath, 'grayordinateTemplate.txt'));
% % grayordinates = table2array(grayordinates);
%
% % lfrom the above example, it's clear that there are 91281 grayordinatees
% % in total. let's seee where #1 is
% % figure out where template file lives. we'll stash temporary results
% % there
% template = zeros(91282, 1);
% template(1:30000) = 1;
% %template = 1:91282;
% [ savePath ] = fileparts(templateFile);
%
%
% % write out the stats to a text file
% dlmwrite(fullfile(savePath, 'stats.txt'), template, 'delimiter','\t')
% % make the dscalar file
% system(['bash ', workbenchPath, 'wb_command -cifti-convert -from-text "', fullfile(savePath, 'stats.txt'), '" "', templateFile, '" "', fullfile(savePath, 'grayordinateTemplate.dscalar.nii'), '"']);
%
%
% % source: https://wiki.humanconnectome.org/download/attachments/63078513/Resampling-FreeSurfer-HCP.pdf
%
% %% convert visual area benson map to gifti
% % specify the files
% subjectID = 'benson';
% paths = definePaths(subjectID);
%
% mapTypes = {'angle', 'eccen', 'retinotopy', 'varea'};
% hemispheres = {'lh', 'rh'};
% %% loop around each map type
% for mm = 1:length(mapTypes)
%     for hh = 1:length(hemispheres)
%         templateSurfFile = fullfile(paths.anatDir, [hemispheres{hh}, '.benson14_', mapTypes{mm}, '.v4_0.mgz']);
%         templateGIFTIFile = fullfile(paths.anatDir, [hemispheres{hh}, '.', mapTypes{mm}, '.surf.gii']);
%         templateGIFTIExplicitFile = fullfile(paths.anatDir, [hemispheres{hh}, '.', mapTypes{mm}, '.surfGIFTI.gii']);
%
%
%         % convert to GIFTI format
%         system(['export FREESURFER_HOME=/Applications/freesurfer; source $FREESURFER_HOME/SetUpFreeSurfer.sh; mri_convert "', templateSurfFile, '" "', templateGIFTIFile, '"']);
%         system(['export FREESURFER_HOME=/Applications/freesurfer; source $FREESURFER_HOME/SetUpFreeSurfer.sh; mris_convert "', templateGIFTIFile, '" "', templateGIFTIExplicitFile, '"']);
%
%     end
% end
%
% % convert files from .mgh to GIFTI
% subjectID = 'standard-mesh-atlases';
% paths = definePaths(subjectID);
% for hemisphere = {'L', 'R'}
% system(['export FREESURFER_HOME=/Applications/freesurfer; source $FREESURFER_HOME/SetUpFreeSurfer.sh; mri_convert "', templateSurfFile, '" "', templateGIFTIFile, '"']);
%
% % resample the template onto the fs_LR mesh
%

%%
subjectID = 'benson';
paths = definePaths(subjectID);

mapTypes = {'angle', 'eccen', 'varea'};
hemispheres  = {'lh', 'rh'};
load(fullfile(paths.anatDir, 'indexMapping.mat'));
templateFile = '/Users/harrisonmcadams/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3005/template.dscalar.nii';
for map = 1:length(mapTypes)
    for hemisphere = 1:2
        
        if strcmp(hemispheres{hemisphere}, 'lh')
            hemisphereFactor = 1;
        elseif strcmp(hemispheres{hemisphere}, 'rh')
            hemisphereFactor = 2;
        end
        
        template = MRIread(fullfile(paths.anatDir, [hemispheres{hemisphere}, '.benson14_', mapTypes{map}, '.v4_0.mgz']));
        for ii = 1:91282
            CIFTITemplateCellArray{ii} = [];
        end
        
        for ii = 1:length(template.vol)
            FSVertexNumber = ii;
            CIFTIRowNumber = ciftifsaverageix(ii+(hemisphereFactor - 1)*length(template.vol));
            CIFTITemplateCellArray{CIFTIRowNumber}(end+1) = template.vol(FSVertexNumber);
        end
        
        meanCIFTITemplateVector = cellfun(@mean,CIFTITemplateCellArray);
        % all of the vertices that get mapped to row 1 of the GIFTI
        % represent vertices that have no HCP counterpart. These are set to
        % NaN
        meanCIFTITemplateVector(1) = NaN;
        
        % write out template to textfile
        dlmwrite(fullfile(paths.anatDir, 'stats.txt'), meanCIFTITemplateVector', 'delimiter', '\t')
        
        % make CIFTI from the textfile
        system(['bash ', '/Applications/workbench/bin_macosx64/', 'wb_command -cifti-convert -from-text "', fullfile(paths.anatDir, 'stats.txt'), '" "', templateFile, '" "', fullfile(paths.anatDir, [hemispheres{hemisphere}, '.benson14_', mapTypes{map}, '.dscalar.nii']), '"'])
    end
end

