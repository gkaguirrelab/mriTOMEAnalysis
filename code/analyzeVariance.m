function analyzeVariance(subjectList)

if isempty(subjectList)
    subjectList = {'TOME_3001', 'TOME_3002', 'TOME_3003', 'TOME_3004', 'TOME_3005', 'TOME_3007', 'TOME_3008', 'TOME_3009', 'TOME_3011', 'TOME_3012', 'TOME_3013', 'TOME_3014', 'TOME_3015', 'TOME_3016', 'TOME_3017', 'TOME_3018', 'TOME_3019', 'TOME_3020', 'TOME_3021', 'TOME_3022'};   
end

%% assemble list of runs across subjects
counter = 1;
for ss = 1:length(subjectList)
    potentialRuns = dir(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectList{ss}, '*_physioMotionWMVCorrected.mat'));
    subjectID = subjectList{ss};
    
    for rr = 1:length(potentialRuns)
        subjectListPooled{counter} = subjectID;
        runListPooled{counter} = potentialRuns(rr).name;
        counter = counter + 1;
    end
    
    
end

%% copy over the pupil data
% to ensure we have the latest version
downloadPupil = true;

if downloadPupil

for rr = 1:length(runListPooled)
    
   runName = strsplit(runListPooled{rr}, '_timeSeries');
   runName = runName{1};
   getSubjectData(subjectListPooled{rr}, runName, 'downloadOnly', 'pupil')
    
end

end
    

end