%% identify all HCP-struct sessions
fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));

searchStruct = struct(...
    'returnType', 'file', ...
    'filters', {{ ...
    struct('wildcard', struct('analysis0x2elabel', '*hcp-struct*')), ...
    struct('match', struct('project0x2elabel', 'tome')), ...
    }} ...
    );
analyses = fw.search(searchStruct, 'size', '1000');

for ii = 1:numel(analyses)
    
    if ~strcmp(analyses{ii}.file.name, [analyses{ii}.subject.code, '_hcpstruct.zip'])
        analyses{ii} = [];
    end
end

analyses = analyses(~cellfun('isempty', analyses));



numberOfSubjects = size(analyses,1);
%% from each session, download the hcp-struct.zip
for ss = 1:numberOfSubjects
    
    subject = analyses{ss}.subject.code;
    file_name = analyses{ss}.file.name;
    analysis_id = analyses{ss}.analysis.id;
    session_id = analyses{ss}.session.id;
    dataDownloadDir = '/Users/harrisonmcadams/Desktop/flywheel';
    output_name = fullfile(dataDownloadDir, file_name);
    
    fw.downloadOutputFromAnalysis(analysis_id, file_name, fullfile(dataDownloadDir, file_name));
    
    [~,~,ext] = fileparts(file_name);
    unzipDir = fullfile(dataDownloadDir,[subject '_' analysis_id]);
    
    if (~exist(unzipDir,'dir'))
        mkdir(unzipDir);
    end
    system(['unzip -o ' output_name ' -d ' unzipDir]);
    delete(output_name);
    
    fileToUpload = fullfile(unzipDir, subject, 'T1w', 'T1w_acpc_dc_restore.nii.gz');
    
    fw.uploadFileToSession(session_id,fileToUpload);
    rmdir(unzipDir, 's');
    
end

%% upload the T1w_apcp_dc_restore.nii.gz back to the same session