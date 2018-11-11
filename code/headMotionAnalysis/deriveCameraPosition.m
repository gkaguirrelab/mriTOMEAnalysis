function deriveCameraPosition(subjectCellArray, cornealCoords, varargin)
% Derive a vector of relative position of the eye from fMRI motion params
%
% Syntax:
%  deriveCameraPosition(subjectCellArray, cornealCoords)
%
% Description:
%
%
%
% Dimensions of the T1 image as expressed in Flywheel viewer
% These are the coordinates as expressed in the Flywheel viewer

% Examples:
%{
    subjectCellArray = {'TOME_3001','TOME_3002','TOME_3003','TOME_3004','TOME_3005'};
    cornealCoords = {[189 29 160],[190 23 162],[187 24 154],[194 33 151],[180 35 157]};
    deriveCameraPosition(subjectCellArray, cornealCoords)
%}

%% Parse vargin for options passed here
p = inputParser; p.KeepUnmatched = true;

% Required
p.addRequired('subjectCellArray',@iscell);
p.addRequired('cornealCoords',@iscell);

% Optional display and I/O params
p.addParameter('verbose',true,@islogical);
p.addParameter('showPlots',true,@islogical);

% Optional environment params
p.addParameter('tbSnapshot',[],@(x)(isempty(x) | isstruct(x)));
p.addParameter('timestamp',char(datetime('now')),@ischar);
p.addParameter('hostname',char(java.lang.System.getProperty('user.name')),@ischar);
p.addParameter('username',char(java.net.InetAddress.getLocalHost.getHostName),@ischar);

% Optional analysis params
p.addParameter('processingDir','/Users/aguirre/Dropbox (Aguirre-Brainard Lab)/TOME_processing',@ischar);
p.addParameter('analysisDir', '/Users/aguirre/Dropbox (Aguirre-Brainard Lab)/TOME_analysis/deriveCameraPositionFromHeadMotion/',@ischar);
p.addParameter('scratchSaveDir',getpref('flywheelMRSupport','flywheelScratchDir'),@ischar);
p.addParameter('sessionDir','session1_restAndStructure',@ischar);
p.addParameter('freesurferBinDir','/Applications/freesurfer/bin/',@ischar);
p.addParameter('epiVoxelSizeMm', 2, @isnumeric);
p.addParameter('msecsTR', 800, @isnumeric);
p.addParameter('t1Dims', [227 272 227], @isnumeric);


%% Parse and check the parameters
p.parse(subjectCellArray, cornealCoords, varargin{:});

% This string precedes system calls to freesurfer commands to set the
% environment variables
freesurferSetUp = 'export FREESURFER_HOME=/Applications/freesurfer; source $FREESURFER_HOME/SetUpFreeSurfer.sh; ';

% This string follows system calls to silence consult output
devNull = ' >/dev/null';

% Load a T1 reference volume
t1FileName = fullfile(p.Results.analysisDir,'T1w_acpc_dc_restore.nii.gz');
mri = MRIread(escapeFileCharacters(t1FileName));

%% Loop through the subjects
for ii = 1:numel(subjectCellArray)
    
    %% Find the right corneal surface coordinate in the EPI scout space
    % Place a point in the T1 volume corresponding to the right cornea
    mri.vol = mri.vol.*0;
    % The coordinates in the flywheel viewer are relative to the opposite
    % corner of the volume, so we subtract the value from the dimensions of
    % the volume. This puts the coordinate into the same frame that would
    % be found in the fslEyes viewer.
    coord = p.Results.t1Dims-cornealCoords{ii};
    % In fslEyes, the dimensions are right-left, anterior-posterior,
    % inferior-superior when loaded in matlab, the mri.vol dimensions are
    % anterior-posterior, right-left, inferior-superior So the fslEyes
    % viewer coordinate [73, 250, 42] corresponds to the mri.vol coordinate
    % in matlab of [251, 74, 43]
    mri.vol(coord(2)+1,coord(3)+1,coord(1)+1)=100;
    
    % Save the volume in a tmp location
    t1SpaceEyeCoordFileName = fullfile(p.Results.scratchSaveDir,['t1SpaceEyeCoord_' num2str(tic()) '.nii.gz']);
    MRIwrite(mri,escapeFileCharacters(t1SpaceEyeCoordFileName));
    
    % Find the Scout EPI targets in the analysisDir
    targetFiles = dir(fullfile(p.Results.analysisDir,p.Results.sessionDir,[subjectCellArray{ii} '*' 'Scout_gdc.nii.gz']));
    
    % Loop through the target files and project the eye coordinate in T1
    % space to scout EPI space
    for jj=1:length(targetFiles)
        
        % Assemble the file strings
        acquisitionRootName = strsplit(targetFiles(jj).name,'_Scout_gdc.nii.gz');
        acquisitionRootName = acquisitionRootName{1};        
        infoFile = fullfile(targetFiles(jj).folder,[acquisitionRootName '_sessionInfo.mat']);
        regFile = fullfile(targetFiles(jj).folder,[acquisitionRootName '_EPItoT1w.dat']);
        moveRegressorsFile = fullfile(targetFiles(jj).folder,[acquisitionRootName '_Movement_Regressors.txt']);
        outEyeVoxelFile = fullfile(p.Results.scratchSaveDir,[num2str(tic()) acquisitionRootName '_eyeVoxel_ScoutSpace.nii.gz']);
        
        % Assemble the vol2vol command
        command = [p.Results.freesurferBinDir 'mri_vol2vol' ...
            ' --mov ' escapeFileCharacters(t1SpaceEyeCoordFileName) ...
            ' --targ ' escapeFileCharacters(fullfile(targetFiles(jj).folder,targetFiles(jj).name)) ...
            ' --o '  escapeFileCharacters(outEyeVoxelFile) ...
            ' --reg ' escapeFileCharacters(regFile) ...
            ' --cubic' ];
        
        % Issue the command
        system([freesurferSetUp command devNull]);
        
        % Load the resulting volume
        mriEyeVoxel = MRIread(escapeFileCharacters(outEyeVoxelFile));
        
        % Find the eye voxel coordinate
        [~,ind] = max(mriEyeVoxel.vol(:));
        [eyeVoxel(1), eyeVoxel(2), eyeVoxel(3)] = ind2sub(size(mriEyeVoxel.vol),ind);
        
        % Find the position of the eyeVoxel in mm relative to the volume
        % center
        eyePositionWRTCenter = (eyeVoxel-size(mriEyeVoxel.vol)./2).*p.Results.epiVoxelSizeMm;
        
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
        videoAcqStemName = fullfile(p.Results.processingDir,p.Results.sessionDir,sessionInfo.subject,sessionInfo.date,'EyeTracking',tmpString);
        
        % Create the relativeCameraPosition
        relativeCameraPosition = calcRelativeCameraPosition(moveRegressorsFile, videoAcqStemName, eyePositionWRTCenter, p.Results.msecsTR);
        
        % add meta data
        relativeCameraPosition.meta = p.Results;
        relativeCameraPosition.meta.sessionInfo = sessionInfo;
        
        % Save the relativeCameraPosition variable
        outCameraPositionFile = [videoAcqStemName '_relativeCameraPosition.mat'];
        save(outCameraPositionFile,'relativeCameraPosition');

        % Plot the relativeCameraPosition variables
        if p.Results.showPlots
            figure
            plot(relativeCameraPosition.values(1,:));
            hold on
            plot(relativeCameraPosition.values(2,:));
            plot(relativeCameraPosition.values(3,:));
            ylim([-4 4]);
        end

        % Report completion of this step
        if p.Results.verbose
        reportLineOut = sprintf([acquisitionRootName ' eye coords relative to volume center (mm): %d %d %2d'],eyePositionWRTCenter(1),eyePositionWRTCenter(2),eyePositionWRTCenter(3));
        fprintf([reportLineOut ' \n']);
        end
        
        % Clean up the files we have generated thus far
        delete([outEyeVoxelFile]);
        delete([outEyeVoxelFile '.lta']);
        delete([outEyeVoxelFile '.reg']);
        
    end
    
    % Clean up the T1 space file
    delete(t1SpaceEyeCoordFileName);
end

end % deriveCameraPosition

function relativeCameraPosition = calcRelativeCameraPosition(moveRegressorsFile, videoAcqStemName, eyePositionWRTCenter, msecsTR)

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
    newEyePosition = newEyePosition + T';
    
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
relativeCameraPosition.values = zeros(3,length(timebase.values));

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
    relativeCameraPosition.values(scanToCameraCoords(dd),:) = [zeros(1,nElementsPre) ...
        -interp1(scanTimebase,eyePosition(:,dd),eyeTrackTimebase,'PCHIP') ...
        -repmat(eyePosition(end,dd),1,nElementsPost)];
end

end


function nameOut = escapeFileCharacters(nameIn)
nameOut = strrep(nameIn,' ','\ ');
nameOut = strrep(nameOut,'(','\(');
nameOut = strrep(nameOut,')','\)');
end