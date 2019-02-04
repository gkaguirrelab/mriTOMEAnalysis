function unpackICAFIX(subjectID)

downloadDir = '~/Downloads';


%% look for the relevant tars in the downloadDir
tarFiles = dir(fullfile(downloadDir, [subjectID, '*.zip']));
unzipDir = fullfile(tarFiles(1).folder,subjectID);

paths = definePaths(subjectID);

if (~exist(unzipDir,'dir'))
    mkdir(unzipDir);
end

for ii = 1:length(tarFiles)
    system(['unzip -o "', fullfile(tarFiles(ii).folder, tarFiles(ii).name), '" -d "', unzipDir, '"']);
    if contains(tarFiles(ii).name, 'hcpicafix.zip')
        analysisName = strsplit(tarFiles(ii).name, subjectID);
        analysisName = analysisName{2}(2:end);
        analysisName = analysisName(1:end-14);
        % template file
        copyfile(fullfile(unzipDir, subjectID, 'MNINonLinear/Results', analysisName, [analysisName, '_Atlas_mean.dscalar.nii']), fullfile(paths.anatDir, 'template.dscalar.nii'));
        
        runs = dir(fullfile(unzipDir, subjectID, 'MNINonLinear/Results'));
        for rr = 1:length(runs)
            if contains(runs(rr).name, 'Run') && ~strcmp(runs(rr).name, analysisName)
                copyfile(fullfile(unzipDir, subjectID, 'MNINonLinear/Results', runs(rr).name, [runs(rr).name, '_Atlas_hp2000_clean.dtseries.nii']), fullfile(paths.anatDir, [runs(rr).name, '_Atlas_hp2000_clean.dtseries.nii']));
            end
        end

        % each functional file
    end
    
    if contains(tarFiles(ii).name, 'Classification_Scene.zip')
        
        copyfile(fullfile(unzipDir, tarFiles(ii).name(1:end-4), subjectID, 'MNINonLinear/fsaverage_LR32k', [subjectID, '.R.midthickness.32k_fs_LR.surf.gii']), fullfile(paths.anatDir, 'R.midthickness.32k_fs_LR.surf.gii'));
        copyfile(fullfile(unzipDir, tarFiles(ii).name(1:end-4), subjectID, 'MNINonLinear/fsaverage_LR32k', [subjectID, '.L.midthickness.32k_fs_LR.surf.gii']), fullfile(paths.anatDir, 'L.midthickness.32k_fs_LR.surf.gii'));

    end
    delete(fullfile(fullfile(tarFiles(ii).folder, tarFiles(ii).name)));

end

rmdir(unzipDir, 's')
end