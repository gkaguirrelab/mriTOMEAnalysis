


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
devNull = ' >/dev/null';

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
    sessionLabelIdx = startsWith(thisSession.label,sessionLabelPrefix);

    % This is not the session you are looking for: move along, move along.
    if sum(sessionLabelIdx)==0
        continue
    end

    % More than one session matches this stem.
    if sum(sessionLabelIdx)>1
        error('This subject has more than one session of this type that contains this analysis');
    end

    % Time the loop from here
    timerVal = tic;

    % Get the subject ID, session label, and study date
    thisSubject = thisSession.subject.code;
    thisSessionLabel = thisSession.label;
    timeFormat = 'mmddyy';
    thisSessionDate = datestr(thisSession.timestamp,timeFormat);
    
    % Download the matching file to the rootSaveDir
    thisName = thisAnalysis.files{analysisFileMatchIdx}.name;
    zipFileName = fw.downloadOutputFromAnalysis(thisAnalysis.id,thisName,fullfile(scratchSaveDir,thisName));

    % Unzip the downloaded file; overwright existing; pipe the terminal
    % output to dev/null
    command = ['unzip -o -a ' zipFileName ' -d ' zipFileName '_unzip' devNull];
    system(command);

    % Derive the saveStem from the analysisFile name
    tmp = strsplit(thisName,outputFileSuffix);
    saveStem = tmp{1};

    % Save a .mat file with session label, study date, and subject
    sessionInfo.subject = thisSubject;
    sessionInfo.session = thisSessionLabel;
    sessionInfo.date = thisSessionDate;    
    destinationFile = fullfile(resultSaveDirStem,sessionLabelReplacement{sessionLabelIdx},[saveStem '_sessionInfo.mat']);
    save(destinationFile,'sessionInfo');

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
    
    % Record the time    
    minutesPassed = toc(timerVal)/60;
    
    % Report completion of this step
    reportLineOut = [sessionLabelReplacement{sessionLabelIdx} ' - ' saveStem];
    fprintf([reportLineOut ' - %2.1f mins \n'],minutesPassed);
end
