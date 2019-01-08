function [whiteMatterMask, ventriclesMask] = makeMaskOfWhiteMatterAndVentricles(aparcAsegFile, functionalFile)
% Make eroded white matter and ventricle masks from FreeSurfer output.
%
% Syntax:
%  [whiteMatterMask, ventriclesMask] = makeMaskOfWhiteMatterAndVentricles(aparcAsegFile, functionalFile)
%
% Description:
%  This routine first resamples the aparc_aseg file (which
%  contains the segmentation/parcellation results form FreeSurfer) to the
%  resolution of the functional data. It then identifies voxels
%  corresponding to white matter and gray matter (separately) and binarizes
%  as mask of these relevant voxels. Finally the routine erodeds these
%  masks by 1 voxel to avoid any partial volume effects.
%
%  This routine requires AFNI, unless we're just loading in the files
%  already created.
% 
% Inputs:
%  aparcAsegFile:       - a string that gives the full path to the
%                         aparcAseg file
%  functionalFile:      - a string that gives the full path to the
%                         functional volume
%
% Outputs:
%  whiteMatterMask:     - a structure that contains the binary mask in
%                         which all voxels corresponding to white matter
%                         are 1 with the rest 0. This is following the
%                         erosion process.
%  ventriclesMask:     - a structure that contains the binary mask in
%                         which all voxels corresponding to the ventricles
%                         are 1 with the rest 0. This is following the
%                         erosion process.



%% Check to see if these files already exist, so we don't have to make them again.
[ savePath ] = fileparts(aparcAsegFile);

if exist(fullfile(savePath, 'whiteMatter_eroded_resampled.nii.gz')) && exist(fullfile(savePath, 'ventricles_eroded_resampled.nii.gz'))
    
    whiteMatterMask = MRIread(fullfile(savePath, 'whiteMatter_eroded_resampled.nii.gz'));
    ventriclesMask = MRIread(fullfile(savePath, 'ventricles_eroded_resampled.nii.gz'));
    
else
    
    %% Make eroded white matter mask
    
    
    system(['~/abin/3dresample -master "' functionalFile '" -prefix "' savePath '/aparc+aseg_resampled.nii.gz"' ' -inset "' aparcAsegFile '"'])
    
    system(['~/abin/3dcalc -a "' savePath '/aparc+aseg_resampled.nii.gz"' ' -expr "equals(a,2)+equals(a,7)+equals(a,41)+equals(a,46)+equals(a,251)+equals(a,252)+equals(a,253)+equals(a,254)+equals(a,255)" -prefix "' savePath '/whiteMatter_resampled.nii.gz"']);
    
    system(['~/abin/3dcalc -a "' savePath '/whiteMatter_resampled.nii.gz" -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr "a*(1-amongst(0,b,c,d,e,f,g))" -prefix "' savePath '/whiteMatter_eroded_resampled.nii.gz"']);
    
    %% make eroded ventricule mask
    system(['~/abin/3dcalc -a "' savePath '/aparc+aseg_resampled.nii.gz" -expr "equals(a,4)+equals(a,43)" -prefix "' savePath '/ventricles_resampled.nii.gz"']);
    
    system(['~/abin/3dcalc -a "' savePath '/aparc+aseg_resampled.nii.gz" -expr "equals(a,10)+equals(a,11)+equals(a,26)+equals(a,49)+equals(a,50)+equals(a,58)" -prefix "' savePath '/nonVentricles_resampled.nii.gz"']);
    
    system(['~/abin/3dcalc -a "' savePath '/nonVentricles_resampled.nii.gz" -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr "amongst(1,a,b,c,d,e,f,g)" -prefix "' savePath '/nonVentricles_dilated_resampled.nii.gz"']);
    
    system(['~/abin/3dcalc -a "' savePath '/ventricles_resampled.nii.gz" -b "' savePath '/nonVentricles_dilated_resampled.nii.gz" -expr "a-step(a*b)" -prefix "' savePath '/ventricles_eroded_resampled.nii.gz"']);
    
    whiteMatterMask = MRIread(fullfile(savePath, 'whiteMatter_eroded_resampled.nii.gz'));
    ventriclesMask = MRIread(fullfile(savePath, 'ventricles_eroded_resampled.nii.gz'));
end


end