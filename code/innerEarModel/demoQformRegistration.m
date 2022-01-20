% Subject alignment
% 3005 - yaw and roll to the right
% 3009 - yaw and roll to the left, slight pitch up
% 3011 - yaw to left, roll to right
% 3018 - pitch up 
% 3025 - yaw right
% 3028 - pitch up
% 3027 - pitch up
% 3036 - roll left
% 3044 - yaw left
% 3046 - pitch up

% Set ID and Workdir
subjectID = 'TOME_3046';
workdir = 'C:\Users\ozenc\Desktop\ears';
compareTo = 'T2'; % enter spinEcho or T2 here.

% Create a folder for the subject in workdir
subjectDir = fullfile(workdir, subjectID);
if ~exist(subjectDir, 'dir')
    mkdir(subjectDir)
end

% Init fw and find projects
fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));
projects = fw.projects();

% Find tome on Flywheel
for ii = 1:length(projects)
    if strcmp('tome', projects{ii}.label)
        project = projects{ii};
    end
end

% Find the subject
subjects = project.subjects();
for sub = 1:length(subjects)
    if strcmp(subjectID, subjects{sub}.label)
        subject = subjects{sub};
    end
end

% Get the session 
sessions = subject.sessions();
for ses = 1:length(sessions)
    if strcmp(sessions{ses}.label, 'Session 1')
        session = sessions{ses};
        acquisitions = session.acquisitions();
    end
end

% Find the AAHscout and the image to compare(T2 or Spin)
for acq = 1:length(acquisitions)
    if contains(acquisitions{acq}.label, 'AAHScout') && ~contains(acquisitions{acq}.label, 'cor') && ~contains(acquisitions{acq}.label, 'sag') && ~contains(acquisitions{acq}.label, 'tra')
        scoutPath = fullfile(subjectDir, 'AAH_scout.nii.gz');
        if ~isfile(scoutPath)
            acquisitions{acq}.files{2}.download(scoutPath);
        end
    end
    if strcmp(compareTo, 'spinEcho')
        if contains(acquisitions{acq}.label, 'SpinEchoFieldMap_AP')
            comparePath = fullfile(subjectDir, 'spinEcho.nii.gz');
            if ~isfile(comparePath)
                acquisitions{acq}.files{2}.download(comparePath);
            end
        end
    else
        if contains(acquisitions{acq}.label, 'T2')
            comparePath = fullfile(subjectDir, 'T2_image.nii.gz');
            if ~isfile(comparePath)
                fprintf(['Downloading T2 image for ' subjectID '\n'])
                acquisitions{acq}.files{2}.download(comparePath);
            end
        end
    end
end

% Load volume
scoutHeader = spm_vol(scoutPath);
compareHeader = spm_vol(comparePath);

% Read headers and image data
scoutVol = spm_read_vols(scoutHeader);
compareVol = spm_read_vols(compareHeader);
compareVol = compareVol(:,:,:,1);

%% Here we get the qform matrix for both scout and spin and do decomposition.
    % Qform specifies the translation that needs to be performed to go from
    % image coordinates to scanner coordinates. We get qform matrices for 
    % scout/spin and decompose them into translation, rotation, and scaling. 
    % We only care about rotation so I set translation to 0 and only 
    % calculate scaling factor for decomposition purposes.

% Get scout and other image's qform    
scoutQform = scoutHeader.mat;
compareQform = compareHeader.mat;

% % Set translation to zero on both
% scoutQform(1:3, 4) = 0; 
% compareQform(1:3, 4) = 0; 

% Get scalings from the both
scoutSx = norm(scoutQform(1:3, 1));
scoutSy = norm(scoutQform(1:3, 2));
scoutSz = norm(scoutQform(1:3, 3));

compareSx = norm(compareQform(1:3, 1));
compareSy = norm(compareQform(1:3, 2));
compareSz = norm(compareQform(1:3, 3));

% Decompose rotations by dividing out the scaling factors 
scoutR = [scoutQform(1,1)/scoutSx  scoutQform(1,2)/scoutSy  scoutQform(1,3)/scoutSz 0;...
          scoutQform(2,1)/scoutSx  scoutQform(2,2)/scoutSy  scoutQform(2,3)/scoutSz 0;...
          scoutQform(3,1)/scoutSx  scoutQform(3,2)/scoutSy  scoutQform(3,3)/scoutSz 0;...
                     0                         0                          0         1];

compareR = [compareQform(1,1)/compareSx  compareQform(1,2)/compareSy  compareQform(1,3)/compareSz 0;...
         compareQform(2,1)/compareSx  compareQform(2,2)/compareSy  compareQform(2,3)/compareSz 0;...
         compareQform(3,1)/compareSx  compareQform(3,2)/compareSy  compareQform(3,3)/compareSz 0;...
                   0                      0                        0         1]; 
 
% INNER EAR DRAW
lateralMRILeft_points = pca(load(fullfile('C:\Users\ozenc\Desktop\ForOzzy\ForOzzy\tome\TOME_3046', 'left_lat.mat'), 'point_array').point_array);
lateralMRILeft = lateralMRILeft_points(:,3);
offsetLeft = load(fullfile('C:\Users\ozenc\Desktop\ForOzzy\ForOzzy\tome\TOME_3005', 'left_lat.mat'), 'offset').offset;
offsetRight = load(fullfile('C:\Users\ozenc\Desktop\ForOzzy\ForOzzy\tome\TOME_3005', 'right_lat.mat'), 'offset').offset;
offsetLeft = inv(compareQform)*[offsetLeft(1) offsetLeft(2) offsetLeft(3) 1]';
offsetRight = inv(compareQform)*[offsetRight(1) offsetRight(2) offsetRight(3) 1]';
slice(double(compareVol),round(offsetRight(2)),round(offsetRight(1)),round(offsetRight(3)))
grid on, shading interp, colormap gray
% oMat = inv(compareQform) * [offset 1]';
% normalMat = inv(compareQform) * [lateralMRILeft' 1]';
% newOffset = [round(oMat(1)) round(oMat(2)) round(oMat(3))];
% newNormal = [round(normalMat(1)) round(normalMat(2)) round(normalMat(3))];
[newcompare, newR] = affine(compareVol, compareQform);
slice(double(newcompare),round(offset(2)),round(offset(1)),round(offset(3)))
grid on, shading interp, colormap gray
hold on
pts = [offset(2) offset(1) offset(3); lateralMRILeft(1) lateralMRILeft(2) lateralMRILeft(3)];
line(pts(:,1), pts(:,2), pts(:,3))

% Plot raw scout. Plot Y axis first
a = subplot(2,2,1);
scoutSize = size(scoutVol);
slice(double(scoutVol),scoutSize(2)/2,scoutSize(1)/2,scoutSize(3)/2)
title('Raw scout')
grid on, shading interp, colormap gray

% Plot raw spin/T2 in the second panel for initial comparison
b = subplot(2,2,2);
compareSize = size(compareVol);
slice(double(compareVol),compareSize(2)/2,compareSize(1)/2,compareSize(3)/2)
if strcmp(compareTo, 'spinEcho')
    title('Raw spindEcho')
else
    title('Raw T2')
end
grid on, shading interp, colormap gray

% % Maybe plot vectors here? 
% hold on
% y = [round(compareSize(1)/3) 0 0];
% x = [0 round(compareSize(2)/3) 0]; 
% z = [0 0 round(compareSize(3)/3)];
% quiver3(compareSize(2)/2,compareSize(1)/2,compareSize(3)/2,x(1),x(2),x(3),'r')
% quiver3(compareSize(2)/2,compareSize(1)/2,compareSize(3)/2,y(1),y(2),y(3),'g')
% quiver3(compareSize(2)/2,compareSize(1)/2,compareSize(3)/2,z(1),z(2),z(3),'b')

% Plot raw scout again
c = subplot(2,2,3);
slice(double(scoutVol),scoutSize(2)/2,scoutSize(1)/2,scoutSize(3)/2)
title('Raw scout')
grid on, shading interp, colormap gray

% Now rotate the spinEcho/T2 with qform to get back to scout image and plot
d = subplot(2,2,4);
[newcompare, newR] = affine(compareVol, compareQform);
newcompareSize = size(newcompare);
slice(double(newcompare),newcompareSize(2)/2,newcompareSize(1)/2,newcompareSize(3)/2)
if strcmp(compareTo, 'spinEcho')
    title('Rotated spindEcho')
else
    title('Rotated T2')
end
grid on, shading interp, colormap gray

% % Maybe plot the unit vectors again here but this time rotated versions?
% hold on 
% yNew = compareR(1:3,1:3)*y';
% xNew = compareR(1:3,1:3)*x';
% zNew = compareR(1:3,1:3)*z';
% quiver3(newcompareSize(2)/2,newcompareSize(1)/2,newcompareSize(3)/2,xNew(1),xNew(2),xNew(3),'r')
% quiver3(newcompareSize(2)/2,newcompareSize(1)/2,newcompareSize(3)/2,yNew(1),yNew(2),yNew(3),'g')
% quiver3(newcompareSize(2)/2,newcompareSize(1)/2,newcompareSize(3)/2,zNew(1),zNew(2),zNew(3),'b')

% Link all plots together, so they move together
linkprop([a,b,c,d],'View');
set(a,'View',[-3.5 20.0])

rad2deg(rotm2eul(x.R(1:3, 1:3), 'ZXY'))