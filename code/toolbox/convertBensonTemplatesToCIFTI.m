% This routine converts the Benson retinopty templates from fsaverage space
% with 160K vertice to the FS_LR space with 32K vertices (the format used
% by HCP), as well as converts the file type to CIFTI.

% This should have been a relatively straightforward resampling (such as
% through
% https://wiki.humanconnectome.org/download/attachments/63078513/Resampling-FreeSurfer-HCP.pdf).
% However, I believe the way Noah decided to store his templates is a bit
% different than what is normally done through FreeSurfer, and consequently
% the intended commands do not work. More specifically, the templates were
% stored as .mgz files. This .mgz format is used to specify volumes, but
% Noah, I believe, had it store a surface representation.

% As part of this 7T retinotopy paper further refining his template
% approach, he makes a lot of his code and data available
% (https://osf.io/bw9ec/wiki/home/). Because part of this dataset involves
% going back and forth between fsaverage space and standard HCP grayordinate
% space, he worked out the mapping back and forth between the two spaces.
% Specifically, this mapping information is contained within
% ciftifsaverageix of prfresults.mat. Note that I just used this work for
% this mapping and did not convert the templates associated with this
% paper.

%%
% where we keep the templates
subjectID = 'benson';
paths = definePaths(subjectID);

% describe the different templates we want to produce
mapTypes = {'angle', 'eccen', 'varea'};
hemispheres  = {'lh', 'rh'};

% this file contains the ciftifsaverageix that maps fsaverage vertex number
% to grayordinate row
load(fullfile(paths.anatDir, 'indexMapping.mat'));

% grab an example scalar template
TOME3005path = definePaths('TOME_3005');
templateFile = fullfile(TOME3005.anatDir, 'template.dscalar.nii');
for map = 1:length(mapTypes)
    for hemisphere = 1:2
        
        % the FSvertices will range between 1 and 160K for both left and
        % right hemispheres. Ultimately, the grayordinate rows pertaining
        % to right hemisphere is in the same file as those for the left
        % hemisphere, they are just shifted down by a certain amount. This
        % hemisphereFactor will later account for this shift.
        if strcmp(hemispheres{hemisphere}, 'lh')
            hemisphereFactor = 1;
        elseif strcmp(hemispheres{hemisphere}, 'rh')
            hemisphereFactor = 2;
        end
        
        % load up the template of interest
        template = MRIread(fullfile(paths.anatDir, [hemispheres{hemisphere}, '.benson14_', mapTypes{map}, '.v4_0.mgz']));
        
        % pre-allocate output cell array
        for ii = 1:91282
            CIFTITemplateCellArray{ii} = [];
        end
        
        % for each vertex, look up the corresponding GIFTI row, and stash
        % the value at that vertex in the proper row.
        for ii = 1:length(template.vol)
            FSVertexNumber = ii;
            CIFTIRowNumber = ciftifsaverageix(ii+(hemisphereFactor - 1)*length(template.vol));
            CIFTITemplateCellArray{CIFTIRowNumber}(end+1) = template.vol(FSVertexNumber);
        end
        
        % more than one FreeSurfer vertex maps onto the same GIFTI row.
        % combine them by averaging.
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

