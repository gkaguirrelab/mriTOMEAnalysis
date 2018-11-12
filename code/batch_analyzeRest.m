function batch_analyzeRest

% set up error log
errorLogPath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/');
currentTime = clock;
errorLogFilename = ['errorLog_', num2str(currentTime(1)), '-', num2str(currentTime(2)), '-', num2str(currentTime(3)), '_', num2str(currentTime(4)), num2str(currentTime(5))];
system(['echo "', 'SubjectID', ',', 'runName', '" > ', [errorLogPath, errorLogFilename]]);

fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));

searchStruct = struct(...
    'returnType', 'file', ...
    'filters', {{ ...
    struct('wildcard', struct('analysis0x2elabel', '*hcp-struct*')), ...
    struct('match', struct('project0x2elabel', 'tome')), ...
    }} ...
    );
analyses = fw.search(searchStruct, 'size', '1000');

for ii = 1:numel(analyses)
    
    if ~strcmp(analyses{ii}.file.name, [analyses{ii}.subject.code, '_hcpstruct.zip'])
        analyses{ii} = [];
    end
end

analyses = analyses(~cellfun('isempty', analyses));



numberOfSubjects = size(analyses,1);
%% from each session, download the hcp-struct.zip
for ss = 4:numberOfSubjects
    
    subjectID = analyses{ss}.subject.code;

    searchStruct = struct(...
        'returnType', 'file', ...
        'filters', {{ ...
        struct('wildcard', struct('analysis0x2elabel', ['*hcp-func*'])), ...
        struct('match', struct('project0x2elabel', 'tome')), ...
        }} ...
        );
    subjectAnalyses = [];
    subjectAnalyses = fw.search(searchStruct, 'size', '10000');
    
    for ii = 1:numel(subjectAnalyses)
        
        if ~strcmp(subjectAnalyses{ii}.subject.code, subjectID) || ~contains(subjectAnalyses{ii}.file.name, 'REST') || ~contains(subjectAnalyses{ii}.file.name, 'hcpfunc.zip') || contains(subjectAnalyses{ii}.file.name, 'log')
            subjectAnalyses{ii} = [];
        end
    end
    
    subjectAnalyses = subjectAnalyses(~cellfun('isempty', subjectAnalyses));
    
    runNames = [];
    for ii = 1:length(subjectAnalyses)
        
        wholeFileName = subjectAnalyses{ii}.file.name;
        wholeFileName_split = strsplit(wholeFileName, '_');
        runName = [wholeFileName_split{3}, '_', wholeFileName_split{4}, '_', wholeFileName_split{5}, '_', wholeFileName_split{6}];
        runNames{end+1} = runName;
        
    end
    
    for rr = 1:length(runNames)
        
        runName = runNames{rr};
        
        try
        analyzeRest(subjectID, runName);
        
        close all
        catch
            system(['echo "', subjectID, ',', runName, '" >> ', [errorLogPath, errorLogFilename]]);
        end
        
    end
end

end
