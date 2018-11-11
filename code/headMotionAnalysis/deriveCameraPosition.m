


processingDir = '/Users/aguirre/Dropbox (Aguirre-Brainard Lab)/TOME_processing';
analysisDir = '/Users/aguirre/Dropbox (Aguirre-Brainard Lab)/TOME_analysis/deriveCameraPositionFromHeadMotion/';
%scratchSaveDir = getpref('flywheelMRSupport','flywheelScratchDir');
scratchSaveDir = '/tmp/flywheel';
sessionDir = 'session1_restAndStructure';
freesurferBinDir = '/Applications/freesurfer/bin/';
freesurferSetUp = 'export FREESURFER_HOME=/Applications/freesurfer; source $FREESURFER_HOME/SetUpFreeSurfer.sh; ';
devNull = ' >/dev/null';
resultFileSuffix = {'Movement_Regressors.txt','Scout_gdc.nii.gz','DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased/EPItoT1w.dat'};

epiVoxelSizeMm = 2.0;
msecsTR = 800;

subjects = {'TOME_3001','TOME_3002'};

% These are the coordinates as expressed in the Flywheel viewer
rightCornealCoords = {[189 29 160],[190 23 162]};

% Dimensions of the T1 image as expressed in Flywheel viewer
t1Dims = [227 272 227];

% Load a T1 volume
t1FileName = fullfile(analysisDir,'T1w_acpc_dc_restore.nii.gz');
mri = MRIread(escapeFileCharacters(t1FileName));

%% Loop through the subjects
for ii = 1:numel(subjects)
    
    %% Find the right corneal surface coordinate in the EPI scout space
    % Place a point in the T1 volume corresponding to the right cornea
    mri.vol = mri.vol.*0;
    % The coordinates in the flywheel viewer are relative to the opposite
    % corner of the volume, so we subtract the value from the dimensions of
    % the volume. This puts the coordinate into the same frame that would
    % be found in the fslEyes viewer.
    coord = t1Dims-rightCornealCoords{ii};
    % In fslEyes, the dimensions are right-left, anterior-posterior,
    % inferior-superior when loaded in matlab, the mri.vol dimensions are
    % anterior-posterior, right-left, inferior-superior So the fslEyes
    % viewer coordinate [73, 250, 42] corresponds to the mri.vol coordinate
    % in matlab of [251, 74, 43]
    mri.vol(coord(2)+1,coord(3)+1,coord(1)+1)=100;
    
    % Save the volume in a tmp location
    t1SpaceEyeCoordFileName = fullfile(scratchSaveDir,['t1SpaceEyeCoord_' num2str(tic()) '.nii.gz']);
    MRIwrite(mri,escapeFileCharacters(t1SpaceEyeCoordFileName));
    
    % Find the Scout EPI targets in the analysisDir
    targetFiles = dir(fullfile(analysisDir,sessionDir,[subjects{ii} '*' 'Scout_gdc.nii.gz']));
    
    % Loop through the target files and project the eye coordinate in T1
    % space to scout EPI space
    for jj=1:length(targetFiles)
        
        % Assemble the file strings
        acquisitionRootName = strsplit(targetFiles(jj).name,'_Scout_gdc.nii.gz');
        acquisitionRootName = acquisitionRootName{1};        
        infoFile = fullfile(targetFiles(jj).folder,[acquisitionRootName '_sessionInfo.mat']);
        regFile = fullfile(targetFiles(jj).folder,[acquisitionRootName '_EPItoT1w.dat']);
        moveRegressorsFile = fullfile(targetFiles(jj).folder,[acquisitionRootName '_Movement_Regressors.txt']);
        outFile = fullfile(scratchSaveDir,[num2str(tic()) acquisitionRootName '_eyeVoxel_ScoutSpace.nii.gz']);
        
        % Assemble the vol2vol command
        command = [freesurferBinDir 'mri_vol2vol' ...
            ' --mov ' escapeFileCharacters(t1SpaceEyeCoordFileName) ...
            ' --targ ' escapeFileCharacters(fullfile(targetFiles(jj).folder,targetFiles(jj).name)) ...
            ' --o '  escapeFileCharacters(outFile) ...
            ' --reg ' escapeFileCharacters(regFile) ...
            ' --cubic' ];
        
        % Issue the command
        system([freesurferSetUp command devNull]);
        
        % Load the resulting volume
        mriEyeVoxel = MRIread(escapeFileCharacters(outFile));
        
        % Find the eye voxel coordinate
        [~,ind] = max(mriEyeVoxel.vol(:));
        [eyeVoxel(1), eyeVoxel(2), eyeVoxel(3)] = ind2sub(size(mriEyeVoxel.vol),ind);
        
        % Find the position of the eyeVoxel in mm relative to the volume
        % center
        eyePositionWRTCenter = (eyeVoxel-size(mriEyeVoxel.vol)./2).*epiVoxelSizeMm;
        
        % Determine the corresponding video acquisition stem
        dataLoad = load(infoFile);
        sessionInfo = dataLoad.sessionInfo;
        clear dataLoad        
        tmpString = strsplit(acquisitionRootName,[sessionInfo.subject '_' ]);
        tmpString = tmpString{2};
        tmpString = strrep(tmpString,'Run1','run01');
        tmpString = strrep(tmpString,'Run2','run02');
        tmpString = strrep(tmpString,'Run3','run03');
        tmpString = strrep(tmpString,'Run4','run04');
        videoAcqStemName = fullfile(processingDir,sessionDir,sessionInfo.subject,sessionInfo.date,'EyeTracking',tmpString);
        
        % Create the camera position vector file
        createCameraPositionFile(moveRegressorsFile, videoAcqStemName, eyePositionWRTCenter, msecsTR)
        
        % Report completion of this step
        reportLineOut = sprintf([acquisitionRootName ' eye coords relative to volume center (mm): %d %d %2d'],eyePositionWRTCenter(1),eyePositionWRTCenter(2),eyePositionWRTCenter(3));
        fprintf([reportLineOut ' \n']);
        
        % Clean up the files we have generated thus far
        delete([outFile]);
        delete([outFile '.lta']);
        delete([outFile '.reg']);
        
    end
    
    % Clean up the T1 space file
    delete(t1SpaceEyeCoordFileName);
end



function createCameraPositionFile(moveRegressorsFile, videoAcqStemName, eyePositionWRTCenter, msecsTR)

% Load the head motion regressors
movementTable = readtable(moveRegressorsFile,'Delimiter','space','MultipleDelimsAsOne',true);

numTRs = size(movementTable,1);

% Loop over TRs
for ii = 1:numTRs
    
    % Create the rotation matrix. The regressors correspond to pitch, roll,
    % and yaw.
    R.x = [1 0 0; 0 cosd(movementTable{ii,4}) -sind(movementTable{ii,4}); 0 sind(movementTable{ii,4}) cosd(movementTable{ii,4})];
    R.y = [cosd(movementTable{ii,5}) 0 sind(movementTable{ii,5}); 0 1 0; -sind(movementTable{ii,5}) 0 cosd(movementTable{ii,5})];
    R.z = [cosd(movementTable{ii,6}) -sind(movementTable{ii,6}) 0; sind(movementTable{ii,6}) cosd(movementTable{ii,6}) 0; 0 0 1];
    Rzyx = R.z * R.y * R.x;
    
    % Rotate the eye position
    newEyePosition = Rzyx * eyePositionWRTCenter';
    
    % Translate the eye position. The first three columns of the head
    % motion regressors correspond to x, y, z
    T = table2array(movementTable(ii,1:3));
    newEyePosition = newEyePosition - T';
    
    % Store the newEyePosition
    eyePosition(ii,:)=newEyePosition;
end

% Make eye position relative to the initial time point
eyePosition = eyePosition-eyePosition(1,:);

% Load the eyetracking timebase
dataLoad = load([videoAcqStemName '_timebase.mat']);
timebase = dataLoad.timebase;
clear dataLoad

% Establish the timebase of the scan acquisition
scanTimebase = 0:msecsTR:msecsTR*(numTRs-1);

% Calculate the deltaT of the eyetracking video
eyeTrackDeltaT = mean(diff(timebase.values));

% Establish the timebase of the scan in eyetrack temporal resolution
eyeTrackTimebase = 0:eyeTrackDeltaT:(msecsTR*numTRs)-eyeTrackDeltaT;

% Calculate the number of video frames before and after the scan
% acquisition
nElementsPre = sum(timebase.values<0);
nElementsPost = sum(timebase.values>max(eyeTrackTimebase));

% Create a variable to hold the relative camera position
relativeCameraPosition = zeros(3,length(timebase.values));

% We are sometimes off by one frame due to rounding errors and missed
% frames. We fix that here.
trim = (nElementsPre+nElementsPost+numel(eyeTrackTimebase)) - length(timebase.values);
nElementsPost = nElementsPost-trim;

% The scanner coordinates x,y,z correspond to right-left,
% posterior-anterior, inferior-superior. The camera world coordinates are
% x,y,z corresponding to right-left, down-up, back-front (towards the
% camera)
scanToCameraCoords = [1,3,2];

% Loop over the world coordinate dimensions and create the relative camera
% position vector, with a length equal to the timebase of the video
% acquisition. Interpolate from the coarse TR sampling to the fine video
% sampling.
for dd = 1:3
    relativeCameraPosition(scanToCameraCoords(dd),:) = [zeros(1,nElementsPre) ...
        -interp1(scanTimebase,eyePosition(:,dd),eyeTrackTimebase,'PCHIP') ...
        -repmat(eyePosition(end,dd),1,nElementsPost)];
end

% Save the relativeCameraPosition variable
figure
plot(relativeCameraPosition(1,:));
hold on
plot(relativeCameraPosition(2,:));
plot(relativeCameraPosition(3,:));


end


function nameOut = escapeFileCharacters(nameIn)
nameOut = strrep(nameIn,' ','\ ');
nameOut = strrep(nameOut,'(','\(');
nameOut = strrep(nameOut,')','\)');
end