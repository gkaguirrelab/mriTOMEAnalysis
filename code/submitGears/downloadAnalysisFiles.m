% Script to download analysis files

gearName = 'forwardmodel';
modelClass = 'prfTimeShift';
fileType = 'image';

% Where to save the files
outDir = '/Users/aguirre/Desktop/prfTimeShiftPlots';


%% Instantiate the flywheel object
fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));

% Get a list of all completed flobsHRF models on the forwardModel gear
jobList = fw.jobs.find(...
    'state=complete',...
    ['gear_info.name=' gearName],...
    ['config.config.modelClass="' modelClass '"']);


% Loop through the analyses. Can't figure out how to get the flywheel api
% to let me know if an analysis still exists or not, so right now I'm doing
% this in a try-catch frame (yuck).
for jj = 1:length(jobList)
    try
        analysisHandle = fw.getAnalysis(jobList{jj}.destination.id);
    catch
        continue
    end
    
    % Check if this is a tome project analysis
    if strcmp(analysisHandle.parents.group,'tome')
        
        % Download the files
        fileIdx = find(cellfun(@(x) strcmp(x.type,fileType),analysisHandle.files));
        for pp = 1:length(fileIdx)
            fileName = analysisHandle.files{fileIdx(pp)}.name;
            outPath = fullfile(outDir,fileName);
            fw.downloadOutputFromAnalysis(analysisHandle.id,fileName,outPath);
        end
        
    end
    
end

