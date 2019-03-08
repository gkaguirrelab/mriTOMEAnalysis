function combineCIFTIs(fileNamesCellArray, varargin)
%{
 % assemble fileNamesCellArray

 subjectList = {'TOME_3003'};
 stats = {'rSquared', 'beta'};
 covariateTypes = {'pupilDiameter+pupilChange', 'pupilDiameter', 'constrictions', 'dilations', 'eyeDisplacement', 'PUI100', 'PUI1000', 'PUI5000', 'PUI10000', 'pupilChange', 'rectifiedPupilChange'};

 masterFileNamesCellArray = [];

 for ss = 1:length(subjectList)

    subjectID = subjectList{ss};

    for cc = 1:length(covariateTypes);

        covariateType = covariateTypes{cc};

         

            for stat = 1:length(stats)
                
                if strcmp(stats{stat}, 'beta')
                    for covariateSubType = 1:length(strsplit(covariateType,'+'))

                        betas = strsplit(covariateType, '+')
                        statsType = [betas{covariateSubType}, '_beta'];

                        fileNamesCellArray{1} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_AP_Run1_', covariateType, '_', statsType, '.dscalar.nii']);
                        fileNamesCellArray{2} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_PA_Run2_', covariateType, '_', statsType, '.dscalar.nii']);
                        fileNamesCellArray{3} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_AP_Run3_', covariateType, '_', statsType, '.dscalar.nii']);
                        fileNamesCellArray{4} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_PA_Run4_', covariateType, '_', statsType, '.dscalar.nii']);
  
                    
                    end

                else
                    statsType = stats{stat};

                    fileNamesCellArray{1} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_AP_Run1_', covariateType, '_', statsType, '.dscalar.nii']);
                    fileNamesCellArray{2} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_PA_Run2_', covariateType, '_', statsType, '.dscalar.nii']);
                    fileNamesCellArray{3} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_AP_Run3_', covariateType, '_', statsType, '.dscalar.nii']);
                    fileNamesCellArray{4} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_PA_Run4_', covariateType, '_', statsType, '.dscalar.nii']);
                end

                masterFileNamesCellArray = [ masterFileNamesCellArray; fileNamesCellArray];
                combineCIFTIs(masterFileNamesCellArray)

            end
        
    end
 end

%}
%% Input parser
p = inputParser; p.KeepUnmatched = true;
p.addParameter('workbenchPath', '/Applications/workbench/bin_macosx64/', @ischar);
p.addParameter('savePath', [], @ischar);
p.addParameter('saveName', [], @ischar);
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
    
    % delete text file intermediate
    system(['rm "', fullfile(savePath, [fileName, '.txt']), '"']);
    
    % stash the results
    grayordinatesCombinedMatrix(:,:,ii) = table2array(grayordinates);
end

% compute the mean
meanGrayordinates = mean(grayordinatesCombinedMatrix,3);

% write it out
fileNameSplit = strsplit(fileName, '_');
runType = [fileNameSplit{1}, '_', fileNameSplit{2}];
covariateType = fileNameSplit{5};

if strcmp(fileNameSplit{end}, 'beta')
    statsType = [fileNameSplit{end-1}, '_', fileNameSplit{end}];
else
    statsType = fileNameSplit{end};
end

if ~isempty(p.Results.savePath)
    savePath = p.Results.savePath;
end
% first to text file
dlmwrite(fullfile(savePath, ['average_', runType, '_stats.txt']), meanGrayordinates, 'delimiter','\t')  
if isempty(p.Results.saveName)
    fullSaveName = fullfile(savePath, ['average_', runType, '_', covariateType, '_', statsType, '.dscalar.nii']);
else
    fullSaveName = fullfile(savePath, p.Results.saveName);
end
% now to CIFTI
system(['bash ', p.Results.workbenchPath, 'wb_command -cifti-convert -from-text "', fullfile(savePath, ['average_', runType, '_stats.txt']), '" "', fileNamesCellArray{1}, '" "', fullSaveName, '"']);

% delete text file intermediate
system(['rm "', fullfile(savePath, ['average_', runType, '_stats.txt']), '"']);
end