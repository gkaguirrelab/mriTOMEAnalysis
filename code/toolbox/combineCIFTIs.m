function combineCIFTIs(fileNamesCellArray, varargin)
%{
 % assemble fileNamesCellArray

 subjectList = {'TOME_3003'};
 stats = {'beta'};
 covariateTypes = {'pupilDiameter+pupilChange', 'pupilDiameter', 'constrictions', 'dilations', 'eyeDisplacement', 'PUI100', 'PUI1000', 'PUI5000', 'PUI10000', 'pupilChange', 'rectifiedPupilChange'};

 masterFileNamesCellArray = [];

 for ss = 1:length(subjectList)

    subjectID = subjectList{ss};

    for cc = 1:length(covariateTypes);

        covariateType = covariateTypes{cc};

            for stat = 1:length(stats)

                statsType = stats{stat};

                fileNamesCellArray{1} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_AP_Run1_', covariateType, '_', statsType, '.dscalar.nii']);
                fileNamesCellArray{2} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_PA_Run2_', covariateType, '_', statsType, '.dscalar.nii']);
                fileNamesCellArray{3} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_AP_Run3_', covariateType, '_', statsType, '.dscalar.nii']);
                fileNamesCellArray{4} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_PA_Run4_', covariateType, '_', statsType, '.dscalar.nii']);

                masterFileNamesCellArray = [ masterFileNamesCellArray; fileNamesCellArray];
            end
    end
 end
 combineCIFTIs(fileNamesCellArray)

%}
%% Input parser
p = inputParser; p.KeepUnmatched = true;
p.addParameter('workbenchPath', '/Applications/workbench/bin_macosx64/', @ischar);
p.parse(varargin{:});



for ii = 1:length(fileNamesCellArray)
    % get some information about the path for saving purposes
    [ savePath, fileName ] = fileparts(fileNamesCellArray{ii});
    fileName = strsplit(fileName, '.');
    fileName = fileName{1};
    
    % convert CIFTI to text
    system(['bash ', p.Results.workbenchPath, 'wb_command -cifti-convert -to-text ', fileNamesCellArray{ii}, ' ', fullfile(savePath, [fileName, '.txt'])]);
    
    % read text file into matlab
    grayordinates = readtable(fullfile(savePath, [fileName, '.txt']), 'ReadVariableNames', false);
    
    % stash the results
    grayordinatesCombinedMatrix(:,:,ii) = table2array(grayordinates);
end

% compute the mean
meanGrayordinates = mean(grayordinatesCombinedMatrix,3);

% write it out
fileNameSplit = strsplit(fileName, '_');
runType = [fileNameSplit{1}, '_', fileNameSplit{2}];
covariateType = fileNameSplit{5};
statsType = fileNameSplit{6};
% first to text file
dlmwrite(fullfile(savePath, ['average_', runType, '_stats.txt']), meanGrayordinates, 'delimiter','\t')  
% now to CIFTI
system(['bash ', p.Results.workbenchPath, 'wb_command -cifti-convert -from-text "', fullfile(savePath, ['average_', runType, '_stats.txt']), '" "', fileNamesCellArray{1}, '" "', fullfile(savePath, ['average_', runType, '_', covariateType, '_', statsType, '.dscalar.nii']), '"']);

end