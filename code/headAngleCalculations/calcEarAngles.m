% calcEarAngles.m
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
resultSaveDirStem = fullfile(getpref('mriTOMEAnalysis','TOMEAnalysisPath'),'calcEarAngles');
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

% The list of canals
canals = {'lateral','anterior','posterior'};

% Save the warn state and turn off a warning
warnState = warning();
warning('off','MATLAB:table:ModifiedAndSavedVarnames');

% Loop through canals
for cc = 1:3
    
    % Loop through the session
    for ii = 1:numel(sessions)
        
        % Get the session label
        sessionLabel = sessions{ii}.label;
        
        % Get the subject label
        subjectLabel = sessions{ii}.subject.label;
        
        % Get the analyses object
        analyses = sessions{ii}.analyses();
        
        % Find the inner ear gear.
        gearNames = cellfun(@(x) x.gearInfo.name,analyses,'UniformOutput',false);
        idxEarGear = find(cellfun(@(x) contains(x,'tome-calculate-inner-ear-angles'),gearNames));
        
        % If there is no inner ear, move on
        if isempty(idxEarGear)
            continue
        end
        
        % Grab the analysis
        analysis = analyses{idxEarGear};
        
        % If there are no files, we are still processing, so move on
        if isempty(analysis.files)
            continue
        end
        
        % Find which file is the csv file
        fileIdx = find(cellfun(@(x) contains(x.name,'_CanalAnglesWithB0.csv'),analysis.files));
        
        % If there are no files, we are still processing, so move on
        if isempty(fileIdx)
            continue
        end
        
        fileName = analysis.files{fileIdx}.name;
        
        % Download the csv results
        tmpPath = fullfile(scratchSaveDir,fileName);
        fw.downloadOutputFromAnalysis(analysis.id,fileName,tmpPath);
        
        % Load the csv file into memory
        T = readtable(tmpPath);
        
        % Report the values for this subject to the screen
        str = sprintf([subjectLabel '\t' sessionLabel '\t ' canals{cc} ' canal angles [R,L]:\t%2.1f\t%2.1f'],T{(cc-1)*2+1,3},T{(cc-1)*2+2,3});
        disp(str);
        
    end % Loop over session
    
    fprintf('\n\n');
    
end % Loop over canals

% Restore warn state
warning(warnState);