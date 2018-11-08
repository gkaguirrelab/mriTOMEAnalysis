function getSubjectData(subjectID, runName, varargin)

%% input parser
p = inputParser; p.KeepUnmatched = true;
p.addParameter('dataDownloadDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/temp'), @isstring);
p.addParameter('paramsFileName','analysesLabels.csv', @ischar);
p.addParameter('anatDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);
p.addParameter('functionalDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID),  @isstring);
p.parse(varargin{:});

fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));


%% Get structural stuff first
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
destinationOfStructuralScan = fullfile(p.Results.anatDir, 'T1w_acpc_dc_restore.nii.gz');
copyfile(structuralScan, destinationOfStructuralScan);

% get registration information to bring functional back to native space
registrationInfo = fullfile(unzipDir, subjectID, 'MNINonLinear', 'xfms', 'standard2acpc_dc.nii.gz');
destinationOfRegistrationInfo = fullfile(p.Results.anatDir, 'standard2acpc_dc.nii.gz');
copyfile(registrationInfo, destinationOfRegistrationInfo);

rmdir(unzipDir, 's');


%% Get functional data
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

% get structural scan
functionalScan = fullfile(unzipDir, subjectID, 'MNINonLinear', 'Results', runName, [runName, '.nii.gz']);
destinationOfFunctionalScan = fullfile(p.Results.functionalDir, [runName, '_mni.nii.gz']);
copyfile(functionalScan, destinationOfFunctionalScan);

% get movement regressors
movementRegressors = fullfile(unzipDir, subjectID, runName, 'Movement_Regressors.txt');
destinationOfMovementRegressors = fullfile(p.Results.functionalDir, [subjectID, '_Movement_Regressors.txt']);
copyfile(movementRegressors, destinationOfMovementRegressors);

rmdir(unzipDir, 's');

%% Get physio

searchCategory = 'acquisition0x2elabel';
searchStruct = struct('returnType', 'file', ...
    'filters', {{struct('term', ...
    struct(searchCategory,runName))}});
analyses = [];
analyses = fw.search(searchStruct, 'size', '10000');

for ii = 1:numel(analyses)
    
    if ~strcmp(analyses{ii}.subject.code, subjectID) %|| ~strcmp(analyses{ii}.file.name, [runName, '_puls.mat'])
        analyses{ii} = [];
    end
end

analyses = analyses(~cellfun('isempty', analyses));

if length(analyses) == 0
    searchStruct = struct('returnType', 'file', ...
        'filters', {{struct('term', ...
        struct(searchCategory,[runName,' ']))}});
    analyses = [];
    analyses = fw.search(searchStruct, 'size', '10000');
    
    for ii = 1:numel(analyses)
        
        if ~strcmp(analyses{ii}.subject.code, subjectID) || ~strcmp(analyses{ii}.file.name, [runName, ' _puls.mat'])
            analyses{ii} = [];
        end
    end
    
    analyses = analyses(~cellfun('isempty', analyses));
end


    



file_name = analyses{1}.file.name;
analysis_id = analyses{1}.analysis.id;
session_id = analyses{1}.session.id;
dataDownloadDir = p.Results.dataDownloadDir;
output_name = fullfile(dataDownloadDir, file_name);
flywheelRunName = strsplit(file_name, '_puls.mat');
flywheelRunName = flywheelRunName{1};


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
    allAcqs = fw.getSessionAcquisitions(sesID);
    for acqs = 1:numel(allAcqs)
        allAcqs{acqs}.label
        if strcmp(allAcqs{acqs}.label, flywheelRunName)
            acquisition_id = allAcqs{acqs}.id;
        end
    end
end
[ acqToUpload ] = fw.getAcquisition(acquisition_id);

fw.downloadFileFromAcquisition(acquisition_id, file_name, fullfile(dataDownloadDir, file_name));

copyfile(fullfile(dataDownloadDir, file_name), fullfile(p.Results.functionalDir, [runName, '_puls.mat']));

delete(fullfile(dataDownloadDir, file_name));



end

