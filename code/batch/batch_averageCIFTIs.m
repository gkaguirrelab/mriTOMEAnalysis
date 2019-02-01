% assemble fileNamesCellArray

subjectList = determineCompletedSubjects(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/errorLogs/completedRuns'));
stats = {'beta', 'rSquared'};
covariateTypes = {'pupilDiameter+pupilChange', 'pupilDiameter', 'pupilChange'};

masterFileNamesCellArray = [];


for cc = 1:length(covariateTypes)
    
    covariateType = covariateTypes{cc};
    
    
    
    for stat = 1:length(stats)
        
        if strcmp(stats{stat}, 'beta')
            for covariateSubType = 1:length(strsplit(covariateType,'+'))
                betas = strsplit(covariateType, '+');
                
                for derivative = 1:2
                    masterFileNamesCellArray = [];

                    if derivative == 1
                        statsType= [betas{covariateSubType}, '_beta'];
                    else
                        statsType = ['firstDerivative', upper(betas{covariateSubType}(1)), betas{covariateSubType}(2:end), '_beta'];

                    end
                    for ss = 1:length(subjectList)
                        
                        subjectID = subjectList{ss};
                        
                        runNames = getRunsPerSubject(subjectID);
                        for rr = 1:length(runNames)
                            fileName = {fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, [runNames{rr} '_', covariateType, '_', statsType, '.dscalar.nii'])};
                            masterFileNamesCellArray = [ masterFileNamesCellArray, fileName];
                            
                        end
                        
                    end
                    savePath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'average');
                    combineCIFTIs(masterFileNamesCellArray, 'savePath', savePath)
                end
            end
            
            
        else
            masterFileNamesCellArray = [];
            statsType = 'rSquared';
            for ss = 1:length(subjectList)
                
                subjectID = subjectList{ss};
                runNames = getRunsPerSubject(subjectID);
                for rr = 1:length(runNames)
                    fileName = {fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', subjectID, [runNames{rr} '_', covariateType, '_', statsType, '.dscalar.nii'])};
                    masterFileNamesCellArray = [ masterFileNamesCellArray, fileName];
                    
                end
            end
                                savePath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'average');

            combineCIFTIs(masterFileNamesCellArray, 'savePath', savePath)
        end
        
        
        
    end
    
end
