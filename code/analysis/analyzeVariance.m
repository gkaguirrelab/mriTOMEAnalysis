function [meanRSquared, meanRSquaredShuffled, rSquaredDistribution, rSquaredShuffledDistribution] = analyzeVariance(subjectList)

if isempty(subjectList)
    subjectList = {'TOME_3001', 'TOME_3002', 'TOME_3003', 'TOME_3004', 'TOME_3005', 'TOME_3007', 'TOME_3008', 'TOME_3009', 'TOME_3011', 'TOME_3012', 'TOME_3013', 'TOME_3014', 'TOME_3015', 'TOME_3016', 'TOME_3017', 'TOME_3018', 'TOME_3019', 'TOME_3020', 'TOME_3021', 'TOME_3022'};
end

%% assemble list of runs across subjects
counter = 1;
for ss = 1:length(subjectList)
    potentialRuns = dir(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectList{ss}, '*_physioMotionWMVCorrected.mat'));
    subjectID = subjectList{ss};
    
    for rr = 1:length(potentialRuns)
        subjectListPooled{counter} = subjectID;
        runListPooled{counter} = potentialRuns(rr).name;
        counter = counter + 1;
    end
    
    
end

%% copy over the pupil data
% to ensure we have the latest version
downloadPupil = false;

if downloadPupil
    
    for rr = 11:length(runListPooled)
        
        runName = strsplit(runListPooled{rr}, '_timeSeries');
        runName = runName{1};
        getSubjectData(subjectListPooled{rr}, runName, 'downloadOnly', 'pupil')
        
    end
    
end

%% look at variance explained by eye signals, averaged across subjects
rSquaredPooled = [];
for rr = 1:length(runListPooled)
    runName = strsplit(runListPooled{rr}, '_timeSeries');
    runName = runName{1};
    subjectID = subjectListPooled{rr};
    cleanedTimeSeriesStruct = load(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID, [runName '_timeSeries_physioMotionWMVCorrected.mat']));
    %cleanedTimeSeries = cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V1Combined;
    cleanedTimeSeries = (cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V1v_lh_mask + ...
        cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V1v_rh_mask + ...
        cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V1d_lh_mask + ...
        cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V1d_rh_mask + ...
        cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V2v_lh_mask + ...
        cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V2v_rh_mask + ...
        cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V2d_lh_mask + ...
        cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V2d_rh_mask + ...
        cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V3v_lh_mask + ...
        cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V3v_rh_mask + ...
        cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V3d_lh_mask + ...
        cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V3d_rh_mask)/12;
    
    % make eye signal regressors
    [ covariates ] = makeEyeSignalCovariates(subjectID, runName);
    
    
    
    
    
    regressors = [covariates.eyeDisplacementConvolved; covariates.firstDerivativeEyeDisplacementConvolved; covariates.pupilDiameterConvolved; covariates.firstDerivativePupilDiameterConvolved; covariates.blinksConvolved; covariates.firstDerivativeBlinksConvolved];
    %regressors = [covariates.pupilChangeConvolved; covariates.firstDerivativePupilChangeConvolved];
    %regressors = [covariates.dilationsConvolved; covariates.firstDerivativeDilationsConvolved; covariates.constrictionsConvolved; covariates.firstDerivativeConstrictionsConvolved];
    %regressors = [covariates.constrictionsConvolved; covariates.firstDerivativeConstrictionsConvolved];
    %regressors = [covariates.dilationsConvolved; covariates.firstDerivativeDilationsConvolved];
    
    %regressors = [covariates.eyeDisplacementConvolved; covariates.firstDerivativeEyeDisplacementConvolved; covariates.pupilDiameterConvolved; covariates.firstDerivativePupilDiameterConvolved; covariates.blinksConvolved; covariates.firstDerivativeBlinksConvolved; covariates.pupilChangeConvolved; covariates.firstDerivativePupilChangeConvolved];
    
    
    [ ~, stats ] = cleanTimeSeries( cleanedTimeSeries, regressors', covariates.pupilTimebase, 'meanCenterRegressors', true);
    rSquaredPooled = [rSquaredPooled, stats.rSquared];
    
end

meanRSquared = mean(rSquaredPooled);

%% bootstrap to get a confidence interval
nBootstraps = 1000;
rSquaredDistribution = [];
for bb = 1:nBootstraps
    rSquaredPooled = [];
    indicesToGrab = datasample(1:length(runListPooled), length(runListPooled));
    for rr = 1:length(runListPooled)
        runName = strsplit(runListPooled{rr}, '_timeSeries');
        runName = runName{1};
        subjectID = subjectListPooled{rr};
        cleanedTimeSeriesStruct = load(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID, [runName '_timeSeries_physioMotionWMVCorrected.mat']));
        %cleanedTimeSeries = cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V1Combined;
        cleanedTimeSeries = (cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V1v_lh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V1v_rh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V1d_lh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V1d_rh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V2v_lh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V2v_rh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V2d_lh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V2d_rh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V3v_lh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V3v_rh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V3d_lh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V3d_rh_mask)/12;
        
        % make eye signal regressors
        [ covariates ] = makeEyeSignalCovariates(subjectID, runName);
        
        
        
        
        
        %regressors = [covariates.eyeDisplacementConvolved; covariates.firstDerivativeEyeDisplacementConvolved; covariates.pupilDiameterConvolved; covariates.firstDerivativePupilDiameterConvolved; covariates.blinksConvolved; covariates.firstDerivativeBlinksConvolved];
        %regressors = [covariates.pupilChangeConvolved; covariates.firstDerivativePupilChangeConvolved];
        %regressors = [covariates.dilationsConvolved; covariates.firstDerivativeDilationsConvolved; covariates.constrictionsConvolved; covariates.firstDerivativeConstrictionsConvolved];
        regressors = [covariates.constrictionsConvolved; covariates.firstDerivativeConstrictionsConvolved];
        %regressors = [covariates.dilationsConvolved; covariates.firstDerivativeDilationsConvolved];
        
        %regressors = [covariates.eyeDisplacementConvolved; covariates.firstDerivativeEyeDisplacementConvolved; covariates.pupilDiameterConvolved; covariates.firstDerivativePupilDiameterConvolved; covariates.blinksConvolved; covariates.firstDerivativeBlinksConvolved; covariates.pupilChangeConvolved; covariates.firstDerivativePupilChangeConvolved];
        
        
        [ ~, stats ] = cleanTimeSeries( cleanedTimeSeries, regressors', covariates.pupilTimebase, 'meanCenterRegressors', true);
        rSquaredPooled = [rSquaredPooled, stats.rSquared];
        
        
    end
    rSquaredDistribution = [rSquaredDistribution, mean(rSquaredPooled)];
end

%% Now shuffle ordering of pupil data, so we randomly pair a BOLD run with a pupil run
% See strength of variance explained after many iterations

nIterations = 1000;
rSquaredShuffledDistribution = [];
for ii = 1:nIterations
    rSquaredPooled = [];
    randomOrder = randperm(length(runListPooled));
    shuffledSubjectListPooled = subjectListPooled(randomOrder);
    shuffledRunListPooled = runListPooled(randomOrder);
    
    for rr = 1:length(runListPooled)
        runName = strsplit(runListPooled{rr}, '_timeSeries');
        runName = runName{1};
        subjectID = subjectListPooled{rr};
        cleanedTimeSeriesStruct = load(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID, [runName '_timeSeries_physioMotionWMVCorrected.mat']));
        %cleanedTimeSeries = cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V1Combined;
        cleanedTimeSeries = (cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V1v_lh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V1v_rh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V1d_lh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V1d_rh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V2v_lh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V2v_rh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V2d_lh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V2d_rh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V3v_lh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V3v_rh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V3d_lh_mask + ...
            cleanedTimeSeriesStruct.cleanedMeanTimeSeries.V3d_rh_mask)/12;
        
        
        
        % load up the pupil data
        runNameShuffled = strsplit(shuffledRunListPooled{rr}, '_timeSeries');
        runNameShuffled = runNameShuffled{1};
        subjectIDShuffled = shuffledSubjectListPooled{rr};
        runName = strsplit(runListPooled{rr}, '_timeSeries');
        
        
        % make eye signal regressors
        [ covariates ] = makeEyeSignalCovariates(subjectIDShuffled, runNameShuffled);
        
        
        
        
        
        %regressors = [covariates.eyeDisplacementConvolved; covariates.firstDerivativeEyeDisplacementConvolved; covariates.pupilDiameterConvolved; covariates.firstDerivativePupilDiameterConvolved; covariates.blinksConvolved; covariates.firstDerivativeBlinksConvolved];
        %regressors = [covariates.pupilChangeConvolved; covariates.firstDerivativePupilChangeConvolved];
        %regressors = [covariates.dilationsConvolved; covariates.firstDerivativeDilationsConvolved; covariates.constrictionsConvolved; covariates.firstDerivativeConstrictionsConvolved];
        regressors = [covariates.constrictionsConvolved; covariates.firstDerivativeConstrictionsConvolved];
        %regressors = [covariates.dilationsConvolved; covariates.firstDerivativeDilationsConvolved];
        
        %regressors = [covariates.eyeDisplacementConvolved; covariates.firstDerivativeEyeDisplacementConvolved; covariates.pupilDiameterConvolved; covariates.firstDerivativePupilDiameterConvolved; covariates.blinksConvolved; covariates.firstDerivativeBlinksConvolved; covariates.pupilChangeConvolved; covariates.firstDerivativePupilChangeConvolved];
        
        
        [ ~, stats ] = cleanTimeSeries( cleanedTimeSeries, regressors', covariates.pupilTimebase, 'meanCenterRegressors', true);
        rSquaredPooled = [rSquaredPooled, stats.rSquared];
        
    end
    rSquaredShuffledDistribution = [rSquaredShuffledDistribution, mean(rSquaredPooled)];
end
meanRSquaredShuffled = mean(rSquaredShuffledDistribution);
savePath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries');
save(fullfile(savePath, 'rSquaredDistributions'), 'rSquaredDistribution', 'rSquaredShuffledDistribution', '-v7.3')

%% Do some summary plotting
plotFig = figure;
hold on
histogram(rSquaredShuffledDistribution*100)
histogram(rSquaredDistribution*100)
xlabel('Percentage of Variance Explained')
ylabel('Frequency')
legend('Shuffled', 'Veridical')
xlabel('Percentage of BOLD Signal Variance Explained')
end