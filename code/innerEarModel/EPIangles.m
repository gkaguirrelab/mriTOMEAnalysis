%% Calculate the angle between z-axis and ear normals in the EPI space
% WARNING: Running this script takes a long time as I had to download all 
% EPI images (takes about a day). It deletes data, so disk space is not
% crucial as long as you have about 500mb space to for the workdir

% Set paths to inner ear normal folder folder which can be downloaded with
% the downloadSubjectNormals.m 
normalFolder = '/home/ozzy/Desktop/hadEnough/ForOzzy/ForOzzy/tome';
workdir = '/home/ozzy/Desktop/workdir';

% Establish a z-axis. The 1 at the 4th dimension is for homogenous
% coordinates, not for time.
zAxis = [0 0 1 1];

% Loop through the subject folders, get the lateral normal, get the EPI
% images and their q-form, apply transformation, and measure angles
directoryContents = dir(normalFolder);
directoryContents(2) = [];
directoryContents(1) = [];

% Find tome
fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));
projects = fw.projects();
for ii = 1:length(projects)
    if strcmp('tome', projects{ii}.label)
        project = projects{ii};
    end
end

% Create an empty cell where the results will be saved
normalWrtB0 = {};

for ii = 1:length(directoryContents)
    % Get subject name from folder names and construct plane folder path
    subjectName = directoryContents(ii).name;
    planeFolder = fullfile(normalFolder, subjectName);
    
    % Load normals
    [lateralMRILeft, lateralMRIRight, ...
     anteriorMRILeft, anteriorMRIRight, ...
     posteriorMRILeft, posteriorMRIRight] = loadMRINormals(planeFolder);
 
    % Get subjects
    subjects = project.subjects();
    
    % Loop through subjects
    for sub = 1:length(subjects)
        % Get sessions if the subject ID is in the plane normal folder
        if strcmp(subjects{sub}.label, subjectName)
            sessions = subjects{sub}.sessions();
            % Loop through sessions and get acquisitions 
            for ss = 1:length(sessions)
                acquisitions = sessions{ss}.acquisitions();
                % Set a counter
                indexCount = 1;
                % Go through acquisitions in the sessions and get task and
                % rest fmri files.
                for aa = 1:length(acquisitions)
                    if contains(acquisitions{aa}.label, 'tfMRI') || contains(acquisitions{aa}.label, 'rfMRI')
                        if ~contains(acquisitions{aa}.label, 'SBRef')
                            acquisition = acquisitions{aa};    
                            files = acquisition.files();
                            % Loop through files get niftis
                            for mm = 1:length(files)
                                if strcmp(files{mm}.type, 'nifti')
                                    niftiFile = files{mm};
                                    % Download the nifti and read qform 
                                    acquisitionLabel = acquisitions{aa}.label;
                                    acquisitionLabel = acquisitionLabel(find(~isspace(acquisitionLabel)));                                    
                                    downloadPath = fullfile(workdir, [acquisitionLabel '_' acquisitionLabel '.nii.gz']);
                                    niftiFile.download(downloadPath);
                                    header = MRIread(downloadPath);
                                    qform = header.vox2ras;
                                    normalWrtB0.(subjectName).(acquisitionLabel).qform = qform;
                                    % Calculate the rotation from qform and
                                    % save it into a struct
                                    scaleX = norm(qform(1:3, 1));
                                    scaleY = norm(qform(1:3, 2));
                                    scaleZ = norm(qform(1:3, 3));
                                    rotation = [qform(1,1)/scaleX  qform(1,2)/scaleY  qform(1,3)/scaleZ 0;...
                                                qform(2,1)/scaleX  qform(2,2)/scaleY  qform(2,3)/scaleZ 0;...
                                                qform(3,1)/scaleX  qform(3,2)/scaleY  qform(3,3)/scaleZ 0;...
                                                         0                 0                   0        1];
                                    normalWrtB0.(subjectName).(acquisitionLabel).rotation = rotation;
                                    % Apply the inverse of the rotation to rotate vectors                 
                                    normalOnEPILeft = inv(qform) * [lateralMRILeft(1) lateralMRILeft(2) lateralMRILeft(3) 1]';
                                    normalOnEPIRight = inv(qform) * [lateralMRIRight(1) lateralMRIRight(2) lateralMRIRight(3) 1]';
                                    % Do the same for the z axis
                                    newZ = inv(qform) * zAxis';
                                    % Calculate the angles in the EPI space
                                    % We expect these to be the same as the
                                    % world coordinate angle relationships
                                    % as we rotate Z-axis and vectors with
                                    % the same rotation matrix.
                                    normalWrtB0.(subjectName).(acquisitionLabel).leftAngleInitial = rad2deg(atan2(norm(cross(normalOnEPILeft(1:3),newZ(1:3))), dot(normalOnEPILeft(1:3),newZ(1:3))));
                                    normalWrtB0.(subjectName).(acquisitionLabel).rightAngleInitial = rad2deg(atan2(norm(cross(normalOnEPIRight(1:3),newZ(1:3))), dot(normalOnEPIRight(1:3),newZ(1:3))));
%                                     % Now we calculate a rigid transform
%                                     % between EPI and T2 image. This
%                                     % ensures that minor head movements
%                                     % will be used to adjust the initial 
%                                     % angle measurements
%                                     singleTR = fullfile(workdir, 'singleTR.nii.gz');
%                                     outputMat = fullfile(workdir, 'registrationMat.txt');
%                                     system(['fslroi ' downloadPath ' ' singleTR ' 0 1'])
%                                     system(['flirt -in ' singleTR ' -ref ' T2Image '-dof 6 -omat ' outputMat])
%                                     rawmat = fileread(outputMat);
%                                     rawmat = strsplit(rawmat);
%                                     headMotionQform = [str2num(rawmat(1)) str2num(rawmat(2)) str2num(rawmat(3)) str2num(rawmat(4)); ...
%                                                        str2num(rawmat(5)) str2num(rawmat(6)) str2num(rawmat(7)) str2num(rawmat(8)); ...
%                                                        str2num(rawmat(9)) str2num(rawmat(10)) str2num(rawmat(11)) str2num(rawmat(12)); ...
%                                                        str2num(rawmat(13)) str2num(rawmat(14)) str2num(rawmat(15)) str2num(rawmat(16))];
%                                     scaleXh = norm(headMotionQform(1:3, 1));
%                                     scaleYh = norm(headMotionQform(1:3, 2));
%                                     scaleZh = norm(headMotionQform(1:3, 3));
%                                     rotationHead = [headMotionQform(1,1)/scaleXh  headMotionQform(1,2)/scaleYh  headMotionQform(1,3)/scaleZh 0;...
%                                                     headMotionQform(2,1)/scaleXh  headMotionQform(2,2)/scaleYh  headMotionQform(2,3)/scaleZh 0;...
%                                                     headMotionQform(3,1)/scaleXh  headMotionQform(3,2)/scaleYh  headMotionQform(3,3)/scaleZh 0;...
%                                                                   0                             0                             0              1];
%                                     
%                                     % Now we apply the transformation to 
%                                     % the normals that are already in the 
%                                     % EPI space to make these minor
%                                     % adjustments. However, we include a 
%                                     % 180 flip because qform already
%                                     % covered that. 
%                                     normalOnEPILeftAdjusted = inv(qform) * [lateralMRILeft(1) lateralMRILeft(2) lateralMRILeft(3) 1]';
%                                     normalOnEPIRightAdjusted = inv(qform) * [lateralMRIRight(1) lateralMRIRight(2) lateralMRIRight(3) 1]';                                    
                                end
                            end
                             indexCount = indexCount + 1;
                             delete(downloadPath);
                        end
                    end
                end
            end
        end
    end                                          
end