function getSubjectData(subjectID, runName, varargin)
% Downloads the relevant files for fMRI analysis from FlyWheel
%
% Syntax:
%  getSubjectData(subjectID, runName)
%
% Description:
%  On the basis of the inputted subject and runName, this routine searches
%  for the relevant files off of FlyWheel and downloads them locally. This
%  routine broadly downloads structural files, functional files, physio
%  data, pupil data (which is stored on Dropbox, and not FlyWheel), and
%  retintopy output from the Benson gear. More specifically, structural
%  files include the structural T1 anatomical image as well as the
%  registration information that brings this image from MNI space to ACPC.
%  Functional files include the functional volume of interest, as well as
%  its associated motion parameters.
%
% Inputs:
%  subjectID:           - a string that identifies the relevant subject (i.e.
%                         'TOME_3040'
%  runName:             - a string that identifies the relevant run (i.e.
%                         'rfMRI_REST_AP_Run3')
%
% Optional key-value pairs:
%  downloadOnly         - a string that determines which files to download.
%                         The default is set to all, which instructs the
%                         code to download all files. Other options include
%                         'pupil' to just download the pupil data from
%                         Dropbox. Note that other options will be added in
%                         the future.
%
% Outputs:
%  None. The downloaded data files, however, are ultimately saved onto
%  Dropbox.

%% input parser
p = inputParser; p.KeepUnmatched = true;
p.addParameter('downloadOnly', 'all', @ischar);
p.parse(varargin{:});

%% Define paths
[ paths ] = definePaths(subjectID);
freeSurferDir = paths.freeSurferDir;
anatDir = paths.anatDir;
pupilDir = paths.pupilDir;
functionalDir = paths.functionalDir;
outputDir = paths.outputDir;
pupilProcessingDir = paths.pupilProcessingDir;
dataDownloadDir = paths.dataDownloadDir;


%% Figure out what we're downloading
if strcmp(p.Results.downloadOnly, 'all')
    downloadPhysio = true;
    downloadPupil = true;
    downloadFunctional = true;
    downloadStructural = true;
    downloadBenson = true;
elseif strcmp(p.Results.downloadOnly, 'pupil')
    downloadPhysio = false;
    downloadPupil = true;
    downloadFunctional = false;
    downloadStructural = false;
    downloadBenson = false;
end

fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));

if (~exist(dataDownloadDir,'dir'))
    mkdir(dataDownloadDir);
end

%% Get physio
if (downloadPhysio)
if ~exist(fullfile(functionalDir, [runName, '_puls.mat']))
    fprintf('Downloading physio file.\n');
    
    if (~exist(functionalDir,'dir'))
        mkdir(functionalDir);
    end
    searchCategory = 'acquisition0x2elabel';
    searchStruct = struct('returnType', 'file', ...
        'filters', {{struct('term', ...
        struct(searchCategory,runName))}});
    analyses = [];
    analyses = fw.search(searchStruct, 'size', '10000');
    
    for ii = 1:numel(analyses)
        
        if ~strcmp(analyses{ii}.subject.code, subjectID) || ~contains(analyses{ii}.file.name, ['_puls.mat'])
            analyses{ii} = [];
        end
    end
    
    if ~isempty([analyses{:}])
        flywheelRunName = runName;
        analyses = analyses(~cellfun('isempty', analyses));
    end
    
    if length((analyses)) == 0
        flyWheelRunName = [runName,' '];
        searchStruct = struct('returnType', 'file', ...
            'filters', {{struct('term', ...
            struct(searchCategory,flyWheelRunName))}});
        analyses = [];
        analyses = fw.search(searchStruct, 'size', '10000');
        
        for ii = 1:numel(analyses)
            
            if ~strcmp(analyses{ii}.subject.code, subjectID) || ~contains(analyses{ii}.file.name, [' _puls.mat'])
                analyses{ii} = [];
            end
        end
        
        analyses = analyses(~cellfun('isempty', analyses));
        
    end
    
    % if length((analyses)) == 0
    %     runNameRoot_split = strsplit(runName, '_');
    %     runNameRoot = [runNameRoot_split{1}, '_', runNameRoot_split{2}, '_', runNameRoot_split{3}];
    %     weirdPhysioName = [runNameRoot, ' puls.mat'];
    %
    %     searchStruct = struct('returnType', 'file', ...
    %         'filters', {{struct('term', ...
    %         struct(searchCategory,weirdPhysioName))}});
    %     analyses = [];
    %     analyses = fw.search(searchStruct, 'size', '10000');
    %
    %     for ii = 1:numel(analyses)
    %
    %         if ~strcmp(analyses{ii}.subject.code, subjectID) || ~strcmp(analyses{ii}.file.name, [runName, ' _puls.mat'])
    %             analyses{ii} = [];
    %         end
    %     end
    %
    %     analyses = analyses(~cellfun('isempty', analyses));
    % end
    %
    
    
    
    
    
    file_name = analyses{1}.file.name;
    analysis_id = analyses{1}.analysis.id;
    session_id = analyses{1}.session.id;
    dataDownloadDir = dataDownloadDir;
    output_name = fullfile(dataDownloadDir, file_name);
    
    
    
    allProjects = fw.getAllProjects;
    for proj = 1:numel(allProjects)
        if strcmp(allProjects{proj}.label,'tome')
            projID = allProjects{proj}.id;
        end
    end
    allSessions = fw.getProjectSessions(projID);
    for session = 1:numel(allSessions)
        if ~strcmp(allSessions{session}.subject.code, subjectID)
            allSessions{session} = [];
        end
        
    end
    allSessions = allSessions(~cellfun('isempty', allSessions));
    for session = 1:numel(allSessions)
        sesID = allSessions{session}.id;
        allAcqs = [];
        allAcqs = fw.getSessionAcquisitions(sesID);
        for acqs = 1:numel(allAcqs)
            
            if strcmp(allAcqs{acqs}.label, flywheelRunName)
                acqs;
                acquisition_id = allAcqs{acqs}.id;
            end
        end
    end
    [ acqToUpload ] = fw.getAcquisition(acquisition_id);
    file_name = strrep(file_name, ' ', '%20');
    fw.downloadFileFromAcquisition(acquisition_id, file_name, fullfile(dataDownloadDir, file_name));
    
    copyfile(fullfile(dataDownloadDir, file_name), fullfile(functionalDir, [runName, '_puls.mat']));
    
    delete(fullfile(dataDownloadDir, file_name));
else
    fprintf('Physio file found. Skipping downloading.\n');
    
end
end

%% Get pupil data
% we want the timebase and the pupil file
if (downloadPupil)
if strcmp(runName(1), 't')
    splitRunName = strsplit(runName, 'run');
    runNumber = str2num(splitRunName{end});
    pupilFileNameBase = [splitRunName{1}, 'run', sprintf('%02d', runNumber)];
    pupilFileName = [pupilFileNameBase, '_pupil.mat'];
    controlFileName = [pupilFileNameBase, '_controlFile.csv'];
    targetControlFileName = [splitRunName{1}, 'run', num2str(runNumber), '_controlFile.csv'];
    targetPupilFileName = [splitRunName{1}, 'run', num2str(runNumber), '_pupil.mat'];
    pupilTimebaseName = [pupilFileNameBase, '_timebase.mat'];
    targetTimebaseName = [splitRunName{1}, 'run', num2str(runNumber), '_timebase.mat'];
elseif strcmp(runName(1), 'r')
    splitRunName = strsplit(runName, 'Run');
    runNumber = str2num(splitRunName{end});
    pupilFileNameBase = [splitRunName{1}, 'run', sprintf('%02d', runNumber)];
    pupilFileName = [pupilFileNameBase, '_pupil.mat'];
    targetPupilFileName = [splitRunName{1}, 'Run', num2str(runNumber), '_pupil.mat'];
    controlFileName = [pupilFileNameBase, '_controlFile.csv'];
    targetControlFileName = [splitRunName{1}, 'Run', num2str(runNumber), '_controlFile.csv'];
    pupilTimebaseName = [pupilFileNameBase, '_timebase.mat'];
    targetTimebaseName = [splitRunName{1}, 'Run', num2str(runNumber), '_timebase.mat'];
end

if (~exist(pupilDir,'dir'))
    mkdir(pupilDir);
end
fprintf('Downloading pupil data.\n');

% one annoying wrinkle is that the run number associated with the pupil
% file has a leading zero. let's get ready for that


% figure out the date and session of this run
searchStruct = struct(...
    'returnType', 'file', ...
    'filters', {{ ...
    struct('wildcard', struct('analysis0x2elabel', ['*hcp-func*'])), ...
    struct('match', struct('project0x2elabel', 'tome')), ...
    }} ...
    );
analyses = [];
analyses = fw.search(searchStruct, 'size', '10000');

for ii = 1:numel(analyses)
    
    if ~strcmp(analyses{ii}.subject.code, subjectID) || ~strcmp(analyses{ii}.file.name, [analyses{ii}.subject.code, '_', runName, '_hcpfunc.zip'])
        analyses{ii} = [];
    end
end

analyses = analyses(~cellfun('isempty', analyses));

if strcmp(analyses{1}.session.label, 'Session 1') || strcmp(analyses{1}.session.label, 'Session 1a') || strcmp(analyses{1}.session.label, 'Session 1b')
    sessionName = 'session1_restAndStructure';
elseif  strcmp(analyses{1}.session.label, 'Session 2')
    sessionName = 'session2_spatialStimuli';
end

sessionDate = NaT(1,'TimeZone','America/New_York');
sessionDate = analyses{1}.session.timestamp;
formatOut = 'mmddyy';
dateString = datestr(sessionDate(1),formatOut);

pupilFile = fullfile(pupilProcessingDir, sessionName, subjectID, dateString, 'EyeTracking', pupilFileName);
timebaseFile = fullfile(pupilProcessingDir, sessionName, subjectID, dateString, 'EyeTracking', pupilTimebaseName);
controlFile = fullfile(pupilProcessingDir, sessionName, subjectID, dateString, 'EyeTracking', controlFileName);

copyfile(pupilFile, fullfile(pupilDir, targetPupilFileName));
copyfile(controlFile, fullfile(pupilDir, targetControlFileName));
copyfile(timebaseFile, fullfile(pupilDir, targetTimebaseName));



end
%% Get structural stuff first
if (downloadStructural)
destinationOfStructuralScan = fullfileanatDir, 'T1w_acpc_dc_restore.nii.gz');
destinationOfRegistrationInfo = fullfile(anatDir, 'standard2acpc_dc.nii.gz');

if ~exist(destinationOfStructuralScan) || ~exist(destinationOfRegistrationInfo)
    fprintf('Downloading structural scans.\n');
    
    
    if (~exist(anatDir,'dir'))
        mkdir(anatDir);
    end
    searchStruct = struct(...
        'returnType', 'file', ...
        'filters', {{ ...
        struct('wildcard', struct('analysis0x2elabel', '*hcp-struct*')), ...
        struct('match', struct('project0x2elabel', 'tome')), ...
        }} ...
        );
    analyses = [];
    analyses = fw.search(searchStruct, 'size', '1000');
    
    for ii = 1:numel(analyses)
        
        if ~strcmp(analyses{ii}.subject.code, subjectID) || ~strcmp(analyses{ii}.file.name, [analyses{ii}.subject.code, '_hcpstruct.zip'])
            analyses{ii} = [];
        end
    end
    
    analyses = analyses(~cellfun('isempty', analyses));
    
    file_name = analyses{1}.file.name;
    analysis_id = analyses{1}.analysis.id;
    session_id = analyses{1}.session.id;
    output_name = fullfile(dataDownloadDir, file_name);
    
    % flywheel gets angry when we search for something with spaces
    file_name = strrep(file_name, ' ', '%20');
    fw.downloadOutputFromAnalysis(analysis_id, file_name, fullfile(dataDownloadDir, file_name));
    
    [~,~,ext] = fileparts(file_name);
    unzipDir = fullfile(dataDownloadDir,[subjectID '_' analysis_id]);
    
    if (~exist(unzipDir,'dir'))
        mkdir(unzipDir);
    end
    system(['unzip -o ' output_name ' -d ' unzipDir]);
    delete(output_name);
    
    % get structural scan
    structuralScan = fullfile(unzipDir, subjectID, 'T1w', 'T1w_acpc_dc_restore.nii.gz');
    copyfile(structuralScan, destinationOfStructuralScan);
    
    % get registration information to bring functional back to native space
    registrationInfo = fullfile(unzipDir, subjectID, 'MNINonLinear', 'xfms', 'standard2acpc_dc.nii.gz');
    copyfile(registrationInfo, destinationOfRegistrationInfo);
    
    rmdir(unzipDir, 's');
else
    fprintf('Structural scans found. Skipping downloading.\n');
    
end
end

%% Get functional data
if (downloadFunctional)
destinationOfFunctionalScan = fullfile(functionalDir, [runName, '_mni.nii.gz']);
destinationOfMovementRegressors = fullfile(functionalDir, [runName, '_Movement_Regressors.txt']);

if ~exist(destinationOfFunctionalScan) || ~exist(destinationOfMovementRegressors)
    
    
    if (~exist(functionalDir,'dir'))
        mkdir(functionalDir);
    end
    searchStruct = struct(...
        'returnType', 'file', ...
        'filters', {{ ...
        struct('wildcard', struct('analysis0x2elabel', ['*hcp-func*'])), ...
        struct('match', struct('project0x2elabel', 'tome')), ...
        }} ...
        );
    analyses = [];
    analyses = fw.search(searchStruct, 'size', '10000');
    
    for ii = 1:numel(analyses)
        
        if ~strcmp(analyses{ii}.subject.code, subjectID) || ~strcmp(analyses{ii}.file.name, [analyses{ii}.subject.code, '_', runName, '_hcpfunc.zip'])
            analyses{ii} = [];
        end
    end
    
    analyses = analyses(~cellfun('isempty', analyses));
    
    file_name = analyses{1}.file.name;
    analysis_id = analyses{1}.analysis.id;
    session_id = analyses{1}.session.id;
    output_name = fullfile(dataDownloadDir, file_name);
    
    fw.downloadOutputFromAnalysis(analysis_id, file_name, fullfile(dataDownloadDir, file_name));
    
    [~,~,ext] = fileparts(file_name);
    unzipDir = fullfile(dataDownloadDir,[subjectID '_' analysis_id]);
    
    if (~exist(unzipDir,'dir'))
        mkdir(unzipDir);
    end
    system(['unzip -o ' output_name ' -d ' unzipDir]);
    delete(output_name);
    
    % get functional scan
    functionalScan = fullfile(unzipDir, subjectID, 'MNINonLinear', 'Results', runName, [runName, '.nii.gz']);
    copyfile(functionalScan, destinationOfFunctionalScan);
    
    % get movement regressors
    movementRegressors = fullfile(unzipDir, subjectID, runName, 'Movement_Regressors.txt');
    copyfile(movementRegressors, destinationOfMovementRegressors);
    
    rmdir(unzipDir, 's');
end


end
%% Get the Benson gear output
if (downloadBenson)
if ~exist(fullfile(anatDir, [subjectID, '_lh.ribbon.nii.gz'])) ||  ~exist(fullfile(anatDir, [subjectID, '_rh.ribbon.nii.gz'])) || ~exist(fullfile(anatDir, [subjectID, '_native.template_eccen.nii.gz'])) || ~exist(fullfile(anatDir, [subjectID, '_native.template_angle.nii.gz'])) || ~exist(fullfile(anatDir, [subjectID, '_native.template_areas.nii.gz'])) || ~exist(fullfile(anatDir, [subjectID, '_aparc+aseg.nii.gz']))
    if (~exist(anatDir,'dir'))
        mkdir(anatDir);
    end
    searchStruct = struct(...
        'returnType', 'file', ...
        'filters', {{ ...
        struct('wildcard', struct('analysis0x2elabel', 'retinotopy-templates*')), ...
        struct('match', struct('project0x2elabel', 'tome')), ...
        }} ...
        );
    analyses = [];
    analyses = fw.search(searchStruct, 'size', '10000');
    
    for ii = 1:numel(analyses)
        
        if ~strcmp(analyses{ii}.subject.code, subjectID)
            analyses{ii} = [];
        end
    end
    analyses = analyses(~cellfun('isempty', analyses));
    
    analysesWeWant = [];
    for ii = 1:numel(analyses)
        if strcmp(analyses{ii}.file.name, [analyses{ii}.subject.code, '_lh.ribbon.nii.gz'])
            analysesWeWant{ii} = analyses{ii};
        elseif strcmp(analyses{ii}.file.name, [analyses{ii}.subject.code, '_rh.ribbon.nii.gz'])
            analysesWeWant{ii} = analyses{ii};
        elseif strcmp(analyses{ii}.file.name, [analyses{ii}.subject.code, '_native.template_eccen.nii.gz'])
            analysesWeWant{ii} = analyses{ii};
        elseif strcmp(analyses{ii}.file.name, [analyses{ii}.subject.code, '_native.template_angle.nii.gz'])
            analysesWeWant{ii} = analyses{ii};
        elseif strcmp(analyses{ii}.file.name, [analyses{ii}.subject.code, '_native.template_areas.nii.gz'])
            analysesWeWant{ii} = analyses{ii};
        elseif strcmp(analyses{ii}.file.name, [analyses{ii}.subject.code, '_aparc+aseg.nii.gz'])
            analysesWeWant{ii} = analyses{ii};
        end
    end
    
    analysesWeWant = analysesWeWant(~cellfun('isempty', analysesWeWant));
    analyses = analysesWeWant;
    
    for ii = 1:length(analyses)
        file_name = analyses{ii}.file.name;
        analysis_id = analyses{ii}.analysis.id;
        session_id = analyses{ii}.session.id;
        output_name = fullfile(dataDownloadDir, file_name);
        
        % flywheel gets angry when we search for something with spaces
        file_name = strrep(file_name, ' ', '%20');
        fw.downloadOutputFromAnalysis(analysis_id, file_name, fullfile(dataDownloadDir, file_name));
        
        
        copyfile(fullfile(dataDownloadDir, file_name), fullfile(anatDir, file_name));
        
        
        
        delete(fullfile(dataDownloadDir, file_name));
    end
end
end

end

