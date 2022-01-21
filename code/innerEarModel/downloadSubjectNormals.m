function downloadSubjectNormals(saveLoc)
% This is the list of subjects whose plane normals are looking at the non
% preferred direction (right). This script downloads normals and corrects
% the directions and and saves normals in different folders.   

% Save folder
if ~isfolder(saveLoc)
    mkdir(saveLoc)
end

% Init fw and find projects
fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));
projects = fw.projects();

% Find tome 
for ii = 1:length(projects)
    if strcmp('tome', projects{ii}.label)
        project = projects{ii};
    end
end

% Find subjects 
subjects = project.subjects();
for ii = 1:length(subjects)
    subjectName = subjects{ii}.label;
    subjectFolder = fullfile(saveLoc, subjectName);
    sessions = subjects{ii}.sessions();
    for ss = 1:length(sessions)
        analyses = sessions{ss}.analyses();
        for aa = 1:length(analyses)
            if strcmp(analyses{aa}.label(1:3), 'new')
                mkdir(subjectFolder)
                innerEarGear = analyses{aa};
                zipName = fullfile(subjectFolder, [subjectName, '_plane_normals.zip']);
                innerEarGear.downloadFile([subjectName '_plane_normals.zip'], zipName);
                unzip(zipName, subjectFolder) 
                delete(zipName)
            end
        end
    end
end
end
        


