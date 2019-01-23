function analyzeWholeBrain(subjectID, runName, varargin)
% Complete analysis pipeline for analyzing resting state data, ultimately
% producing maps
%
% Syntax:
%  analyzeWholeBrain(subjectID, runName)
%
% Description:
%  This routine performs the analysis pipeline for functional BOLD data
%  from resting state runs. Basic analysis steps include to 1) download the
%  necessary data off of flywheel, 2) register the functional volume to the
%  structural volume in subject native space, 3) extract white matter and
%  ventricular signals to be used as nuisance regressors, 4) extract time
%  series from each gray matter voxel in the functional volume, 5) regress
%  out signals from physio, motion, white matter, and ventricles to yield
%  cleaned time series, and 6) regress out a series of eye signals extracted
%  from pupillometry and create maps out of these statistics.
%
%  This routien also requires several pieces of pre-installed software.
%  These include FSL and AFNI.
%
% Inputs:
%  subjectID:           - a string that identifies the relevant subject (i.e.
%                         'TOME_3040'
%  runName:             - a string that identifies the relevant run (i.e.
%                         'rfMRI_REST_AP_Run3')
%
% Optional key-value pairs:
%  skipPhysioMotionWMVRegression  - a logical, with false set as the
%                         default. If true, regressors will be created out
%                         of motion parameters, physiology parameters, and
%                         mean white matter and ventricular signals. One
%                         reason to is when using output from ICAFix, which
%                         we believe will have already dealed with these
%                         nuisance signals.
%  fileType             - a string that controls which type of functional
%                         file is to be processed. Options include 'volume'
%                         and 'CIFTI'. Note that for now, 'volume' is
%                         intended to be analyzed in subject-native space,
%                         and 'CIFTI' in MNI volume, freeSurfer cortical
%                         surface space.
%  covariatesToAnalyze  - a cell array, the contents of which are a string,
%                         that specify which covariates to analyze. Options
%                         include the default (a subset of our eye signals)
%                         or 'flash', which makes the basic box car for
%                         flash runs
% Outputs:
%  None. Several maps are saved out to Dropbox, however.

%% Input parser
p = inputParser; p.KeepUnmatched = true;

p.addParameter('skipPhysioMotionWMVRegression', false, @islogical);
p.addParameter('covariatesToAnalyze', {'pupilDiameter', 'pupilChange', 'eyeDisplacement'}, @iscell);
p.addParameter('fileType', 'volume', @ischar);

p.parse(varargin{:});
%% Define paths
[ paths ] = definePaths(subjectID);

freeSurferDir = paths.freeSurferDir;
anatDir = paths.anatDir;
pupilDir = paths.pupilDir;
functionalDir = paths.functionalDir;
outputDir = paths.outputDir;

%% Get the data and organize it

% getSubjectData(subjectID, runName);

%% Register functional scan to anatomical scan

if strcmp(p.Results.fileType, 'volume')
    [ ~ ] = registerFunctionalToAnatomical(subjectID, runName);
    
    %% Smooth functional scan
    functionalFile = fullfile(functionalDir, [runName, '_native.nii.gz']);
    [ functionalScan ] = smoothVolume(functionalFile);
    %% Get white matter and ventricular signal
    % make white matter and ventricular masks
    targetFile = (fullfile(functionalDir, [runName, '_native.nii.gz']));
    
    aparcAsegFile = fullfile(anatDir, [subjectID, '_aparc+aseg.nii.gz']);
    
    if ~(p.Results.skipPhysioMotionWMVRegression)
        [whiteMatterMask, ventriclesMask] = makeMaskOfWhiteMatterAndVentricles(aparcAsegFile, targetFile);
        
        
        % extract time series from white matter and ventricles to be used as
        % nuisance regressors
        [ meanTimeSeries.whiteMatter ] = extractTimeSeriesFromMask( functionalScan, whiteMatterMask, 'whichCentralTendency', 'median');
        [ meanTimeSeries.ventricles ] = extractTimeSeriesFromMask( functionalScan, ventriclesMask, 'whichCentralTendency', 'median');
        clear whiteMatterMask ventriclesMask
    end
    %% Get gray matter mask
    makeGrayMatterMask(subjectID);
    structuralGrayMatterMaskFile = fullfile(anatDir, [subjectID '_GM.nii.gz']);
    grayMatterMaskFile = fullfile(anatDir, [subjectID '_GM_resampled.nii.gz']);
    [ grayMatterMask ] = resampleMRI(structuralGrayMatterMaskFile, targetFile, grayMatterMaskFile);
    
    %% Extract time series of each voxel from gray matter mask
    [ ~, rawTimeSeriesPerVoxel, voxelIndices ] = extractTimeSeriesFromMask( functionalScan, grayMatterMask);
    clear grayMatterMask
  
    %% Clean time series from physio regressors
    if ~(p.Results.skipPhysioMotionWMVRegression)
        
        physioRegressors = load(fullfile(functionalDir, [runName, '_puls.mat']));
        physioRegressors = physioRegressors.output;
        motionTable = readtable((fullfile(functionalDir, [runName, '_Movement_Regressors.txt'])));
        motionRegressors = table2array(motionTable(:,7:12));
        regressors = [physioRegressors.all, motionRegressors];
        
        % mean center these motion and physio regressors
        for rr = 1:size(regressors,2)
            regressor = regressors(:,rr);
            regressorMean = nanmean(regressor);
            regressor = regressor - regressorMean;
            regressor = regressor ./ regressorMean;
            nanIndices = find(isnan(regressor));
            regressor(nanIndices) = 0;
            regressors(:,rr) = regressor;
        end
        
        % also add the white matter and ventricular time series
        regressors(:,end+1) = meanTimeSeries.whiteMatter;
        regressors(:,end+1) = meanTimeSeries.ventricles;
        
        TR = functionalScan.tr; % in ms
        nFrames = functionalScan.nframes;
        
        
        regressorsTimebase = 0:TR:nFrames*TR-TR;
        
        % remove all regressors that are all 0
        emptyColumns = [];
        for column = 1:size(regressors,2)
            if ~any(regressors(:,column))
                emptyColumns = [emptyColumns, column];
            end
        end
        regressors(:,emptyColumns) = [];
        
        [ cleanedTimeSeriesMatrix, stats_physioMotionWMV ] = cleanTimeSeries( rawTimeSeriesPerVoxel, regressors, regressorsTimebase, 'meanCenterRegressors', false);
        clear stats_physioMotionWMV rawTimeSeriesPerVoxel meanTimeSeries regressors functionalScan
    else
        cleanedTimeSeriesMatrix = rawTimeSeriesPerVoxel;
        clear rawTimeSeriesPerVoxel functionalScan
    end
end

if strcmp(p.Results.fileType, 'CIFTI')
   %% Smooth the functional file
    functionalFile = fullfile(functionalDir, [runName, '_Atlas_hp2000_clean.dtseries.nii']);
    [ smoothedGrayordinates ] = smoothCIFTI(functionalFile);
    
    % mean center the time series of each grayordinate
    [ cleanedTimeSeriesMatrix ] = meanCenterTimeSeries(smoothedGrayordinates);
    
    % make dumnmy voxel indices. this doesn't really apply for grayordinate
    % based analysis, but the code is expecting the variable to at least
    % exist
    voxelIndices = [];
    
    clear smoothedGrayordinates
end

% save out cleaned time series
savePath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID);
if ~exist(savePath,'dir')
    mkdir(savePath);
end
save(fullfile(savePath, [runName, '_cleanedTimeSeries']), 'cleanedTimeSeriesMatrix', 'voxelIndices', '-v7.3');


%% Remove eye signals from BOLD data'
if ~strcmp(p.Results.covariatesToAnalyze, 'flash')
    [ covariates ] = makeEyeSignalCovariates(subjectID, runName);
    
    covariatesToAnalyze = p.Results.covariatesToAnalyze;
elseif strcmp(p.Results.covariatesToAnalyze, 'flash')
    covariatesToAnalyze = {'flash'};
    
    TR = 0.8*1000;
    % make stimulus struct
    % use same deltaT as the TR, so all of our regressors are on the same
    % timebase
    deltaT = 0.8*1000;
    totalTime = 336*1000;
    stimulusStruct.timebase = 0:deltaT:totalTime-TR;
    
    % light-on or light-off segments last 12 seconds
    segmentLength = 12*1000;
    numberOfBlocks = totalTime/segmentLength;
    stimulusStruct.values = zeros(1,length(stimulusStruct.timebase));
    
    % actually make the stimulus profile. we find the boundaries of the 12-s
    % chunks, then make the values in between 1 if it's an even-numbered chunk
    % otherwise they're left as 0.
    for bb = 1:numberOfBlocks
        firstIndex = find(stimulusStruct.timebase == (bb - 1) * segmentLength);
        secondIndex = find(stimulusStruct.timebase == (bb) * segmentLength) - 1;
        if isempty(secondIndex)
            secondIndex = length(stimulusStruct.timebase);
        end
        if round(bb/2) == bb/2
            stimulusStruct.values(firstIndex:secondIndex) = 1;
        end
        
    end
    
    [ flashConvolved ] = convolveRegressorWithHRF(stimulusStruct.values', stimulusStruct.timebase);
    
    
    covariates.FlashConvolved = flashConvolved;
    covariates.firstDerivativeFlashConvolved = diff(covariates.FlashConvolved);
    covariates.firstDerivativeFlashConvolved = [NaN, covariates.firstDerivativeFlashConvolved];
end

templateFile = functionalFile;

for cc = 1:length(covariatesToAnalyze)
    regressors = [covariates.([covariatesToAnalyze{ii}, 'Convolved']); covariates.(['firstDerivative', upper(covariatesToAnalyze{ii}(1)), covariatesToAnalyze{ii}(2:end), 'Convolved'])];
    [ ~, stats.(covariatesToAnalyze{ii}) ] = cleanTimeSeries( cleanedTimeSeriesMatrix, regressors', covariates.pupilTimebase, 'meanCenterRegressors', true);
    if strcmp(p.Results.fileType, 'volume')
        suffix = '.nii.gz';
    elseif strcmp(p.Results.fileType, 'CIFTI')
        suffix = '.dscalar.nii';
    end
    statsOfInterest = {'rSquared', 'beta'};
    for ss = 1:length(statsOfInterest)
        saveName = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'wholeBrain', 'resting', subjectID, [runName,'_', covariatesToAnalyze{ii}, '_', statsOfInterest{ii}, suffix]);
        makeWholeBrainMap(stats.(covariatesToAnalyze{ii}).(statsOfInterest{ii})', voxelIndices, templateFile, saveName);
    end
end


clearvars
end