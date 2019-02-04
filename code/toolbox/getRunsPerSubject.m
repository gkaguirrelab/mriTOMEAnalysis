function [runNames] = getRunsPerSubject(subjectID)

fw = flywheel.Flywheel('upenn.flywheel.io:xRBvFBoJddS12kWEkM');

result = fw.lookup('tome/tome');
allSessions = fw.getProjectSessions(result.id);

analyses = [];
for ii = 1:numel(allSessions)
    if ~strcmp(allSessions{ii}.subject.code, subjectID)
        allSessions{ii} = [];
        
    end
    
end

allSessions = allSessions(~cellfun('isempty', allSessions));
for ii = 1:numel(allSessions)
    newAnalyses = fw.getSessionAnalyses(allSessions{ii}.id);
    analyses = [analyses; newAnalyses];
end

for ii = 1:numel(analyses)
    
    if ~contains(analyses{ii}.label, 'hcp-icafix') || ~contains(analyses{ii}.label, 'REST')
        analyses{ii} = [];
    end
end
analyses = analyses(~cellfun('isempty', analyses));

runNames = [];
for ff = 1:length(analyses{1}.inputs)
    if ~contains(analyses{1}.inputs{ff}.name, 'hcpstruct')
         fileName = analyses{1}.inputs{ff}.name;
         fileNameSplit = strsplit(fileName, '_hcpfunc.zip');
         fileNameSplit = fileNameSplit{1};
         fileNameSplit = strsplit(fileNameSplit, [subjectID, '_']);
         runName= fileNameSplit{2};
         
         runNames{end+1} = runName;
    end
end

end