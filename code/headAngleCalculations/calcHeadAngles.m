% calcHeadAngles.m
%
% This script identifies 
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

%% Loop through the analyses and download
for ii = 1:numel(sessions)
    
    % Get the acquisitions object
    acquisitions = sessions{ii}.acquisitions();
    
    % Find the T1 acquisition
    acqLabels = cellfun(@(x) x.label,acquisitions,'UniformOutput',false);
    idxT1 = find(cellfun(@(x) contains(x,'T1w'),acqLabels));
    
    % Get the acquisition and reload it. For some reason Flywheel needs
    % this step to make the annotations available
    if isempty(idxT1) == 0
        acquisition = acquisitions{idxT1};
        acquisition = acquisition.reload();

        % Find the nifti file
        idxFile = find(cellfun(@(x) strcmp(x.type,'nifti'),acquisition.files));
        file = acquisition.files{idxFile};

        try
           check = file.info.roi;
        end

        if exist('check')
            % Grab the ROI structures if annotations exist
             if isstruct(file.info.roi)
                 rois = file.info.roi;

                % Need to go into the elements of the cell/structure here to
                % figure out which ones are which
                    for annot = 1:numel(rois)
                        if isfield(rois,'description')
                            if isequal(rois(annot).description,'midline falx')
                                xStart = rois(annot).handles.start.x;
                                yStart = rois(annot).handles.start.y;
                                xEnd = rois(annot).handles.end.x;
                                yEnd = rois(annot).handles.end.y;
                                angle = atan2(yEnd-yStart,xEnd-xStart);
                                rois(annot).interhemisphericFissureAngle = angle;

                                %print values
                                subId = acquisition.parents.subject;
                                subject = fw.get(subId);
                                disp(subject.label);
                                fprintf('ImageOrientationPatient: ');
                                disp(file.info.ImageOrientationPatientDICOM);
                                fprintf('interhemisphericFissureAngle: ');
                                disp(rois(annot).interhemisphericFissureAngle);

                            end
                        end
                    end
             end

             if iscell(file.info.roi)
                rois = file.info.roi;
                    for annot = 1:length(rois)
                       if isfield(rois{annot,1},'description')
                           if isequal(rois{annot,1}.description,'midline falx')
                               xStart = rois{annot,1}.handles.start.x;
                               yStart = rois{annot,1}.handles.start.y;
                               xEnd = rois{annot,1}.handles.end.x;
                               yEnd = rois{annot,1}.handles.end.y;
                               angle = atan2(yEnd-yStart,xEnd-xStart);
                               rois{annot,1}.interhemisphericFissureAngle = angle;

                               %print values
                               subId = acquisition.parents.subject;
                               subject = fw.get(subId);
                               disp(subject.label);
                               fprintf('ImageOrientationPatient: ');
                               disp(file.info.ImageOrientationPatientDICOM);
                               fprintf('interhemisphericFissureAngle: ');
                               disp(rois{annot,1}.interhemisphericFissureAngle);
                           end
                       end
                    end
             end
             clear check;
        end
    end
end