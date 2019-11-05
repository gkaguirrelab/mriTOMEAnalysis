% Script to download analysis files

% gearName = 'forwardmodel';
% modelClass = 'prfTimeShift';
% outDir = '/Users/aguirre/Desktop/bayesPRFPlots';
% fileType = 'image';

gearName = 'bayesprf';
modelClass = '';
outDir = '/Users/aguirre/Desktop/bayesPRFPlots';

% Leave one of these empty
fileType = 'image';
fileName = '';

%% Instantiate the flywheel object
fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));

% Get a list of all completed flobsHRF models on the forwardModel gear

if ~isempty(modelClass)
    jobList = fw.jobs.find(...
        'state=complete',...
        ['gear_info.name=' gearName],...
        ['config.config.modelClass="' modelClass '"']);
else
    jobList = fw.jobs.find(...
        'state=complete',...
        ['gear_info.name=' gearName]);
end

% Loop through the analyses. Can't figure out how to get the flywheel api
% to let me know if an analysis still exists or not, so right now I'm doing
% this in a try-catch frame (yuck).
for jj = 1:length(jobList)
    try
        analysisHandle = fw.getAnalysis(jobList{jj}.destination.id);
    catch
        continue
    end
    
    % If there are no files in this analysis, continue
    if isempty(analysisHandle.files)
        continue
    end
    
    % Check if this is a tome project analysis
    if strcmp(analysisHandle.parents.group,'tome')
        
        % Download the files
        if ~isempty(fileName)
            fileIdx = find(cellfun(@(x) contains(x.name,fileName),analysisHandle.files));
        else
            fileIdx = find(cellfun(@(x) strcmp(x.type,fileType),analysisHandle.files));
        end
        for pp = 1:length(fileIdx)
            outName = analysisHandle.files{fileIdx(pp)}.name;
            outPath = fullfile(outDir,outName);
            fw.downloadOutputFromAnalysis(analysisHandle.id,outName,outPath);
        end
        
    end
    
end

