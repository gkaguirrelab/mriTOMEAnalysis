% Download TOME hcp-struct analysis result to local directory

projectName = 'tome';
gearName = 'hcp-diff';
rootSaveDir = '~/Desktop/dataForRito';
outputFileStem = '_hcpdiff.zip';

%% Instantiate the flywheel object
fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));

%% Find all analyses of the specified gear
searchStruct = struct(...
        'returnType', 'analysis', ...
        'filters', {{ struct('wildcard', struct('analysis0x2elabel', ['*' gearName '*']))}} ...
        );
analyses = fw.search(searchStruct);

%% Refine to just those in the specified project
idx = cellfun(@(x) strcmp(projectName,x.project.label),analyses);
analyses = analyses(idx);

%% Loop through the analyses and download
for ii = 1:numel(analyses)
    
    % Get the analysis object
    thisAnalysis = fw.getAnalysis(analyses{ii}.analysis.id);

    % Find the file with the matching stem
    fileMatchIdx = cellfun(@(x) contains(x.name,outputFileStem),thisAnalysis.files);

    % Have some sanity checking here to error if there are none or more
    % than one matching files
    %% TODO
        
    % Download the matching files to the rootSaveDir
    thisName = thisAnalysis.files{fileMatchIdx}.name;
    fw.downloadOutputFromAnalysis(thisAnalysis.id,thisName,fullfile(rootSaveDir,thisName));
end

