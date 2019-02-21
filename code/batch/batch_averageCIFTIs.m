% assemble fileNamesCellArray


%subjectList = determineCompletedSubjects(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/errorLogs/completedRuns'));
subjectList = {'TOME_3001', ...
'TOME_3002', ...
'TOME_3003', ...
'TOME_3004', ...
'TOME_3005', ...
'TOME_3008', ...
'TOME_3009', ...
'TOME_3011', ...
'TOME_3012', ...
'TOME_3013', ...
'TOME_3014', ...
'TOME_3015', ...
'TOME_3016', ...
'TOME_3018', ...
'TOME_3020', ...
'TOME_3021', ...
'TOME_3022', ...
'TOME_3023', ...
'TOME_3024', ...
'TOME_3025', ...
'TOME_3026', ...
'TOME_3028', ...
'TOME_3029', ...
'TOME_3030', ...
'TOME_3032', ...
'TOME_3033', ...
'TOME_3034', ...
'TOME_3035', ...
'TOME_3036', ...
'TOME_3038', ...
'TOME_3039', ...
'TOME_3042'};

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
