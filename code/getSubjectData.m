function getSubjectData(subjectID, varargin)

%% input parser
p = inputParser; p.KeepUnmatched = true;
p.addParameter('dataDownloadDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/temp'), @isstring);
p.addParameter('paramsFileName','analysesLabels.csv', @ischar);
p.parse(varargin{:});

%% load in the analysesLabels table to find the relevant analyses to download
paramsFileName = p.Results.paramsFileName;

theProject = 'tome';
analysisLabel = '';

paramsTable = readtable(paramsFileName,'ReadVariableNames',false,'FileType','text','Delimiter','comma');
paramsArray = table2cell(paramsTable);

numberOfSubjects = size(paramsArray,1);

for ss = 1:numberOfSubjects
    if strcmp(paramsArray{ss,1}, subjectID)
        relevantRow = ss;
        numberOfAnalyses = size(paramsTable(ss,:),2) - 1;
    end
end

%% Loop through the analyses, download them, and unpack them
for aa = 1:numberOfAnalyses
        
    analysisLabel = paramsArray{relevantRow, aa+1};
    
    % figure out what type of analysis we're dealing with, because that
    % informs which files we want
    runName = strsplit(analysisLabel, '[');
    runName = runName{2};
    runName = strsplit(runName, ']');
    runName = runName{1};
    runName = strtrim(runName);
    
    if ~exist(p.Results.dataDownloadDir, 'dir')
        mkdir(p.Results.dataDownloadDir);
    end
  
    
    
    if strcmp(runName, 'T1w_MPR')
        fileName = [subjectID, '_hcpstruct.zip'];
        downloadType = 'analysis';
        [fwInfoStruct] = getAnalysisFromFlywheel(theProject,analysisLabel,p.Results.dataDownloadDir, subjectID, fileName, 'downloadType', downloadType);
        % grab standard2acpc_dc.nii.gz
        % grab T1w_acpc_dc_restore.nii.gz
        % grab freeSurfer
        
    else
        % get functional analyses
        fileName = [subjectID, '_', runName, '_hcpfunc.zip'];
        downloadType = 'analysis';
        [fwInfoFunc] = getAnalysisFromFlywheel(theProject,analysisLabel,p.Results.dataDownloadDir, subjectID, fileName, 'downloadType', downloadType);
        % grab runName_mni.nii.gz
        
        % get the physio
        fileName = [runName, '_puls.mat'];
        downloadType = 'physio';
        [fwInfoPhysio] = getAnalysisFromFlywheel(theProject,analysisLabel,p.Results.dataDownloadDir, subjectID, fileName, 'downloadType', downloadType);
        % get _puls.mat

    end
end




end

