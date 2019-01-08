function [whiteMatterMask, ventriclesMask] = makeMaskOfWhiteMatterAndVentricles(aparcAsegFile, functionalFile)


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