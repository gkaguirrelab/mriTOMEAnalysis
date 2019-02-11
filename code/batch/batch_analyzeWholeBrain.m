function batch_analyzeWholeBrain

% set up error log
errorLogPath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/errorLogs/');
currentTime = clock;
errorLogFilename = ['errorLog_WholeBrain_', num2str(currentTime(1)), '-', num2str(currentTime(2)), '-', num2str(currentTime(3)), '_', num2str(currentTime(4)), num2str(currentTime(5))];
system(['echo "', 'SubjectID', ',', 'runName', '" > ', [errorLogPath, errorLogFilename]]);

allSubjects = {'TOME_3001', 'TOME_3003','TOME_3002', 'TOME_3004','TOME_3004','TOME_3005','TOME_3008','TOME_3009','TOME_3011','TOME_3012','TOME_3013','TOME_3014','TOME_3015', 'TOME_3016', 'TOME_3018', 'TOME_3022', 'TOME_3020', 'TOME_3023', 'TOME_3024'};
completedSubjects = determineCompletedSubjects(fullfile(errorLogPath, 'completedRuns'));

[~, userID] = system('whoami');
userID = strtrim(userID);
if contains(userID, 'harrisonmcadams')
    subjects = {allSubjects{1:2:end}};
    subjects = setdiff(subjects, completedSubjects);
elseif contains(userID, 'coloradmin')
    subjects = {allSubjects{2:2:end}};
    subjects = setdiff(subjects, completedSubjects);
end

%% from each session, download the hcp-struct.zip
for ss = 1:length(subjects)
    subjectID = subjects{ss};
    
    [ runNames ] = getRunsPerSubject(subjectID);
    for rr = 1:length(runNames)
        
        runName = runNames{rr};
        
        fprintf('Now analyzing Subject %s, Run %s\n', subjectID, runName);
        
        try
            analyzeWholeBrain(subjectID, runName, 'fileType', 'CIFTI');
            system(['echo "', subjectID, ',', runName, '" >> ', [errorLogPath, 'completedRuns']]);
            
            close all
        catch
            system(['echo "', subjectID, ',', runName, '" >> ', [errorLogPath, errorLogFilename]]);
        end
        
    end
end

end
