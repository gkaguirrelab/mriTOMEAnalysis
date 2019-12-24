function deriveCameraPosition(subject, cornealCoord, varargin)
% Derive a vector of relative position of the eye from fMRI motion params
%
% Syntax:
%  deriveCameraPosition(subject, cornealCoord)
%
% Description:
%   The "motion correction" stage of pre-processing of fMRI data includes
%   calculation of the displacement of the head from the starting position
%   at each point in time during an acquisition. This routine uses the
%   displacement information to produce a vector that specifies the
%   relative displacement of the eye tracking camera with respect to the
%   corneal surface during a scan. This vector is subsequently used in the
%   analysis of eye tracking videos.
%
%   This routine relies upon the prior execution of
%   "downloadMotionFiles.m", which downloads several files from Flywheel
%   for each subject/acquisition to be analyzed. These files include:
%       Scout_gdc.nii.gz      - The scout EPI image for this acquisition
%       T1w_acpc_dc_restore_brain.nii.gz - A T1 weighted anatomical image
%                               of the brain. We will define the location
%                               of the front surface of the right eye
%                               within this image.
%       MotionMatrices        - A directory that contains the rotation and
%                               translation matrix for each TR for the
%                               acquisition that aligns that EPI image
%                               volume with the Scout_gdc image.
%       Movement_Regressors.txt - The head motion for this acquisition
%                               expessed in a different format.
%       sessionInfo.mat       - A file generated by "downloadMotionFiles"
%                               that gives the subject, session, and date
%                               information for this acquisition
%
%   The key-value "analysisDir" specifies the directory where these files
%   may be found. Also specified is the "processingDir" which is the
%   directory in which the eye tracking video processing has taken place.
%   In particular, the routine requires the "timebase.mat" file associated
%   with eye tracking video for the acquisition to be analyzed.
%
%   At a high level, the processing steps for a given acquisition for a
%   given subject are:
%
%     - Given the right eye surface coordinate in T1 space, project that
%       coordinate to the EPI space for this subject/acqusition. This is
%       done by using FLIRT to calculate the affine transformation for
%           T1w_acpc_dc_restore_brain --> Scout_gdc.nii.gz
%       and then projecting the eye coordinate to the Scout_gdc space
%     - The movement of the eye coordinate point over time is then
%       calculate based upon the translations and rotations of the head
%       given in the MotionMatrices. My current understanding is that the
%       MotionMatrices are computed by the FSL FLIRT routine, and the
%       rotations are expressed relative to the "centre of mass" of the
%       target EPI volume. There is much fussing with the different
%       coordinate frames here.
%     - The movement of the eye coordinate is made relative to the position
%       of the eye at the first TR. As the temporal resolution of the head
%       motion regressors is far coarser than the eye tracking video, a
%       smooth interpolation of the head motion is performed to create a
%       vector that may be related to the eye tracking videos.
%     - The relative camera position vector is saved along with some meta
%       data.
%
%   The routine saves the file *_relativeCameraPosition.mat within the
%   processingDir for the subject.
%
% Inputs:
%   subject               - Char vector / string. The subject ID to be
%                           analyzed.
%   cornealCoord          - 1x3 vector. The [x y z] coordinates of the
%                           corneal surface of the right eye as specified
%                           in the Flywheel image viewer from the
%                           T1w_acpc_dc_restore.nii.gz image generated by
%                           the hcp-struct gear. The coordinates are in the
%                           order superior-inferior, anterior-posterior,
%                           left-right.
%
% Optional key/value pairs (display and I/O):
%  'verbose'              - Logical. Default false.
%  'showPlots'            - Logical. Default false.
%
% Optional key/value pairs (environment)
%  'tbSnapshot'           - This should contain the output of the
%                           tbDeploymentSnapshot performed upon the result
%                           of the tbUse command. This documents the state
%                           of the system at the time of analysis.
%  'timestamp'            - AUTOMATIC; The current time and date
%  'username'             - AUTOMATIC; The user
%  'hostname'             - AUTOMATIC; The host
%
% Optional key/value pairs (analysis)
%  'processingDir'        - Char vector. The full path to the directory
%                           that holds the intermediate processing stages
%                           of the eye tracking video analysis.
%  'analysisDir'          - Char vector. The full path to the directory
%                           that holds the files downloaded by the routine
%                           downloadMotionFiles.m
%  't1FileName'           - Char vector. Full path to a nifti file that is
%                           a T1 image in native subject space that has the
%                           same coordinates as the image in which the eye
%                           coordinate was determined.
%  'scratchSaveDir'       - Char vector. Full path to a directory where
%                           intermediate files will be saved and then
%                           deleted.
%  'sessionDir'           - The session label for the subjects to be
%                           analyzed. E.g., 'session1_restAndStructure'
%  'freesurferBinDir'     - Char vector. Full path to the freesurfer binary
%                           files.
%  'epiVoxelSizeMm'       - Scalar. Size of the EPI voxels.
%  'msecsTR'              - Scalar. TR of the fMRI data.
%  't1Dims'               - 1x3 vector. Dimensions of the T1 image as
%                           expressed in Flywheel viewer
%
% Outputs
%   none
%
%
% Examples:
%{
    % One subject with plots
    deriveCameraPosition('TOME_3011',[188 32 158],'sessionDir','session2_spatialStimuli','verbose',true,'showPlots',true)
%}
%{
    % The coords were obtained within the Flywheel image viewer for the
    % right cornea from the T1w_acpc_dc_restore.nii.gz image.
    dataArray = {...
                'TOME_3001', [189 29 160]; ...
                'TOME_3002', [190 23 162]; ...
                'TOME_3003', [187 24 154]; ...
                'TOME_3004', [194 33 151]; ...
                'TOME_3005', [180 35 157]; ...
                'TOME_3007', [194 31 157]; ...
                'TOME_3008', [194 35 153]; ...
                'TOME_3009', [194 35 152]; ...
                'TOME_3011', [188 32 158]; ...
                'TOME_3012', [185 28 158]; ...
                'TOME_3013', [184 34 157]; ...
                'TOME_3014', [194 30 155]; ...
                'TOME_3015', [183 35 155]; ...
                'TOME_3016', [187 34 153]; ...
                'TOME_3017', [186 38 155]; ...
                'TOME_3018', [195 31 158]; ...
                'TOME_3019', [189 35 153]; ...
                'TOME_3020', [189 26 160]; ...
                'TOME_3021', [192 26 155]; ...
                'TOME_3022', [190 33 154]; ...
                'TOME_3023', [192 21 159]; ...
                'TOME_3024', [191 33 152]; ...
                'TOME_3025', [188 30 155]; ...
                'TOME_3026', [189 30 162]; ...
                'TOME_3028', [186 28 164]; ...
                'TOME_3029', [186 38 154]; ...
                'TOME_3030', [188 24 157]; ...
                'TOME_3031', [185 31 159]; ...
                'TOME_3032', [192 35 155]; ...
                'TOME_3033', [190 29 153]; ...
                'TOME_3034', [188 35 151]; ...
                'TOME_3035', [192 29 158]; ...
                'TOME_3036', [194 35 157]; ...
                'TOME_3037', [192 31 155]; ...
                'TOME_3038', [187 35 160]; ...
                'TOME_3039', [183 36 155]; ...
                'TOME_3040', [189 32 155]; ...
                'TOME_3042', [189 28 158]; ...
                'TOME_3043', [192 31 153]; ...
                'TOME_3044', [188 31 155]; ...
                'TOME_3045', [187 29 155]; ...
                'TOME_3046', [190 25 161]  ...
                };
    for ii=1:size(dataArray,1)
        deriveCameraPosition(dataArray{ii,1}, dataArray{ii,2},'sessionDir','session1_restAndStructure')
    end
    for ii=1:size(dataArray,1)
        deriveCameraPosition(dataArray{ii,1}, dataArray{ii,2},'sessionDir','session2_spatialStimuli')
    end
%}

%% Parse vargin for options passed here
p = inputParser; p.KeepUnmatched = true;

% Required
p.addRequired('subject',@ischar);
p.addRequired('cornealCoord',@isnumeric);

% Optional display and I/O params
p.addParameter('verbose',true,@islogical);
p.addParameter('showPlots',false,@islogical);
p.addParameter('savePlots',true,@islogical);

% Optional environment params
p.addParameter('tbSnapshot',[],@(x)(isempty(x) | isstruct(x)));
p.addParameter('timestamp',char(datetime('now')),@ischar);
p.addParameter('hostname',char(java.lang.System.getProperty('user.name')),@ischar);
p.addParameter('username',char(java.net.InetAddress.getLocalHost.getHostName),@ischar);

% Optional analysis params
p.addParameter('processingDir',...
    getpref('mriTOMEAnalysis', 'TOMEProcessingPath'),@ischar);
p.addParameter('analysisDir', ...
    fullfile(getpref('mriTOMEAnalysis','TOMEAnalysisPath'),...
    'deriveCameraPositionFromHeadMotion'),@ischar);
p.addParameter('scratchSaveDir',getpref('flywheelMRSupport','flywheelScratchDir'),@ischar);
p.addParameter('sessionDir','session1_restAndStructure',@ischar);
p.addParameter('freesurferBinDir','/Applications/freesurfer/bin/',@ischar);
p.addParameter('fslBinDir','/usr/local/fsl/bin/',@ischar);
p.addParameter('epiVoxelSizeMm', 2, @isscalar);
p.addParameter('msecsTR', 800, @isscalar);
p.addParameter('t1Dims', [227 272 227], @isnumeric);
p.addParameter('rmseThreshold', 3, @isnumeric);


%% Parse and check the parameters
p.parse(subject, cornealCoord, varargin{:});


%% Define some strings used in system calls

% This string precedes system calls to freesurfer commands to set the
% environment variables
freesurferSetUp = 'export FREESURFER_HOME=/Applications/freesurfer; source $FREESURFER_HOME/SetUpFreeSurfer.sh; ';
fslSetUp = 'export FSLDIR=/usr/local/fsl; source ${FSLDIR}/etc/fslconf/fsl.sh; ';

% This string follows system calls to silence consult output
devNull = ' >/dev/null';

% Find the Scout EPI targets in the analysisDir
targetFiles = dir(fullfile(p.Results.analysisDir,p.Results.sessionDir,[subject '*' 'Scout_gdc.nii.gz']));

% Loop through the target files and project the eye coordinate in T1 space
% to scout EPI space
for ii=1:length(targetFiles)
    
    % Get the root name for this acquisition
    acquisitionRootName = strsplit(targetFiles(ii).name,'_Scout_gdc.nii.gz');
    acquisitionRootName = acquisitionRootName{1};
    
    % Assemble the file strings
    scoutFile = fullfile(targetFiles(ii).folder,targetFiles(ii).name);
    t1FileName = fullfile(targetFiles(ii).folder,[acquisitionRootName '_T1w_acpc_dc_restore_brain.nii.gz']);
    t12ScoutFileName = fullfile(p.Results.scratchSaveDir,[p.Results.subject '_T1_acpc2Scout_gdc_' num2str(tic()) '.nii.gz']);
    affineRegFile = fullfile(p.Results.scratchSaveDir,[p.Results.subject '_T1_acpc2Scout_gdc_' num2str(tic()) '.mat']);
    eyeVoxelT1File = fullfile(p.Results.scratchSaveDir,[p.Results.subject '_t1SpaceEyeCoord_' num2str(tic()) '.nii.gz']);
    eyeVoxelScoutFile = fullfile(p.Results.scratchSaveDir,[p.Results.subject '_ScoutSpaceEyeCoord_' num2str(tic()) '.nii.gz']);
    infoFile = fullfile(targetFiles(ii).folder,[acquisitionRootName '_sessionInfo.mat']);
    motionMatricesDir = fullfile(targetFiles(ii).folder,[acquisitionRootName '_MotionMatrices']);
    moveRegressorsFile = fullfile(targetFiles(ii).folder,[acquisitionRootName '_Movement_Regressors.txt']);
    
    % Create an affine transform between the T1 and Scout spaces
    command = [p.Results.fslBinDir 'flirt' ...
        ' -in ' escapeFileCharacters(t1FileName) ...
        ' -ref ' escapeFileCharacters(scoutFile) ...
        ' -omat ' escapeFileCharacters(affineRegFile) ...
        ' -out ' escapeFileCharacters(t12ScoutFileName) ...
        ' -dof 6' ...
        ];
    
    system([fslSetUp command devNull]);
    
    % Create a right eye corneal surface coordinate in the T1 space. Placed
    % in an eval function to silence console output
    evalc('eyeVoxelT1 = MRIread(escapeFileCharacters(t1FileName));');
    eyeVoxelT1.vol = eyeVoxelT1.vol.*0;
    
    % Place a point in the T1 volume corresponding to the right cornea The
    % coordinates in the flywheel viewer are SAL and one-indexed. By
    % subtracting those coordinates from some of the dimensions of the T1
    % image (also expressed in SAL order), we convert the coordinates in
    % IPR.
    coordSAL = cornealCoord;
    coordIPR = p.Results.t1Dims - coordSAL;
    
    % In matlab, the eyeVoxelT1.vol dimensions are posterior-anterior,
    % right-left, inferior-superior (PRI). Although the coordinates are
    % ostensibly one-indexed in the FLywheel viewer, we find we have to add
    % one to the coordinate values here to match up exactly with the
    % corresonding slice.
    coordPRI = [coordIPR(2) coordIPR(3) coordIPR(1)];
    eyeVoxelT1.vol(coordPRI(1)+1,coordPRI(2)+1,coordPRI(3)+1)=1e4;
    
    % Save the volume in a tmp location
    MRIwrite(eyeVoxelT1,escapeFileCharacters(eyeVoxelT1File));
    
    % Project the eyeVoxelT1 to the Scout_gdc space
    command = [p.Results.fslBinDir 'flirt' ...
        ' -in ' escapeFileCharacters(eyeVoxelT1File) ...
        ' -ref ' escapeFileCharacters(scoutFile) ...
        ' -applyxfm -init ' escapeFileCharacters(affineRegFile) ...
        ' -out ' escapeFileCharacters(eyeVoxelScoutFile) ...
        ];    
    system([fslSetUp command devNull]);
    
    % Load the resulting volume
    evalc('eyeVoxelScout = MRIread(escapeFileCharacters(eyeVoxelScoutFile));');
    
    % Get the dimensions of the scout volume
    scoutDims = size(eyeVoxelScout.vol);
    
    % Find the eye voxel coordinate. This will be in PRI orientation
    [~,ind] = max(eyeVoxelScout.vol(:));
    [eyeVoxelPRI(1), eyeVoxelPRI(2), eyeVoxelPRI(3)] = ind2sub(scoutDims,ind);
    
    % Find the position of the eyeVoxel in mm relative to the [0 0 0]
    % coordinate position, as this is what is used by MCFLIRT to produce
    % the motion matrices. Need to find out if MCFLIRT has the origin in
    % the center or edge of the [0 0 0] voxel. Currently assumes the
    % center.
    eyeVoxelPRImm = (eyeVoxelPRI - [1 1 1]) .* p.Results.epiVoxelSizeMm;
    
    % Covert dimension order from PRI to RPI, as this is the order of
    % dimensions for the rotation matrices.
    eyeVoxelRPImm = eyeVoxelPRImm([2 1 3]);
            
    % Determine the corresponding video acquisition stem
    dataLoad = load(infoFile);
    sessionInfo = dataLoad.sessionInfo;
    clear dataLoad
    
    % Load the set of motionMatrices
    motionMats = {};
    % Remarkably, the dir command fails to find the directory if the
    % special characters are escaped, so we do not do so in this command
    matList = dir([motionMatricesDir '/MAT*']);
    for jj = 1:length(matList)
        m = readmatrix(fullfile(matList(jj).folder,matList(jj).name),'FileType','text','Range',[1 1 4 4]);
        motionMats{jj} = m(1:4,1:4);
    end
    
    % Handle the special case of TOME_3019, 042617
    if strcmp(sessionInfo.subject,'TOME_3019') && strcmp(sessionInfo.date,'042617')
        sessionInfo.date = '042617a';
    end
    
    % Convert the rootName format of the run number
    tmpString = strsplit(acquisitionRootName,[sessionInfo.subject '_' ]);
    tmpString = tmpString{2};
    tmpString = strrep(tmpString,'run1','run01');
    tmpString = strrep(tmpString,'run2','run02');
    tmpString = strrep(tmpString,'run3','run03');
    tmpString = strrep(tmpString,'run4','run04');
    tmpString = strrep(tmpString,'Run1','run01');
    tmpString = strrep(tmpString,'Run2','run02');
    tmpString = strrep(tmpString,'Run3','run03');
    tmpString = strrep(tmpString,'Run4','run04');
    videoAcqStemName = fullfile(p.Results.processingDir,p.Results.sessionDir,sessionInfo.subject,sessionInfo.date,'EyeTracking',tmpString);
    
    % Create the relativeCameraPosition
    relativeCameraPosition = calcRelativeCameraPosition(motionMats, videoAcqStemName, eyeVoxelRPImm, p.Results.msecsTR);
    
    % Store the pre-rotated relativeCameraPosition
    preRotateRelativeCameraPosition = relativeCameraPosition;
    
    % Rotate the relativeCameraPosition to best match the pupilData. The
    % relativeCamera position variable is calculated from head motion
    % relative to the coordinate frame of the Scout image. The camera is
    % not necessarily aligned with this coordinate frame, as the head may
    % be tilted. Consider the case in which the camera is positioned to
    % the side of the head, aimed towards the eyes. In this case,
    % horizontal head movements (w.r.t. the Scout coordinate frame) will
    % not produce any change in the location of the pupil center in the
    % camea coordinate frame. To accout for this, we identify the rotation
    % (and scaling) of the camera RL and IS positions that best match the
    % change in location in the RL and IS pupil centers over the course of
    % the acquisition.
    % We also compute the small shift in time that best matches the head
    % and camera motion measurements
    maxFrameShift = ((p.Results.msecsTR/1000)*60)/2;
    [relativeCameraPosition, adjustParams] = ...
        alignCoordinates(relativeCameraPosition,videoAcqStemName, p.Results.rmseThreshold, maxFrameShift);
    
    % add meta data
    relativeCameraPosition.meta = p.Results;
    relativeCameraPosition.meta.sessionInfo = sessionInfo;
    
    % Save the relativeCameraPosition variable
    outCameraPositionFile = [videoAcqStemName '_relativeCameraPosition.mat'];
    save(outCameraPositionFile,'relativeCameraPosition');
    
    % Plot the relativeCameraPosition variables
    if p.Results.showPlots || p.Results.savePlots
        if p.Results.showPlots
            plotFig = figure('Name',acquisitionRootName);
        else
            plotFig = figure('Name',acquisitionRootName,'Visible','off');
        end
        subplot(2,1,1)        
        plot(relativeCameraPosition.values(1,:));
        hold on
        plot(relativeCameraPosition.values(2,:));
        plot(relativeCameraPosition.values(3,:));
        ylim([-4 4]);
        legend({'+right','+up','+further'})
        tLine1 = ['Relative camera position (world coordinates) - ' acquisitionRootName ];
        tLine2 = ['theta [deg] = ' num2str(adjustParams(2)) '; pixelsPerMm = ' num2str(adjustParams(3)) '; frameShift = ' num2str(adjustParams(1))];
        tString = {tLine1,tLine2};
        title(tString,'Interpreter','none');
        xlabel('time [frames]');
        ylabel('translation [mm]');

        subplot(2,1,2)        
        plot(preRotateRelativeCameraPosition.values(1,:));
        hold on
        plot(preRotateRelativeCameraPosition.values(2,:));
        plot(preRotateRelativeCameraPosition.values(3,:));
        ylim([-4 4]);
        legend({'+right','+up','+further'})
        tLine1 = ['Pre-rotation camera position'];
        tString = {tLine1};
        title(tString,'Interpreter','none');
        xlabel('time [frames]');
        ylabel('translation [mm]');

        if p.Results.savePlots
            tmp = [videoAcqStemName '_relativeCameraPosition_QA.pdf'];
            print(plotFig,tmp,'-dpdf');
            close(plotFig)
        end
    end
    
    % Report completion of this step
    if p.Results.verbose
        reportLineOut = sprintf([acquisitionRootName]);
        fprintf([reportLineOut ' \n']);
    end
    
    % Clean up the tmp files
    delete([t12ScoutFileName]);
    delete([affineRegFile]);
    delete([eyeVoxelT1File]);
    delete([eyeVoxelScoutFile]);
    
end

end % deriveCameraPosition




function relativeCameraPosition = calcRelativeCameraPosition(motionMats, videoAcqStemName, eyeVoxelRPImm, msecsTR)

% Load the head motion regressors
numTRs = length(motionMats);
eyePositionRPImm = nan(numTRs,3);

% For each TR, we obtain the inverse of the motion matrix, which is then
% used to project where the eye voxel (in Scout space) was located in space
% with respect to the Scout coordinate system at each TR.
for ii = 1:numTRs
    
    % Get the inverse of this matrix
    m = motionMats{ii};
    mPrime = m;
    mPrime(1:3,4) = -inv(m(1:3,1:3)) * m(1:3,4);
    mPrime(1:3,1:3)=inv(m(1:3,1:3));
        
    % Rotate the eye position
    newEyePosition = mPrime * [eyeVoxelRPImm 1]';
    
    % Store the newEyePosition
    eyePositionRPImm(ii,:)=newEyePosition(1:3);
end

% Make eye position relative to the initial time point. We are currently in
% the RPI coordinate order
eyePositionRPImm = eyePositionRPImm-eyePositionRPImm(1,:);

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


%% Switch axes to camera world coordinates.
% Up until this point, the coordinates have described the position of the
% head, relative to its own (subject) coordinate frame. The
% eyePositionRPImm variable describes the position of the right corneal
% surface relative to its initial position. For example, a positive value in the first
% dimension indicates that the eye has moved from the subject's right
% towards the subject's left. We now wish to switch the expression of
% position to be the movement of the video camera relative to fixed
% coordinate of the corneal surface of the right eye of the subject.
%
% This coordinate frame is in mm units and has the dimensions (X,Y,Z).
% The diagram is of a cartoon head (taken from Leszek Swirski), being
% viewed from above:
%
%    ^
%    |
%    |    .-.
% -Z |   |   | <- Head
%    +   `^u^'
% +Z |
%    |
%    |      W <- Camera    (As seen from above)
%    V
%
%     <-----+----->
%        -X   +X
%
% +X = right
% +Y = up
% +Z = front (towards the camera)
%
% Thus:
% - Displacement of the eye from (subject's) right --> left (+ in RPI)
%   corresponds to -X camera movement in world coordinates
% - Disolacement of the eye from (subject's) posterior --> anterior (+ in
%   RPI) corresponds to -Z movement of the camera.
% - Displacement of the eye from the (subject's) inferior --> superior (+
%   in RPI) corresponds to -Y movement of the camera.
%
% The scanner coordinates x,y,z correspond to right-left, posterior-
% anterior, inferior-superior. The camera world coordinates are x,y,z
% corresponding to right-left, down-up, back-front (towards the camera).
scanToCameraCoords = [1,3,2];
scanToCameraSign = [1,-1,1];

% Loop over the world coordinate dimensions and create the relative camera
% position vector, with a length equal to the timebase of the video
% acquisition. Interpolate from the coarse TR sampling to the fine video
% sampling.
for dd = 1:3
    relativeCameraPosition.values(scanToCameraCoords(dd),:) = scanToCameraSign(dd) .* ...
        [zeros(1,nElementsPre) ...
        -interp1(scanTimebase,eyePositionRPImm(:,dd),eyeTrackTimebase,'PCHIP') ...
        -repmat(eyePositionRPImm(end,dd),1,nElementsPost)];
end

end


function [adjustedRelativeCameraPosition, adjustParams] = alignCoordinates(relativeCameraPosition,videoAcqStemName,rmseThreshold,maxFrameShift)

% Load the pupilData
load([videoAcqStemName '_pupil.mat'],'pupilData');

% Load the timebase
load([videoAcqStemName '_timebase.mat'],'timebase');

% Find the "good" frames after the start of the scan
[~,startFrame] = min(abs(timebase.values));
goodIdx = logical(double(pupilData.initial.ellipses.RMSE < rmseThreshold) .* ...
    (timebase.values > startFrame));

% Create a matrix of xy locations of the pupil center.
B = [pupilData.initial.ellipses.values(goodIdx,1), ...
    pupilData.initial.ellipses.values(goodIdx,2)]';

% Create weight vector
weights = 1./pupilData.initial.ellipses.RMSE(goodIdx)';

% Set the pupilCenter position to be relative to the mean position prior to
% time zero
notNanIdx = find(~isnan(pupilData.initial.ellipses.RMSE(1:startFrame)));
w = 1./pupilData.initial.ellipses.RMSE(notNanIdx);
refCenter = mean(w.*pupilData.initial.ellipses.values(notNanIdx,1:2))';
B = B-refCenter;

% We have to invert the value of the x dimension of B so that the rotation
% matrix will not flip this around.
B(1,:) = -B(1,:);

% Create a matrix of x'y' locations of the camera in the Scout coordinate
% frame
A = [relativeCameraPosition.values(1,:)', ...
    relativeCameraPosition.values(2,:)']';

% Set up some anonymous functions for the fit
R = @(theta) [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
modelAtIdx = @(vec) vec(:,goodIdx);
pupilPositionFit = @(p) (censorShift(A,p(1))'*R(p(2)).*p(3))';
myObj = @(p) sqrt(nansum(nansum( (B-modelAtIdx(pupilPositionFit(p))).^2 ).*weights)./sum(weights) );

% Perform the fit. The parameters ae in the order of:
%   adjustParams(1) = frame shift
%   adjustParams(2) = theta (deg)
%   adjustParams(3) = scale (pixelsPerMm)
options = optimoptions(@fmincon,...
    'Display','off');
adjustParams = fmincon(myObj,[0 0 10],[],[],[],[],[-maxFrameShift -22.5 10],[+maxFrameShift 22.5 20],[],options);

% Obtain the adjustedRelativeCameraPosition
pupilPositionFitNoScale = @(p) (censorShift(A,p(1))'*R(p(2)))';
fitResult = pupilPositionFitNoScale(adjustParams);
adjustedRelativeCameraPosition = relativeCameraPosition;
adjustedRelativeCameraPosition.values(1,:) = fitResult(1,:);
adjustedRelativeCameraPosition.values(2,:) = fitResult(2,:);
adjustedRelativeCameraPosition.meta.adjustParams = adjustParams;

end


function vecOut = censorShift(vecIn,frameShift)
for jj = 1:size(vecIn,1)
    vecOut(jj,:) = fshift(vecIn(jj,:),frameShift);
    if frameShift<0
        vecOut(jj,end+round(frameShift):end)=nan;
    end
    if frameShift>0
        vecOut(jj,1:round(frameShift))=nan;
    end
end
end

function nameOut = escapeFileCharacters(nameIn)
% Sanitize file strings to be used in system commands

nameOut = strrep(nameIn,' ','\ ');
nameOut = strrep(nameOut,'(','\(');
nameOut = strrep(nameOut,')','\)');
end