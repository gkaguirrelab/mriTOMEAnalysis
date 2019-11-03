% Script to extract and report the flobsHRF median HRF parameters across
% the TOME subjects.


%% Instantiate the flywheel object
fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));

% Get a list of all completed flobsHRF models on the forwardModel gear
jobList = fw.jobs.find(...
    'state=complete',...
    'gear_info.name=forwardmodel',...
    'config.config.modelClass="flobsHRF"');

% Create a temporary directory to save files
outDir = tempdir;
plotDir = '/Users/aguirre/Desktop/flobsHRFPlots';

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
        
        % Find the results.mat file and download
        fileIdx = find(cellfun(@(x) strcmp(x.type,'MATLAB data'),analysisHandle.files));
        fileName = analysisHandle.files{fileIdx}.name;
        outPath = fullfile(outDir,fileName);
        fw.downloadOutputFromAnalysis(analysisHandle.id,fileName,outPath);
        
        % Load the mat file into memory
        load(outPath,'results')
        
        % Report this result to the screen
        fprintf([fileName ' - (hrfParams),[%2.4f,%2.4f,%2.4f]\n'],results.summary.medianParams)
        
        % Download the plots
        % Find the results.mat file and download
        plotIdx = find(cellfun(@(x) strcmp(x.type,'pdf'),analysisHandle.files));
        for pp = 1:length(plotIdx)
            fileName = analysisHandle.files{plotIdx(pp)}.name;
            outPath = fullfile(plotDir,fileName);
            fw.downloadOutputFromAnalysis(analysisHandle.id,fileName,outPath);
        end
        
    end
    
end

