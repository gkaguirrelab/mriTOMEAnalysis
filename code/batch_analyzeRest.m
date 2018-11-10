function batch_analyzeRest

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
for ss = 1:numberOfSubjects
    
    searchStruct = struct(...
        'returnType', 'file', ...
        'filters', {{ ...
        struct('wildcard', struct('analysis0x2elabel', ['*hcp-func*'])), ...
        struct('match', struct('project0x2elabel', 'tome')), ...
        }} ...
        );
    analyses = [];
    analyses = fw.search(searchStruct, 'size', '10000');
    
    for ii = 1:numel(analyses)
        
        if ~strcmp(analyses{ii}.subject.code, subjectID) || ~contains(analyses{ii}.file.name, 'REST') || ~contains(analyses{ii}.file.name, 'hcpfunc.zip') || contains(analyses{ii}.file.name, 'log')
            analyses{ii} = [];
        end
    end
    
    analyses = analyses(~cellfun('isempty', analyses));
    
    runNames = [];
    for ii = 1:length(analyses)
        
        wholeFileName = analyses{ii}.file.name;
        wholeFileName_split = strsplit(wholeFileName, '_');
        runName = [wholeFileName_split{3}, '_', wholeFileName_split{4}, '_', wholeFileName_split{5}, '_', wholeFileName_split{6}];
        runNames{end+1} = runName;
        
    end
    
    for rr = 1:length(runNames)
        
        subjectID = analyses{ss}.subject.code;
        runName = runNames{rr};
        analyzeRest(subjectID, runName);
        
        close all
        
    end
end

end
