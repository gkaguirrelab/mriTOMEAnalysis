% assemble fileNamesCellArray

subjectList = {'TOME_3003'};
stats = {'rSquared', 'beta'};
covariateTypes = {'pupilDiameter+pupilChange', 'pupilDiameter', 'constrictions', 'dilations', 'eyeDisplacement', 'PUI100', 'PUI1000', 'pupilChange', 'rectifiedPupilChange'};

masterFileNamesCellArray = [];


for cc = 1:length(covariateTypes)
    
    covariateType = covariateTypes{cc};
    
    
    
    for stat = 1:length(stats)
        
        if strcmp(stats{stat}, 'beta')
            for covariateSubType = 1:length(strsplit(covariateType,'+'))
                betas = strsplit(covariateType, '+');

                statsType = [betas{covariateSubType}, '_beta'];
                masterFileNamesCellArray = [];
                for ss = 1:length(subjectList)
                    
                    subjectID = subjectList{ss};
                    
                    
                    
                    fileNamesCellArray{1} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_AP_Run1_', covariateType, '_', statsType, '.dscalar.nii']);
                    fileNamesCellArray{2} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_PA_Run2_', covariateType, '_', statsType, '.dscalar.nii']);
                    fileNamesCellArray{3} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_AP_Run3_', covariateType, '_', statsType, '.dscalar.nii']);
                    fileNamesCellArray{4} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_PA_Run4_', covariateType, '_', statsType, '.dscalar.nii']);
                    
                end
                masterFileNamesCellArray = [ masterFileNamesCellArray, fileNamesCellArray];
            combineCIFTIs(masterFileNamesCellArray)
            end
            
            
        else
            masterFileNamesCellArray = [];
            for ss = 1:length(subjectList)
                
                subjectID = subjectList{ss};
                statsType = stats{stat};
                
                fileNamesCellArray{1} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_AP_Run1_', covariateType, '_', statsType, '.dscalar.nii']);
                fileNamesCellArray{2} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_PA_Run2_', covariateType, '_', statsType, '.dscalar.nii']);
                fileNamesCellArray{3} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_AP_Run3_', covariateType, '_', statsType, '.dscalar.nii']);
                fileNamesCellArray{4} = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, ['rfMRI_REST_PA_Run4_', covariateType, '_', statsType, '.dscalar.nii']);
            end
            masterFileNamesCellArray = [ masterFileNamesCellArray, fileNamesCellArray];
            combineCIFTIs(masterFileNamesCellArray)
        end
        
        
        
    end
    
end
