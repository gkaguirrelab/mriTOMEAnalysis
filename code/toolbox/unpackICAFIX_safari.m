function unpackICAFIX(subjectID)

downloadDir = '~/Downloads';


%% look for the relevant tars in the downloadDir
folders = dir(fullfile(downloadDir, [subjectID, '*']));
%unzipDir = fullfile(tarFiles(1).folder);

paths = definePaths(subjectID);



for ii = 1:length(folders)
%    system(['unzip -o "', fullfile(tarFiles(ii).folder, tarFiles(ii).name), '" -d "', unzipDir, '"']);
    if ~contains(folders(ii).name, 'Classification')

        analysisName = dir(fullfile(downloadDir, folders(ii).name, 'MNINonLinear/Results', 'ICA*'));
        analysisName = analysisName(1).name;
        % template file
        copyfile(fullfile(downloadDir, subjectID, 'MNINonLinear/Results', analysisName, [analysisName, '_Atlas_mean.dscalar.nii']), fullfile(paths.anatDir, 'template.dscalar.nii'));
        
        runs = dir(fullfile(downloadDir, subjectID, 'MNINonLinear/Results'));
        for rr = 1:length(runs)
            if contains(runs(rr).name, 'Run') && ~strcmp(runs(rr).name, analysisName)
                copyfile(fullfile(downloadDir, subjectID, 'MNINonLinear/Results', runs(rr).name, [runs(rr).name, '_Atlas_hp2000_clean.dtseries.nii']), fullfile(paths.anatDir, [runs(rr).name, '_Atlas_hp2000_clean.dtseries.nii']));
            end
        end

        % each functional file
    end
    
    if contains(folders(ii).name, 'Classification_Scene.zip')
        
        copyfile(fullfile(downloadDir, folders(ii).name, subjectID, 'MNINonLinear/fsaverage_LR32k', [subjectID, '.R.midthickness.32k_fs_LR.surf.gii']), fullfile(paths.anatDir, 'R.midthickness.32k_fs_LR.surf.gii'));
        copyfile(fullfile(downloadDir, folders(ii).name, subjectID, 'MNINonLinear/fsaverage_LR32k', [subjectID, '.L.midthickness.32k_fs_LR.surf.gii']), fullfile(paths.anatDir, 'L.midthickness.32k_fs_LR.surf.gii'));

    end
    rmdir(fullfile(downloadDir, folders(ii).name), 's');
end

%rmdir(unzipDir, 's')
end