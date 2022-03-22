% This script calculates the head rotation from qform and compares them to
% the dicom rotation measurements Geoff made. The dicom measurements are
% in a spreadsheet called YPR_values.xls in
% \mriTOMEAnalysis\code\innerEarModelAndNystagmus\correlationMaterial\YPR_values.xls
% Specify the path for the spreadsheet and a folder for workdir where the
% T2 images will be downloaded from Flywheel

clear all 

% Load Camille's measurement
workdir = 'C:\Users\ozenc\Desktop\workdir';
ypr = readtable('C:\Users\ozenc\Documents\MATLAB\projects\mriTOMEAnalysis\code\innerEarModelAndNystagmus\correlationMaterial\YPR_values.xls');
qformRots = {};

% Find tome
fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));
projects = fw.projects();
for ii = 1:length(projects)
    if strcmp('tome', projects{ii}.label)
        project = projects{ii};
    end
end

% Get subjects
subjects = project.subjects();

% Loop through subjects
counter = 1;
for sub = 1:length(subjects)
    % Get sessions if the subject ID is in the plane normal folder
    sessions = subjects{sub}.sessions();
    % Loop through sessions and get acquisitions 
    for ss = 1:length(sessions)
        if strcmp(sessions{ss}.label, 'Session 1')
            acquisitions = sessions{ss}.acquisitions();
            % Go through acquisitions in the sessions and get task and
            % rest fmri files.
            for aa = 1:length(acquisitions)
                if contains(acquisitions{aa}.label, 'T2w_SPC')
                       acquisition = acquisitions{aa};    
                       files = acquisition.files();
                       % Loop through files get niftis
                       for mm = 1:length(files)
                           if strcmp(files{mm}.type, 'nifti')
                               niftiFile = files{mm};
                               % Download the nifti and read qform                                 
                               downloadPath = fullfile(workdir, [subjects{sub}.label '_T2.nii.gz']);
                               if ~isfile(downloadPath)
                                    niftiFile.download(downloadPath);
                               end
                               header = load_untouch_header_only(downloadPath); 
                               qform = [header.hist.srow_x 0;
                                        header.hist.srow_y 0;
                                        header.hist.srow_z 1];
                               scaleX = norm(qform(1:3, 1));
                               scaleY = norm(qform(1:3, 2));
                               scaleZ = norm(qform(1:3, 3));
                               rotation = [qform(1,1)/scaleX  qform(1,2)/scaleY  qform(1,3)/scaleZ 0;...
                                           qform(2,1)/scaleX  qform(2,2)/scaleY  qform(2,3)/scaleZ 0;...
                                           qform(3,1)/scaleX  qform(3,2)/scaleY  qform(3,3)/scaleZ 0;...
                                                    0                 0                   0        1];
                               eulAngles = rad2deg(rotm2eul(rotation(1:3, 1:3), 'XYZ'));
                               if ~any(any(strcmp(qformRots, subjects{sub}.label)))
                                   qformRots{counter, 1} = subjects{sub}.label;
                                   qformRots{counter, 2} = eulAngles(3);
                                   qformRots{counter, 3} = eulAngles(1);
                                   qformRots{counter, 4} = eulAngles(2);
                                   counter = counter + 1;
                               end
                           end
                       end
                end
            end
        end
    end
end


qformRots = cell2table(qformRots);
qformRots = renamevars(qformRots,'qformRots1','Patient');
ypr = renamevars(ypr,'Var1','Patient');
joined = innerjoin(ypr, qformRots);
[rYaw, pYaw] = corrcoef(joined.Yaw, joined.qformRots2,'Rows','pairwise');
[rPitch, pPitch] = corrcoef(joined.Pitch, joined.qformRots3,'Rows','pairwise');
[rRoll, pRoll] = corrcoef(joined.Roll, joined.qformRots4,'Rows','pairwise');
fprintf(['Yaw correlation: r: ' num2str(rYaw(2)) ' p: ' num2str(pYaw(2)) '\n']) 
fprintf(['Pitch correlation: r: ' num2str(rPitch(2)) ' p: ' num2str(pPitch(2)) '\n'])
fprintf(['Roll correlation: r: ' num2str(rRoll(2)) ' p: ' num2str(pRoll(2)) '\n'])

%% Run the same thing for spin echo images
% Loop through subjects
qformRotsSpinEcho = {};
counter = 1;
for sub = 1:length(subjects)
    % Get sessions if the subject ID is in the plane normal folder
    sessions = subjects{sub}.sessions();
    % Loop through sessions and get acquisitions 
    for ss = 1:length(sessions)
        if strcmp(sessions{ss}.label, 'Session 1')
            acquisitions = sessions{ss}.acquisitions();
            % Go through acquisitions in the sessions and get task and
            % rest fmri files.
            for aa = 1:length(acquisitions)
                if contains(acquisitions{aa}.label, 'SpinEchoFieldMap_AP')
                       acquisition = acquisitions{aa};    
                       files = acquisition.files();
                       % Loop through files get niftis
                       for mm = 1:length(files)
                           if strcmp(files{mm}.type, 'nifti')
                               niftiFile = files{mm};
                               % Download the nifti and read qform                                 
                               downloadPath = fullfile(workdir, [subjects{sub}.label '_spinEcho.nii.gz']);
                               if ~isfile(downloadPath)
                                    niftiFile.download(downloadPath);
                               end
                               header = load_untouch_header_only(downloadPath); 
                               qform = [header.hist.srow_x 0;
                                        header.hist.srow_y 0;
                                        header.hist.srow_z 1];
                               scaleX = norm(qform(1:3, 1));
                               scaleY = norm(qform(1:3, 2));
                               scaleZ = norm(qform(1:3, 3));
                               rotation = [qform(1,1)/scaleX  qform(1,2)/scaleY  qform(1,3)/scaleZ 0;...
                                           qform(2,1)/scaleX  qform(2,2)/scaleY  qform(2,3)/scaleZ 0;...
                                           qform(3,1)/scaleX  qform(3,2)/scaleY  qform(3,3)/scaleZ 0;...
                                                    0                 0                   0        1];
                               rotation = rotation * rotm2tform(roty(180));
                               eulAngles = rad2deg(rotm2eul(rotation(1:3, 1:3), 'XYZ'));
                               if ~any(any(strcmp(qformRots, subjects{sub}.label)))
                                   qformRotsSpinEcho{counter, 1} = subjects{sub}.label;
                                   qformRotsSpinEcho{counter, 2} = eulAngles(3)
                                   qformRotsSpinEcho{counter, 3} = eulAngles(1) - 20;
                                   qformRotsSpinEcho{counter, 4} = eulAngles(2);
                                   counter = counter + 1;
                               end
                           end
                       end
                end
            end
        end
    end
end

qformRotsSpinEcho = cell2table(qformRotsSpinEcho);
qformRotsSpinEcho = renamevars(qformRotsSpinEcho,'qformRotsSpinEcho1','Patient');