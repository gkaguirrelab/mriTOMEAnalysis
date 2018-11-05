function getSubjectData(subjectID, runName, varargin)

%% input parser
p = inputParser; p.KeepUnmatched = true;
p.addParameter('dataDownloadDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/temp'), @isstring);
p.addParameter('paramsFileName','analysesLabels.csv', @ischar);
p.parse(varargin{:});

%% load in the analysesLabels table to find the relevant analyses to download
% paramsFileName = p.Results.paramsFileName;
% 
theProject = 'tome';
% searchTerm = '';
% 
% paramsTable = readtable(paramsFileName,'ReadVariableNames',false,'FileType','text','Delimiter','comma');
% paramsArray = table2cell(paramsTable);
% 
% numberOfSubjects = size(paramsArray,1);
% 
% for ss = 1:numberOfSubjects
%     if strcmp(paramsArray{ss,1}, subjectID)
%         relevantRow = ss;
%         numberOfAnalyses = size(paramsTable(ss,:),2) - 1;
%     end
% end

%% Loop through the analyses, download them, and unpack them
%for aa = 1:numberOfAnalyses
        
    %searchTerm = paramsArray{relevantRow, aa+1};
    
    % figure out what type of analysis we're dealing with, because that
%     % informs which files we want
%     runName = strsplit(searchTerm, '[');
%     runName = runName{2};
%     runName = strsplit(runName, ']');
%     runName = runName{1};
%     runName = strtrim(runName);
    
    if ~exist(p.Results.dataDownloadDir, 'dir')
        mkdir(p.Results.dataDownloadDir);
    end
  
    
    
    %if strcmp(runName, 'T1w_MPR')
        fileName = [subjectID, '_hcpstruct.zip'];
        searchTerm = '*hcp_struct.zip';
        downloadType = 'analysis';
        %[fwInfoStruct] = getAnalysisFromFlywheel(theProject,searchTerm,p.Results.dataDownloadDir, subjectID, fileName, 'downloadType', downloadType);
        % grab subjectID/MNINonLinear/xfms/standard2acpc_dc.nii.gz
        % grab subjectID/T1w/T1w_acpc_dc_restore.nii.gz
        % grab subjectID/T1w/subjectID -> the freeSurfer folder
        
    %else
        % get functional analyses
        fileName = [subjectID, '_', runName, '_hcpfunc.zip'];
        downloadType = 'analysis';
        searchTerm = '*hcp_func.zip';

        [fwInfoFunc] = getAnalysisFromFlywheel(theProject,searchTerm,p.Results.dataDownloadDir, subjectID, fileName, 'downloadType', downloadType);
        % grab subjectID/MNINonLinear/Results/runName/runName.nii.gz
        
        % get the physio
        fileName = [runName, '_puls.mat'];
        downloadType = 'physio';
        [fwInfoPhysio] = getAnalysisFromFlywheel(theProject,searchTerm,p.Results.dataDownloadDir, subjectID, fileName, 'downloadType', downloadType);
        % get _puls.mat

    %end
%end




end

