


projectName = 'tome';
gearName = 'hcp-func';
scratchSaveDir = getpref('flywheelMRSupport','flywheelScratchDir');
resultSaveDirStem = '/Users/aguirre/Dropbox (Aguirre-Brainard Lab)/TOME_analysis/deriveCameraPositionFromHeadMotion';
outputFileSuffix = '_hcpfunc.zip';
resultFileSuffix = {'Movement_Regressors.txt','Scout_gdc.nii.gz','DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased/EPItoT1w.dat'};
sessionLabelPrefix = {'Session 1','Session 2'};
sessionLabelPrefix = {'Session 1'};
sessionLabelReplacement = {'session1_restAndStructure','session2_spatialStimuli'};
sessionLabelReplacement = {'session1_restAndStructure'};

%% Instantiate the flywheel object
fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));

%% Find all analyses of the specified gear
searchStruct = struct(...
    'returnType', 'analysis', ...
    'filters', {{...
    struct('wildcard', struct('analysis0x2elabel', ['*' gearName '*'])), ...
    struct('match', struct('project0x2elabel', projectName))
    }} ...
    );
analyses = fw.search(searchStruct, 'size', '1000');

%% Loop through the analyses and download
for ii = 1:numel(analyses)
    
    % Get the analysis object
    thisAnalysis = fw.getAnalysis(analyses{ii}.analysis.id);
    
    % Find the file with the matching stem
    analysisFileMatchIdx = cellfun(@(x) endsWith(x.name,outputFileSuffix),thisAnalysis.files);
    
    % Sanity checking for one matching file
    if sum(analysisFileMatchIdx)~=1
        warning('There are either zero or more than one files found for this analysis; skipping');
        continue
    end
        
    % Get the session info for this analysis
    thisSession = fw.getSession(thisAnalysis.parent.id);
    sessionLabelIdx = startsWith(sessionLabelPrefix,thisSession.label);

    % This is not the session you are looking for: move along, move along.
    if sum(sessionLabelIdx)==0
        continue
    end

    % More than one session matches this stem.
    if sum(sessionLabelIdx)>1
        error('This subject has more than one session of this type that contains this analysis');
    end

    % Get the subject ID
    thisSubject = thisSession.subject.code;
   
    % Download the matching file to the rootSaveDir
    thisName = thisAnalysis.files{analysisFileMatchIdx}.name;
    zipFileName = fw.downloadOutputFromAnalysis(thisAnalysis.id,thisName,fullfile(scratchSaveDir,thisName));

    % Unzip the downloaded file; overwright existing; pipe the terminal
    % output to dev/null
    command = ['unzip -o -a ' zipFileName ' -d ' zipFileName '_unzip >/dev/null'];
    system(command);

    % Derive the saveStem from the analysisFile name
    tmp = strsplit(thisName,outputFileSuffix);
    saveStem = tmp{1};
    
    % Copy the result files to the resultsSaveDir. If there are
    % duplicates of the target file, just copy the first.
    for jj=1:length(resultFileSuffix)
        dirCommand = [zipFileName '_unzip/**/' resultFileSuffix{jj}];
        targetFiles = dir(dirCommand);
        sourceFile = fullfile(targetFiles(1).folder,targetFiles(1).name);
        destinationFile = fullfile(resultSaveDirStem,sessionLabelReplacement{sessionLabelIdx},[saveStem '_' targetFiles(1).name]);
        copyfile(sourceFile,destinationFile);
    end
    
    % Delete the downloaded files in the scratch dir
    rmdir([zipFileName '_unzip'], 's');
    delete(zipFileName);
    
    % Report completion of this step
    reportLineOut = [sessionLabelReplacement{sessionLabelIdx} ' - ' saveStem];
    fprintf([reportLineOut '\n']);
end



%
%
%
%
% movementTable = readtable('Movement_Regressors.txt','Delimiter','space','MultipleDelimsAsOne',true);
%
% t1EyeVoxel = [72, 250, 42];
% t1VoxelSizeMm = 0.8;
% epiVoxelSizeMm = 2.0;
% epiEyeVoxel =  t1EyeVoxel .* t1VoxelSizeMm ./ epiVoxelSizeMm;
%
% epiDims = [104, 104, 72];
% epiCenterVoxelCoord = epiDims ./2;
%
% eyeCoordMm = (epiEyeVoxel-epiCenterVoxelCoord).*epiVoxelSizeMm;
%
% for ii = 1:size(movementTable,1)
%     T = eye(4);
%     T(4,1:3)=table2array(movementTable(ii,1:3));
%     R.x = [1 0 0; 0 cosd(movementTable{ii,4}) -sind(movementTable{ii,4}); 0 sind(movementTable{ii,4}) cosd(movementTable{ii,4})];
%     R.y = [cosd(movementTable{ii,5}) 0 sind(movementTable{ii,5}); 0 1 0; -sind(movementTable{ii,5}) 0 cosd(movementTable{ii,5})];
%     R.z = [cosd(movementTable{ii,6}) -sind(movementTable{ii,6}) 0; sind(movementTable{ii,6}) cosd(movementTable{ii,6}) 0; 0 0 1];
%     Rzyx = R.z * R.y * R.x;
%     eyePosition(ii,:)=Rzyx * eyeCoordMm';
% end
%
% eyePosition = eyePosition-eyePosition(1,:);
%
% scanDeltaT = 800;
% eyeTrackDeltaT = mean(diff(timebase.values));
%
% scanTimebase = 0:800:800*(420-1);
% eyeTrackTimebase = 0:eyeTrackDeltaT:(800*420)-eyeTrackDeltaT;
%
% nElementsPre = sum(timebase.values<0);
% nElementsPost = sum(timebase.values>max(eyeTrackTimebase));
% nElementsMid = numel(eyeTrackTimebase);
%
% relativeCameraPosition = zeros(3,length(timebase.values));
%
% % The scanner coordinates x,y,z correspond to right-left,
% % posterior-anterior, inferior-superior. The camera world coordinates are
% % x,y,z corresponding to right-left, down-up, back-front (towards the
% % camera)
% scanToCameraCoords = [1,3,2];
%
% for dd = 1:3
%     relativeCameraPosition(scanToCameraCoords(dd),:) = [zeros(1,nElementsPre) ...
%         -interp1(scanTimebase,eyePosition(:,dd),eyeTrackTimebase,'PCHIP') ...
%         -repmat(eyePosition(end,dd),1,nElementsPost)];
% end

