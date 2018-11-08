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
restScans = {'rfMRI_REST_AP_Run1', 'rfMRI_REST_PA_Run2', 'rfMRI_REST_AP_Run3', 'rfMRI_REST_PA_Run4'};
%% from each session, download the hcp-struct.zip
for ss = 1:numberOfSubjects
    for rr = 1:length(restScans)
        
        subjectID = analyses{ss}.subject.code;
        runName = restScans{rr};
        analyzeRest(subjectID, runName);
        
        close all
        
    end
end

end
