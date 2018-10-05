

%% Fixed variable definition
projectName = 'tome';
freesurferLicenseFileName = 'freesurfer_license.txt';
fileType = 'nifti';
gearName = 'hcp-struct';
rootSessionInputLabel = 'T1';
paramsFileName = 'tomeHCPStructuralParams.csv';
verbose = true;

%% Load the params table
% This identifies the subjects and inputs to be processed
paramsTable = readtable(paramsFileName);
nParamColumns = 3;
nJobs = size(paramsTable,2)-nParamColumns;
nInputs = size(paramsTable,1);


%% Instantiate the flywheel object
fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));


%% Get project ID and sessions
allProjects = fw.getAllProjects;
projIdx = find(strcmp(cellfun(@(x) x.label,allProjects,'UniformOutput',false),projectName),1);
projID = allProjects{projIdx}.id;
allSessions = fw.getProjectSessions(projID);


%% Identify the freesurfer license file
fsLicFileIdx = find(strcmp(cellfun(@(x) x.name,allProjects{projIdx}.files,'UniformOutput',false),freesurferLicenseFileName));
fsLicFileName = allProjects{projIdx}.files{fsLicFileIdx}.name;
fsLicFileID = allProjects{projIdx}.id;
fsLicFileType = 'project';
fsLicFileLabel = 'FreeSurferLicense';


%% Construct the gear configuration
% Get all the gears
allGears = fw.getAllGears();

% Find the particular gear we are going to use
theGearIdx=find(strcmp(cellfun(@(x) x.gear.name,allGears,'UniformOutput',false),gearName));
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
    fprintf('No default value for %s\n. It must be set prior to execution.', keys{i});
  end
end


%% Loop through jobs
for jj=1:nJobs

    
    %% Assemble Inputs
    % Create an empty inputs struct
    inputs = struct();
    
    % Loop through the inputs specified in the paramsTable
    for ii=1:size(paramsTable,1)
        
        % Define the input label
        theInputLabel=char(paramsTable{ii,1});
        % Get the entry for this job and input from the params table
        entry = strsplit(char(paramsTable{ii,jj+nParamColumns}),'/');
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
            targetLabel = char(paramsTable{ii,2});
        end
        % Check if this is a session file, or an acquisition file
        if logical(paramsTable{ii,3})
            % It is a session file (such as a coeff.grad file). See if the
            % target file is there.
            acqIdx = find(strcmp(cellfun(@(x) x.name,allSessions{sessionIdx}.files,'UniformOutput',false),targetLabel));
            theID = allSessions{sessionIdx}.id;
            theName = allSessions{sessionIdx}.files{acqIdx}.name;
            theType = 'session';
        else
            % It is an acqusition file. Try to find an acquisition that
            % matches the input label and contains a nifti file. We use
            % strfind instead of strcmp, as the stored label in flywheel
            % sometimes has a trailing space.
            labelMatchIdx = cellfun(@(x) ~isempty(x),strfind(cellfun(@(x) x.label,allAcqs,'UniformOutput',false),targetLabel));
            isNiftiIdx = cellfun(@(x) any(cellfun(@(y) strcmp(y.type,'nifti'),x.files)),allAcqs);
            acqIdx = logical(labelMatchIdx .* isNiftiIdx);
            if ~any(acqIdx)
                error('No matching acquisition for this input entry')
            end
            if sum(acqIdx)>1
                error('More than one matching acquisition for this input entry')
            end
            % We have a match. Re-find the nifti file
            theNiftiIdx = find(cellfun(@(y) strcmp(y.type,'nifti'),allAcqs{acqIdx}.files));
            % Get the name and ID
            theID = allAcqs{acqIdx}.id;
            theName = allAcqs{acqIdx}.files{theNiftiIdx}.name;
            theType = 'acquisition';
            % Check if theInputLabel is the rootSessionInputLabel
            if strcmp(rootSessionInputLabel,theInputLabel)
                % Get the root session information. This is the session to
                % which the analysis product will be assigned
                rootSessionID = allSessions{sessionIdx}.id;
            end
        end
        % Add this input information to the structure
        inputStem = struct('type', theType,...
                  'id', theID, ...
                  'name', theName);
        inputs.(theInputLabel) = inputStem;
    end

    % Add the freesurfer license file
    inputStem = struct('type', fsLicFileType,...
        'id', fsLicFileID, ...
        'name', fsLicFileName);
    inputs.(fsLicFileLabel) = inputStem;

        
    %% Customize gear configuration with this subject name
    config = configDefault;
    subjectName = char(paramsTable.Properties.VariableNames{jj+nParamColumns});
    config.Subject = subjectName;
    config.RegName = 'FS';

    
    %% Assemble Job
    % Create the job body with all the involved files in a struct
    thisJob = struct('gear_id', theGearID, ...
        'inputs', inputs, ...
        'config', config);

    
    %% Assemble analysis label
    analysisLabel = [theGearName ' v' theGearVersion ' - ' char(datetime('now','TimeZone','local','Format','dd/MM/yyyy HH:mm:ss'))];

    
    %% Check if the analysis has already been performed
    allAnalyses=fw.getSessionAnalyses(rootSessionID);
    if ~isempty(allAnalyses)
        if any(cellfun(@(x) strcmp(x.gearInfo.name,theGearName),allAnalyses))
            if verbose
                fprintf(['The analysis ' theGearName ' is already present for ' subjectName '; skipping.\n']);
            end
            continue
        end
    end
    
    %% Run
    body = struct('label', analysisLabel, 'job', thisJob);
    [returnData, resp] = fw.addSessionAnalysis(rootSessionID, body);
    foo=1;
end



