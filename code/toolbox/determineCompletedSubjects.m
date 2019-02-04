%{

pathToCompletedRuns = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/errorLogs/completedRuns')
[completedSubjects] = determineCompletedSubjects(pathToCompletedRuns)

%}

function [completedSubjects] = determineCompletedSubjects(pathToCompletedRuns)

fileID = fopen(pathToCompletedRuns);

text = textscan(fileID, '%s');
subjects = [];
runs = [];
for rr = 1:length(text{1})
   rowSplit = strsplit(text{1}{rr}, ',');
   subjects{end+1} = rowSplit{1};
   runs{end+1} = rowSplit{2};
end
    
subjects = unique(subjects);

completedSubjects = [];
for ss = 1:length(subjects)
   [ runNames ] = getRunsPerSubject(subjects{ss});
   counter = 0;
   for rr = 1:length(runNames)
       if sum(cellfun(@isempty, strfind(text{1}, [subjects{ss},',', runNames{rr}]))) < length(text{1})
           counter = counter + 1;
       end
   end
   if counter == length(runNames)
       completedSubjects{end+1} = subjects{ss};
   end
       
   
end

fclose(fileID);

%text = xlsread(pathToCompletedRuns);

end