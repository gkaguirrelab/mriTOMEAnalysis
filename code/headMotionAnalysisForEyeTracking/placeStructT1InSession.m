% placeStructT1InSession
%
% The hcp-struct gear produces several outputs that are stored within a zip
% file. The purpose of this routine is to extract a particular anatomical
% image (the T1w_acpc_dc_restore.nii.gz) from that zip file, and then save
% the image as an attachment at the session level. The reason for this is
% that visual inspection of the anatomical image is needed for a subsequent
% step (analysis of eye movement), and it is easier to do so when this file
% is available as a session attachment.
%

% The file in question:
targetFile = 'T1w_acpc_dc_restore.nii.gz';

% Instantiate the Flywheel object
fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));

% Obtain all of the HCP-struct analyses in the TOME project
searchStruct = struct(...
    'returnType', 'file', ...
    'filters', {{ ...
    struct('wildcard', struct('analysis0x2elabel', '*hcp-struct*')), ...
    struct('match', struct('project0x2elabel', 'tome')), ...
    }} ...
    );
analyses = fw.search(searchStruct, 'size', 1000);

% Loop through the identified analyses and make sure that it has the
% analysis output that we need
for ii = 1:numel(analyses)    
    if ~strcmp(analyses{ii}.file.name, [analyses{ii}.subject.code, '_hcpstruct.zip'])
        analyses{ii} = [];
    end
end

% Clean up the list
analyses = analyses(~cellfun('isempty', analyses));
numberOfSessions = size(analyses,1);

% Identify the scratch dir
dataDownloadDir = getpref('flywheelMRSupport','flywheelScratchDir');

% Loop through the sessions
for ss = 1:numberOfSessions

    % The ID and subject for this session
    session_id = analyses{ss}.session.id;
    subject = analyses{ss}.subject.code;

    % Check first to see if the session already has this attachment
    sessionFiles = fw.getSession(session_id).files;
    if ~isempty(sessionFiles)
        if any(cellfun(@(x) strcmp(x.name,targetFile),sessionFiles))
            fprintf(['The file ' targetFile ' is already present for ' subject '; skipping.\n']);
            continue
        end
    end
    
    % Get the rest of the session info
    file_name = analyses{ss}.file.name;
    analysis_id = analyses{ss}.analysis.id;
    output_name = fullfile(dataDownloadDir, file_name);

    % Report the upcoming action to the console
    fprintf(['Downloading hcp-struct for ' subject '...']);

    % Download the hcp-struct zip file
    fw.downloadOutputFromAnalysis(analysis_id, file_name, fullfile(dataDownloadDir, file_name));

    % Unzip it
    [~,~,ext] = fileparts(file_name);
    unzipDir = fullfile(dataDownloadDir,[subject '_' analysis_id]);    
    if (~exist(unzipDir,'dir'))
        mkdir(unzipDir);
    end
    system(['unzip -o ' output_name ' -d ' unzipDir '> /dev/null']);
    delete(output_name);
    
    % Find the file and put it up on Flywheel
    fileToUpload = fullfile(unzipDir, subject, 'T1w', targetFile);
    fw.uploadFileToSession(session_id,fileToUpload);

    % Clean up the downloaded files
    rmdir(unzipDir, 's');

    % Report the action to the console
    fprintf([ targetFile ' has been uploaded.\n']);
    
end


