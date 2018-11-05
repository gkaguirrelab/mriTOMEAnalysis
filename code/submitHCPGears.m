function submitHCPGears(paramsFileName)
% Submits jobs to the flywheel instance based upon a table of parameters
%
% Syntax
%  result = submitHCPGears(paramsFileName)
%
% Description:
%
%
%

% Examples:
%{
    submitHCPGears('tomeNoahRetinoParams.csv');
%}

%% Load and parse the params table
% This identifies the subjects and inputs to be processed
paramsTable = readtable(paramsFileName,'ReadVariableNames',false,'FileType','text','Delimiter','comma');

% Parse the table header
p = inputParser; p.KeepUnmatched = false;
p.addParameter('projectName','tome',@ischar);
p.addParameter('gearName','hcp-func',@ischar);
p.addParameter('rootSessionInputLabel','fMRITimeSeries',@ischar);
p.addParameter('verbose','true',@ischar);
p.addParameter('AcqFileType','nifti',@ischar);
p.addParameter('includeFreeSurferLicenseFile','true', @ischar);
p.addParameter('freesurferLicenseFileName','freesurfer_license.txt',@(x)(isempty(x) || ischar(x)));
p.addParameter('configKeys','',@(x)(isempty(x) || ischar(x)));
p.addParameter('configVals','',@(x)(isempty(x) || ischar(x)));
tableVarargin = paramsTable{1,1:end};
p.parse(tableVarargin{:});

% The parameters arrive as char variables from the csv file. Eval some of
% them here.
verbose = eval(p.Results.verbose);
includeFreeSurferLicenseFile = eval(p.Results.includeFreeSurferLicenseFile);

% Define the paramsTable dimensions
nParamRows = 6; % This is the number of rows that make up the header
nParamCols = 1; % This is for the first column that has header info

% Hard-coded identity of the header row information
InputsRow = 2;
DefaultLabelRow = 3;
IsSessionFileRow = 4;
IsAnalysisFileRow = 5;
ExactStringMatchRow = 6;

% Determine the number of inputs to specify for this gear
nInputCols = sum(cellfun(@(x) ~isempty(x),paramsTable{InputsRow,:}));
nRows = size(paramsTable,1);

%% Instantiate the flywheel object
fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));


%% Get project ID and sessions
allProjects = fw.getAllProjects;
projIdx = find(strcmp(cellfun(@(x) x.label,allProjects,'UniformOutput',false),p.Results.projectName),1);
projID = allProjects{projIdx}.id;
allSessions = fw.getProjectSessions(projID);


%% Identify the freesurfer license file
if includeFreeSurferLicenseFile
    fsLicFileIdx = find(strcmp(cellfun(@(x) x.name,allProjects{projIdx}.files,'UniformOutput',false),p.Results.freesurferLicenseFileName));
    fsLicFileName = allProjects{projIdx}.files{fsLicFileIdx}.name;
    fsLicFileID = allProjects{projIdx}.id;
    fsLicFileType = 'project';
    fsLicFileLabel = 'FreeSurferLicense';
else
    fsLicFileID = [];
end

%% Construct the gear configuration
% Get all the gears
allGears = fw.getAllGears();

% Find the particular gear we are going to use
theGearIdx=find(strcmp(cellfun(@(x) x.gear.name,allGears,'UniformOutput',false),p.Results.gearName));
theGearID = allGears{theGearIdx}.id;
theGearName = allGears{theGearIdx}.gear.name;
theGearVersion = allGears{theGearIdx}.gear.version;

% Build the config params. Read the config to set the defaults and edit
% required ones
gear = fw.getGear(theGearID);
gearCfg = struct(gear.gear.config);
configDefault = struct;
keys = fieldnames(gearCfg);
for i = 1:numel(keys)
    val = gearCfg.(keys{i});
    if isfield(val, 'default')
        configDefault.(keys{i}) = val.default;
    else
        if verbose
        fprintf('No default value for %s\n. It must be set prior to execution.', keys{i});
        end
    end
end


%% Loop through jobs
for ii=nParamRows+1:nRows
    
    % Check if this row is empty. If so, continue
    if isempty(char(paramsTable{ii,1}))
        continue
    end
    
    % Get the subject name
    subjectName = char(paramsTable{ii,1});

    %% Assemble Inputs
    % Create an empty inputs struct
    inputs = struct();
    
    % Loop through the inputs specified in the paramsTable
    for jj=nParamCols+1:nInputCols
        
        % Define the input label
        theInputLabel=char(paramsTable{InputsRow,jj});
        % Get the entry for this job and input from the params table
        entry = strsplit(char(paramsTable{ii,jj}),'/');
        % Try to find the session with this subject and session label
        sessionIdx = find(cellfun(@(x) all([strcmp(x.subject.code,entry{1}) strcmp(x.label,entry{2})]),allSessions));
        if isempty(sessionIdx)
            error('No matching session and subject for this input entry')
        end
        if length(sessionIdx)>1
            error('More than one matching session and subject for this input entry')
        end
        % Obtain the set of acquisitions for the matching session
        allAcqs = fw.getSessionAcquisitions(allSessions{sessionIdx}.id);
        % Check to see if there is a custom file label. If not, use the
        % default label
        if length(entry)==3
            targetLabel = entry(3);
        else
            targetLabel = char(paramsTable{DefaultLabelRow,jj});
        end
        % Check if this is a session file, or an acquisition file
        if logical(str2double(char(paramsTable{IsSessionFileRow,jj})))
            % It is a session file (such as a coeff.grad file, or an
            % analysis result). Get the container ID of the session.
            if logical(str2double(char(paramsTable{IsAnalysisFileRow,jj})))
                % It is an analysis output
                allAnalyses=fw.getSessionAnalyses(allSessions{sessionIdx}.id);
                targetLabelParts = strsplit(targetLabel,'/');
                analysisIdx = find(strcmp(cellfun(@(x) x.gearInfo.name,allAnalyses,'UniformOutput',false),targetLabelParts{1}));
                fileIdx = find(cellfun(@(x) (endsWith(x.name,targetLabelParts{2})),allAnalyses{analysisIdx}.files));
                theID = allAnalyses{analysisIdx}.id;
                theName = allAnalyses{analysisIdx}.files{fileIdx}.name;
                theType = 'analysis';
            theAcqLabel = 'analysis_file';
            else
                % It is a session file (like a coeff.grad)
                theID = allSessions{sessionIdx}.id;
                if isempty(allSessions{sessionIdx}.files)
                    error('No session file for this entry (likely missing a coeff.grad file)')
                end
                fileIdx = find(strcmp(cellfun(@(x) x.name,allSessions{sessionIdx}.files,'UniformOutput',false),targetLabel));
                if isempty(fileIdx)
                    error('No matching session file for this entry (likely missing a coeff.grad file)')
                end
                theName = allSessions{sessionIdx}.files{fileIdx}.name;
                theType = 'session';
                theAcqLabel = 'session_file';
            end
            % Check if theInputLabel is the rootSessionInputLabel
            if strcmp(p.Results.rootSessionInputLabel,theInputLabel)
                % Get the root session information. This is the session to
                % which the analysis product will be assigned
                rootSessionID = allSessions{sessionIdx}.id;
                % The root session tag is used to label the outputs of the
                % gear. Sometimes there is leading or trailing white space
                % in the acquisition label. We trim that off here as it can
                % cause troubles in gear execution.
                rootSessionTag = strtrim(theName);
            end            
        else
            % It is an acqusition file. If a file entry was specified, go
            % find that.
            if length(entry)==4
                % We are given the name of the file
                theName = entry{4};
                % Find the acquisition ID
                acqIdx = find(cellfun(@(x) sum(cellfun(@(y) strcmp(y.name,theName),x.files)),allAcqs));
                theID = allAcqs{acqIdx}.id;
                theAcqLabel = allAcqs{acqIdx}.label;
            else
                % Try to find an acquisition that matches the input label
                % and contains a nifti file. Unless told to use exact
                % matching, trim off leading and trailing whitespace, as
                % the stored label in flywheel sometimes has a trailing
                % space. Also, use a case insensitive match.
                if logical(str2double(char(paramsTable{ExactStringMatchRow,jj})))
                    labelMatchIdx = cellfun(@(x) strcmp(x.label,targetLabel),allAcqs);
                else
                    labelMatchIdx = cellfun(@(x) strcmpi(strtrim(x.label),strtrim(targetLabel)),allAcqs);
                end
                isNiftiIdx = cellfun(@(x) any(cellfun(@(y) strcmp(y.type,p.Results.AcqFileType),x.files)),allAcqs);
                acqIdx = logical(labelMatchIdx .* isNiftiIdx);
                if ~any(acqIdx)
                    error('No matching acquisition for this input entry')
                end
                if sum(acqIdx)>1
                    error('More than one matching acquisition for this input entry')
                end
                % We have a match. Re-find the nifti file
                theNiftiIdx = find(cellfun(@(y) strcmp(y.type,p.Results.AcqFileType),allAcqs{acqIdx}.files));
                % Check for an error condition
                if isempty(theNiftiIdx)
                    error('No nifti file for this acquisition');
                end
                if length(theNiftiIdx)>1
                    warning('More than one nifti file for this acquisition; using the most recent');
                    [~,mostRecentIdx]=max(cellfun(@(x) datetime(x.created),allAcqs{acqIdx}.files(theNiftiIdx)));
                    theNiftiIdx=theNiftiIdx(mostRecentIdx);
                end
                % Get the file name, ID, and acquisition label
                theID = allAcqs{acqIdx}.id;
                theName = allAcqs{acqIdx}.files{theNiftiIdx}.name;
                theAcqLabel = allAcqs{acqIdx}.label;
            end
            theType = 'acquisition';
            % Check if theInputLabel is the rootSessionInputLabel
            if strcmp(p.Results.rootSessionInputLabel,theInputLabel)
                % Get the root session information. This is the session to
                % which the analysis product will be assigned
                rootSessionID = allSessions{sessionIdx}.id;
                % The root session tag is used to label the outputs of the
                % gear. Sometimes there is leading or trailing white space
                % in the acquisition label. We trim that off here as it can
                % cause troubles in gear execution.
                rootSessionTag = strtrim(allAcqs{acqIdx}.label);
            end
        end
        % Add this input information to the structure
        inputStem = struct('type', theType,...
            'id', theID, ...
            'name', theName);
        inputs.(theInputLabel) = inputStem;
        acqNotes.(theInputLabel) = theAcqLabel;
    end
    
    % Add the freesurfer license file
    if ~isempty(fsLicFileID)
        inputStem = struct('type', fsLicFileType,...
            'id', fsLicFileID, ...
            'name', fsLicFileName);
        inputs.(fsLicFileLabel) = inputStem;
        acqNotes.(fsLicFileLabel) = 'projectFile';
    end
    
    %% Customize gear configuration
    configKeys = eval(p.Results.configKeys);
    configVals = eval(p.Results.configVals);
    config = configDefault;    
    if ~isempty(configKeys)
        for kk=1:length(configKeys)
            config.(configKeys{kk})=configVals{kk};
        end
    end
    
    %% Assemble Job
    % Create the job body with all the involved files in a struct
    thisJob = struct('gear_id', theGearID, ...
        'inputs', inputs, ...
        'config', config);
    
    
    %% Assemble analysis label
    analysisLabel = [theGearName ' v' theGearVersion ' [' rootSessionTag '] - ' char(datetime('now','TimeZone','local','Format','yyyy-MM-dd HH:mm'))];
    
    
    %% Check if the analysis has already been performed
    skipFlag = false;
    allAnalyses=fw.getSessionAnalyses(rootSessionID);
    if ~isempty(allAnalyses)
        % Check if this gear has been run
        priorAnalysesMatchIdx = cellfun(@(x) strcmp(x.gearInfo.name,theGearName),allAnalyses);
        if any(priorAnalysesMatchIdx)
            % See if the data tag in any of the prior analyses is a match
            % Ignore white space in the label parts
            for mm=1:length(allAnalyses)
                analysisLabelParts = strsplit(allAnalyses{mm}.label,{'[',']'});
                if length(analysisLabelParts)>1
                    if strcmp(strtrim(analysisLabelParts{2}),strtrim(rootSessionTag))
                        skipFlag = true;
                        priorAnalysisID = allAnalyses{mm}.id;
                    end
                end
            end
        end
    end
    if skipFlag
        if verbose
            fprintf(['The analysis ' theGearName ' is already present for ' subjectName ', ' rootSessionTag '; skipping.\n']);
            % This command may be used to delete the prior analysis
            %{
                fw.deleteSessionAnalysis(allSessions{sessionIdx}.id,priorAnalysisID);
            %}
        end
        continue
    end
    
    %% Run
    body = struct('label', analysisLabel, 'job', thisJob);
    [newAnalysisID, ~] = fw.addSessionAnalysis(rootSessionID, body);
    
    
    %% Add a notes entry to the analysis object
    note = ['InputLabel  -+-  AcquisitionLabel  -+-  FileName\n' ...
            '-------------|----------------------|-----------\n'];
    inputFieldNames = fieldnames(inputs);
    for nn = 1:numel(inputFieldNames)
        newLine = [inputFieldNames{nn} '  -+-  ' acqNotes.(inputFieldNames{nn}) '  -+-  ' inputs.(inputFieldNames{nn}).name '\n'];
        note = [note newLine];
    end
    fw.addAnalysisNote(newAnalysisID,sprintf(note));
    
    %% Report the event
    if verbose
        fprintf(['Submitted ' subjectName ' [' newAnalysisID '] - ' analysisLabel '\n']);
    end
end



