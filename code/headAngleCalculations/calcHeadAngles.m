% calcHeadAngles.m
%
% The HCP LifeSpan scanning protocol automatically defines the field of
% view of the acquisitions based upon an initial measurement (the auto
% align head scout, or AAHScout). This includes rotating the field of view
% into oblique positions. The purpose of this routine is to use the field
% of view information present in the T2 image of each session to derive the
% position of the head with regard to the scanner coordinates. To do so, we
% find the T2 images in the Flywheel database, and then obtain the values
% in the ImageOrientationPatient DICOM field. This field specifies the
% orientation of the imaging plane with respect to the scanner coordinates
% with a set of directional cosines (the xyz rows, and then the xyz
% columns). We then calculate the normal to the plane, allowing us to
% reconstruct an entire rotation matrix. This rotation matrix is then
% converted to Euler angles to provide the roll, pitch, and yaw of the
% head. By examining the AAHScout images from different subjects, I have
% determined that the interpretation of the angles is as follows:
%
% Yaw:	(-) head turned to the right
%       (+) head turned to the left
%
% Pitch:(-) head pitched downwards
%       (+) head pitched upwards
%
% Roll: (-) head tilted towards right shoulder
%       (+) head tilted towards left shoulder
%


sessionLabel = 'session1_restAndStructure';
projectName = 'tome';
gearName = 'hcp-func';
scratchSaveDir = getpref('flywheelMRSupport','flywheelScratchDir');
resultSaveDirStem = fullfile(getpref('mriTOMEAnalysis','TOMEAnalysisPath'),'calcHeadAngles');
outputFileSuffix = '_hcpfunc.zip';
resultFileSuffix = {'Movement_Regressors.txt','Scout_gdc.nii.gz','MotionMatrices','DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased/T1w_acpc_dc_restore_brain.nii.gz'};
resultIsDir = [0 0 1 0];

devNull = ' >/dev/null';

% If the scratch dir does not exist, make it
if ~exist(scratchSaveDir,'dir')
    mkdir(scratchSaveDir)
end

%% Instantiate the flywheel object
fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));

% Find the first project with a label of 'My Project'
project = fw.projects.findFirst(['label=' projectName]);

% Find all sessions that are labeled session 1
sessions_1 = project.sessions.find(['label=' 'Session 1']);
sessions_1a = project.sessions.find(['label=' 'Session 1a']);
sessions_1b = project.sessions.find(['label=' 'Session 1b']);

% Concatenate the list of sessions
sessions = [sessions_1; sessions_1a; sessions_1b];

%% Loop through the session
for ii = 1:numel(sessions)
    
    % Get the session label
    sessionLabel = sessions{ii}.label;
    
    % Get the acquisitions object
    acquisitions = sessions{ii}.acquisitions();
    
    % Find the T2 acquisition. We use this because sometimes there was an
    % axial and sagittal T1 acquired in the same session.
    acqLabels = cellfun(@(x) x.label,acquisitions,'UniformOutput',false);
    idxT2 = find(cellfun(@(x) contains(x,'T2w'),acqLabels));
    
    % If there is no T2 acquisition, move on
    if isempty(idxT2)
        continue
    end
    
    % Grab the acquisition
    acquisition = acquisitions{idxT2};
    
    % For some reason, Flywheel requires that we reload the ibject
    % to get all the juicy meta-data
    acquisition = acquisition.reload();
    
    % Find the nifti file
    idxFile = find(cellfun(@(x) strcmp(x.type,'nifti'),acquisition.files));
    
    % If there is no nifti file, move on
    if isempty(idxFile)
        continue
    end
    
    file = acquisition.files{idxFile};
    
    % Get the subject ID
    subId = acquisition.parents.subject;
    subject = fw.get(subId);
    
    % Derive [yaw pitch roll] from ImageOrientationPatientDICOM
    iop = file.info.ImageOrientationPatientDICOM;
    xyzR = iop(1:3);
    xyzC = iop(4:6);
    xyzS = [ (xyzR(2) * xyzC(3)) - (xyzR(3) * xyzC(2)) ; ...
        (xyzR(3) * xyzC(1)) - (xyzC(1) * xyzC(3)) ; ...
        (xyzR(1) * xyzC(2)) - (xyzR(2) * xyzC(1))  ...
        ];
    m = [xyzR xyzC xyzS];
    YPR = rad2deg(rotm2eul(m,'ZYX'));
    
    % Wrap the RPY values to center on zero
    YPR = YPR + [-90 0 90];
    
    % Report the values for this subject to the screen
    str = sprintf([subject.label ', ' sessionLabel ', YPR values: [%2.1f, %2.1f, %2.1f]'],YPR);
    disp(str);

end % Loop over session
