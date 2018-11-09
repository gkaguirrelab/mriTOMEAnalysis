function getSubjectData(subjectID, runName, varargin)

%% input parser
p = inputParser; p.KeepUnmatched = true;
p.addParameter('dataDownloadDir', '~/Desktop/temp', @isstring);
%p.addParameter('dataDownloadDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/temp'), @isstring);
p.addParameter('paramsFileName','analysesLabels.csv', @ischar);
p.addParameter('anatDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);
p.addParameter('functionalDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID),  @isstring);
p.addParameter('pupilDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID),  @isstring);
p.addParameter('pupilProcessingDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_processingPath')),  @isstring);

p.parse(varargin{:});

fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));

if (~exist(p.Results.dataDownloadDir,'dir'))
    mkdir(p.Results.dataDownloadDir);
end

%% Get physio
if ~exist(fullfile(p.Results.functionalDir, [runName, '_puls.mat']))
    fprintf('Downloading physio file.\n');

    if (~exist(p.Results.functionalDir,'dir'))
        mkdir(p.Results.functionalDir);
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
    dataDownloadDir = p.Results.dataDownloadDir;
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
    
    copyfile(fullfile(dataDownloadDir, file_name), fullfile(p.Results.functionalDir, [runName, '_puls.mat']));
    
    delete(fullfile(dataDownloadDir, file_name));
else
    fprintf('Physio file found. Skipping downloading.\n');

end

%% Get pupil data
% we want the timebase and the pupil file
if strcmp(runName(1), 't')
    splitRunName = strsplit(runName, 'run');
    runNumber = str2num(splitRunName{end});
    pupilFileNameBase = [splitRunName{1}, 'run', sprintf('%02d', runNumber)];
    pupilFileName = [pupilFileNameBase, '_pupil.mat'];
    targetPupilFileName = [splitRunName{1}, 'run', num2str(runNumber), '_pupil.mat'];
    pupilTimebaseName = [pupilFileNameBase, '_timebase.mat'];
    targetTimebaseName = [splitRunName{1}, 'run', num2str(runNumber), '_timebase.mat'];
elseif strcmp(runName(1), 'r')
    splitRunName = strsplit(runName, 'Run');
    runNumber = str2num(splitRunName{end});
    pupilFileNameBase = [splitRunName{1}, 'run', sprintf('%02d', runNumber)];
    pupilFileName = [pupilFileNameBase, '_pupil.mat'];
    targetPupilFileName = [splitRunName{1}, 'Run', num2str(runNumber), '_pupil.mat'];
    pupilTimebaseName = [pupilFileNameBase, '_timebase.mat'];
    targetTimebaseName = [splitRunName{1}, 'Run', num2str(runNumber), '_timebase.mat'];
end

if ~exist(fullfile(p.Results.pupilDir, targetPupilFileName)) || ~exist(fullfile(p.Results.pupilDir, targetTimebaseName))
    if (~exist(p.Results.pupilDir,'dir'))
        mkdir(p.Results.pupilDir);
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
    
    pupilFile = fullfile(p.Results.pupilProcessingDir, sessionName, subjectID, dateString, 'EyeTracking', pupilFileName);
    timebaseFile = fullfile(p.Results.pupilProcessingDir, sessionName, subjectID, dateString, 'EyeTracking', pupilTimebaseName);
    
    copyfile(pupilFile, fullfile(p.Results.pupilDir, targetPupilFileName));
    copyfile(timebaseFile, fullfile(p.Results.pupilDir, targetTimebaseName));
else
    fprintf('Pupil files found. Skipping downloading.\n');

end



%% Get structural stuff first
destinationOfStructuralScan = fullfile(p.Results.anatDir, 'T1w_acpc_dc_restore.nii.gz');
destinationOfRegistrationInfo = fullfile(p.Results.anatDir, 'standard2acpc_dc.nii.gz');

if ~exist(destinationOfStructuralScan) || ~exist(destinationOfRegistrationInfo)
    fprintf('Downloading structural scans.\n');

    
    if (~exist(p.Results.anatDir,'dir'))
        mkdir(p.Results.anatDir);
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
    dataDownloadDir = p.Results.dataDownloadDir;
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


%% Get functional data
destinationOfFunctionalScan = fullfile(p.Results.functionalDir, [runName, '_mni.nii.gz']);
destinationOfMovementRegressors = fullfile(p.Results.functionalDir, [runName, '_Movement_Regressors.txt']);

if ~exist(destinationOfFunctionalScan) || ~exist(destinationOfMovementRegressors)
    
    
    if (~exist(p.Results.functionalDir,'dir'))
        mkdir(p.Results.functionalDir);
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
    dataDownloadDir = p.Results.dataDownloadDir;
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



%% Get the Benson gear output

if ~exist(fullfile(p.Results.anatDir, [subjectID, '_lh.ribbon.nii.gz'])) ||  ~exist(fullfile(p.Results.anatDir, [subjectID, '_rh.ribbon.nii.gz'])) || ~exist(fullfile(p.Results.anatDir, [subjectID, '_native.template_eccen.nii.gz'])) || ~exist(fullfile(p.Results.anatDir, [subjectID, '_native.template_angle.nii.gz'])) || ~exist(fullfile(p.Results.anatDir, [subjectID, '_native.template_areas.nii.gz']))
    if (~exist(p.Results.anatDir,'dir'))
        mkdir(p.Results.anatDir);
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
        end
    end
    
    analysesWeWant = analysesWeWant(~cellfun('isempty', analysesWeWant));
    analyses = analysesWeWant;
    
    for ii = 1:length(analyses)
        file_name = analyses{ii}.file.name;
        analysis_id = analyses{ii}.analysis.id;
        session_id = analyses{ii}.session.id;
        dataDownloadDir = p.Results.dataDownloadDir;
        output_name = fullfile(dataDownloadDir, file_name);
        
        % flywheel gets angry when we search for something with spaces
        file_name = strrep(file_name, ' ', '%20');
        fw.downloadOutputFromAnalysis(analysis_id, file_name, fullfile(dataDownloadDir, file_name));
        
        
        copyfile(fullfile(dataDownloadDir, file_name), fullfile(p.Results.anatDir, file_name));
        
        
        
        delete(fullfile(dataDownloadDir, file_name));
    end
end


end

