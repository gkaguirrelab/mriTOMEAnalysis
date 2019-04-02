function batch_analyzeWholeBrain

% set up error log
errorLogPath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/errorLogs/');
currentTime = clock;
errorLogFilename = ['errorLog_TVC_', num2str(currentTime(1)), '-', num2str(currentTime(2)), '-', num2str(currentTime(3)), '_', num2str(currentTime(4)), num2str(currentTime(5))];
system(['echo "', 'SubjectID', ',', 'runName', '" > ', [errorLogPath, errorLogFilename]]);

subjects = {'TOME_3001', ...
    'TOME_3002', ...
    'TOME_3003', ...
    'TOME_3004', ...
    'TOME_3004', ...
    'TOME_3005', ...
    'TOME_3007', ...
    'TOME_3008', ...
    'TOME_3009', ...
    'TOME_3011', ...
    'TOME_3012', ...
    'TOME_3013', ...
    'TOME_3014', ...
    'TOME_3015', ...
    'TOME_3016', ...
    'TOME_3017', ...
    'TOME_3018', ...
    'TOME_3019', ...
    'TOME_3020', ...
    'TOME_3021', ...
    'TOME_3022', ...
    'TOME_3023', ...
    'TOME_3024', ...
    'TOME_3025', ...
    'TOME_3026', ...
    'TOME_3028', ...
    'TOME_3029', ...
    'TOME_3030', ...
    'TOME_3031', ...
    'TOME_3032', ...
    'TOME_3033', ...
    'TOME_3034', ...
    'TOME_3035', ...
    'TOME_3036', ...
    'TOME_3037', ...
    'TOME_3038', ...
    'TOME_3039', ...
    'TOME_3042'};


%% from each session, download the hcp-struct.zip
LGNV1.sliding.slope = [];
LGNV1.sliding.rSquared = [];

LGNV1.pupilMean.slope = [];
LGNV1.pupilMean.rSquared = [];

LGNV1.pupilSTD.slope = [];
LGNV1.pupilSTD.rSquared = [];

hierarchical.sliding.slope = [];
hierarchical.sliding.rSquared = [];

hierarchical.pupilMean.slope = [];
hierarchical.pupilMean.rSquared = [];

hierarchical.pupilSTD.slope = [];
hierarchical.pupilSTD.rSquared = [];

homotopic.sliding.slope = [];
homotopic.sliding.rSquared = [];

homotopic.pupilMean.slope = [];
homotopic.pupilMean.rSquared = [];

homotopic.pupilSTD.slope = [];
homotopic.pupilSTD.rSquared = [];

background.sliding.slope = [];
background.sliding.rSquared = [];

background.pupilMean.slope = [];
background.pupilMean.rSquared = [];

background.pupilSTD.slope = [];
background.pupilSTD.rSquared = [];



for ss = 1:length(subjects)
    subjectID = subjects{ss};
    
% LGN-V1, sliding window
    runNames = getRunsPerSubject(subjectID);
    
    plotFig = figure; hold on;
    set(gcf,'un','n','pos',[.05,.05,.7,.6])
    
    pooledTimeVaryingCorrelationStruct.correlationValues = [];
    pooledTimeVaryingCorrelationStruct.pupilValues = [];


    
    for rr = 1:length(runNames)
        runName = runNames{rr};
        [ pooledTimeVaryingCorrelationStruct] = analyzeLGNV1Correlation(subjectID, runName, 'plotHandle', plotFig, 'pooledTimeVaryingCorrelationStruct', pooledTimeVaryingCorrelationStruct, 'correlationMethod', 'slidingWindowPearson', 'pupilMetric', 'mean');
    end
    makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.pupilValues, pooledTimeVaryingCorrelationStruct.correlationValues)
    saveas(plotFig, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'timeVaryingCorrelation', [subjectID, '_LGN-V1.png']), 'png');
    
    
    NaNIndices = isnan(pooledTimeVaryingCorrelationStruct.correlationValues);
    x = pooledTimeVaryingCorrelationStruct.pupilValues;
    y = pooledTimeVaryingCorrelationStruct.correlationValues;
    x(NaNIndices) = [];
    y(NaNIndices) = [];
    
    data = [x', y'];
    [m, b] = TheilSen(data);
    
    yPredicted = x*m+b;
    yBar = nanmean(y);
    SStot = sum((y - yBar).^2);
    SSreg = sum((yPredicted - yBar).^2);
    SSres = sum((y - yPredicted).^2);
    rSquared = 1 - SSres/SStot;
    
    LGNV1.sliding.slope(end+1) = m;
    LGNV1.sliding.rSquared(end+1) = rSquared;
    
    
    close all
    





% LGN-V1, pupil mean
    plotFig = figure; hold on;
    
    pooledTimeVaryingCorrelationStruct.correlationValues = [];
    pooledTimeVaryingCorrelationStruct.pupilValues = [];
    
    for rr = 1:length(runNames)
        runName = runNames{rr};
        [ pooledTimeVaryingCorrelationStruct] = analyzeLGNV1Correlation(subjectID, runName, 'plotHandle', plotFig, 'pooledTimeVaryingCorrelationStruct', pooledTimeVaryingCorrelationStruct, 'correlationMethod', 'jumpingWindowPearson', 'pupilMetric', 'mean');
    end
    makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.pupilValues, pooledTimeVaryingCorrelationStruct.correlationValues)
    saveas(plotFig, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'timeVaryingCorrelation', [subjectID, '_LGN-V1_jumpingWindow_pupilMean.png']), 'png');
    close all
    NaNIndices = isnan(pooledTimeVaryingCorrelationStruct.correlationValues);
    x = pooledTimeVaryingCorrelationStruct.pupilValues;
    y = pooledTimeVaryingCorrelationStruct.correlationValues;
    x(NaNIndices) = [];
    y(NaNIndices) = [];
    
    data = [x', y'];
    [m, b] = TheilSen(data);
    
    yPredicted = x*m+b;
    yBar = nanmean(y);
    SStot = sum((y - yBar).^2);
    SSreg = sum((yPredicted - yBar).^2);
    SSres = sum((y - yPredicted).^2);
    rSquared = 1 - SSres/SStot;
    
    LGNV1.pupilMean.slope(end+1) = m;
    LGNV1.pupilMean.rSquared(end+1) = rSquared;


% LGN-V1, pupil STD
    plotFig = figure; hold on;
    
    pooledTimeVaryingCorrelationStruct.correlationValues = [];
    pooledTimeVaryingCorrelationStruct.pupilValues = [];
    
    for rr = 1:length(runNames)
        runName = runNames{rr};
        [ pooledTimeVaryingCorrelationStruct] = analyzeLGNV1Correlation(subjectID, runName, 'plotHandle', plotFig, 'pooledTimeVaryingCorrelationStruct', pooledTimeVaryingCorrelationStruct, 'correlationMethod', 'jumpingWindowPearson', 'pupilMetric', 'std');
    end
    makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.pupilValues, pooledTimeVaryingCorrelationStruct.correlationValues)
    saveas(plotFig, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'timeVaryingCorrelation', [subjectID, '_LGN-V1_jumpingWindow_pupilSTD.png']), 'png');
    close all
    NaNIndices = isnan(pooledTimeVaryingCorrelationStruct.correlationValues);
    x = pooledTimeVaryingCorrelationStruct.pupilValues;
    y = pooledTimeVaryingCorrelationStruct.correlationValues;
    x(NaNIndices) = [];
    y(NaNIndices) = [];
    
    data = [x', y'];
    [m, b] = TheilSen(data);
    
    yPredicted = x*m+b;
    yBar = nanmean(y);
    SStot = sum((y - yBar).^2);
    SSreg = sum((yPredicted - yBar).^2);
    SSres = sum((y - yPredicted).^2);
    rSquared = 1 - SSres/SStot;
    
    LGNV1.pupilSTD.slope(end+1) = m;
    LGNV1.pupilSTD.rSquared(end+1) = rSquared;
    


% within V1, pupil mean
    pooledTimeVaryingCorrelationStruct.homotopic.correlationValues = [];
    pooledTimeVaryingCorrelationStruct.hierarchical.correlationValues = [];
    pooledTimeVaryingCorrelationStruct.background.correlationValues = [];
    pooledTimeVaryingCorrelationStruct.homotopic.pupilValues = [];
    pooledTimeVaryingCorrelationStruct.hierarchical.pupilValues = [];
    pooledTimeVaryingCorrelationStruct.background.pupilValues = [];
    
    for rr = 1:length(runNames)
        runName = runNames{rr};
        [ pooledTimeVaryingCorrelationStruct] = analyzeTimeVaryingCorrelation(subjectID, runName, 'plotHandle', plotFig, 'pooledTimeVaryingCorrelationStruct', pooledTimeVaryingCorrelationStruct, 'correlationMethod', 'jumpingWindowPearson', 'pupilMetric', 'mean', 'linkAxes', false);
    end
    ax1 = subplot(1,3,1);
    makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.homotopic.pupilValues, pooledTimeVaryingCorrelationStruct.homotopic.correlationValues)
    ax2 = subplot(1,3,2);
    makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.hierarchical.pupilValues, pooledTimeVaryingCorrelationStruct.hierarchical.correlationValues)
    ax3 = subplot(1,3,3);
    makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.background.pupilValues, pooledTimeVaryingCorrelationStruct.background.correlationValues)
    linkaxes([ax1, ax2, ax3]);
    
    saveas(plotFig, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'timeVaryingCorrelation', [subjectID, '_mean.png']), 'png');
    close all
    
    % homotopic
    NaNIndices = isnan(pooledTimeVaryingCorrelationStruct.homotopic.correlationValues);
    x = pooledTimeVaryingCorrelationStruct.homotopic.pupilValues;
    y = pooledTimeVaryingCorrelationStruct.homotopic.correlationValues;
    x(NaNIndices) = [];
    y(NaNIndices) = [];
    
    data = [x', y'];
    [m, b] = TheilSen(data);
    
    yPredicted = x*m+b;
    yBar = nanmean(y);
    SStot = sum((y - yBar).^2);
    SSreg = sum((yPredicted - yBar).^2);
    SSres = sum((y - yPredicted).^2);
    rSquared = 1 - SSres/SStot;
    
    homotopic.pupilMean.slope(end+1) = m;
    homotopic.pupilMean.rSquared(end+1) = rSquared;
    
    % hierarchical
    NaNIndices = isnan(pooledTimeVaryingCorrelationStruct.hierarchical.correlationValues);
    x = pooledTimeVaryingCorrelationStruct.hierarchical.pupilValues;
    y = pooledTimeVaryingCorrelationStruct.hierarchical.correlationValues;
    x(NaNIndices) = [];
    y(NaNIndices) = [];
    
    data = [x', y'];
    [m, b] = TheilSen(data);
    
    yPredicted = x*m+b;
    yBar = nanmean(y);
    SStot = sum((y - yBar).^2);
    SSreg = sum((yPredicted - yBar).^2);
    SSres = sum((y - yPredicted).^2);
    rSquared = 1 - SSres/SStot;
    
    hierarchical.pupilMean.slope(end+1) = m;
    hierarchical.pupilMean.rSquared(end+1) = rSquared;
    
    % background
    NaNIndices = isnan(pooledTimeVaryingCorrelationStruct.background.correlationValues);
    x = pooledTimeVaryingCorrelationStruct.background.pupilValues;
    y = pooledTimeVaryingCorrelationStruct.background.correlationValues;
    x(NaNIndices) = [];
    y(NaNIndices) = [];
    
    data = [x', y'];
    [m, b] = TheilSen(data);
    
    yPredicted = x*m+b;
    yBar = nanmean(y);
    SStot = sum((y - yBar).^2);
    SSreg = sum((yPredicted - yBar).^2);
    SSres = sum((y - yPredicted).^2);
    rSquared = 1 - SSres/SStot;
    
    background.pupilMean.slope(end+1) = m;
    background.pupilMean.rSquared(end+1) = rSquared;


    


% within V1, pupil STD
    plotFig = figure; hold on;
    set(gcf,'un','n','pos',[.05,.05,.7,.6])
    
    pooledTimeVaryingCorrelationStruct.homotopic.correlationValues = [];
    pooledTimeVaryingCorrelationStruct.hierarchical.correlationValues = [];
    pooledTimeVaryingCorrelationStruct.background.correlationValues = [];
    pooledTimeVaryingCorrelationStruct.homotopic.pupilValues = [];
    pooledTimeVaryingCorrelationStruct.hierarchical.pupilValues = [];
    pooledTimeVaryingCorrelationStruct.background.pupilValues = [];
    
    for rr = 1:length(runNames)
        runName = runNames{rr};
        [ pooledTimeVaryingCorrelationStruct] = analyzeTimeVaryingCorrelation(subjectID, runName, 'plotHandle', plotFig, 'pooledTimeVaryingCorrelationStruct', pooledTimeVaryingCorrelationStruct, 'correlationMethod', 'jumpingWindowPearson', 'pupilMetric', 'std', 'linkAxes', false);
    end
    ax1 = subplot(1,3,1);
    makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.homotopic.pupilValues, pooledTimeVaryingCorrelationStruct.homotopic.correlationValues)
    ax2 = subplot(1,3,2);
    makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.hierarchical.pupilValues, pooledTimeVaryingCorrelationStruct.hierarchical.correlationValues)
    ax3 = subplot(1,3,3);
    makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.background.pupilValues, pooledTimeVaryingCorrelationStruct.background.correlationValues)
    linkaxes([ax1, ax2, ax3]);
    
    saveas(plotFig, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'timeVaryingCorrelation', [subjectID, '_std.png']), 'png');
    close all
    % homotopic
    NaNIndices = isnan(pooledTimeVaryingCorrelationStruct.homotopic.correlationValues);
    x = pooledTimeVaryingCorrelationStruct.homotopic.pupilValues;
    y = pooledTimeVaryingCorrelationStruct.homotopic.correlationValues;
    x(NaNIndices) = [];
    y(NaNIndices) = [];
    
    data = [x', y'];
    [m, b] = TheilSen(data);
    
    yPredicted = x*m+b;
    yBar = nanmean(y);
    SStot = sum((y - yBar).^2);
    SSreg = sum((yPredicted - yBar).^2);
    SSres = sum((y - yPredicted).^2);
    rSquared = 1 - SSres/SStot;
    
    homotopic.pupilSTD.slope(end+1) = m;
    homotopic.pupilSTD.rSquared(end+1) = rSquared;
    
    % hierarchical
    NaNIndices = isnan(pooledTimeVaryingCorrelationStruct.hierarchical.correlationValues);
    x = pooledTimeVaryingCorrelationStruct.hierarchical.pupilValues;
    y = pooledTimeVaryingCorrelationStruct.hierarchical.correlationValues;
    x(NaNIndices) = [];
    y(NaNIndices) = [];
    
    data = [x', y'];
    [m, b] = TheilSen(data);
    
    yPredicted = x*m+b;
    yBar = nanmean(y);
    SStot = sum((y - yBar).^2);
    SSreg = sum((yPredicted - yBar).^2);
    SSres = sum((y - yPredicted).^2);
    rSquared = 1 - SSres/SStot;
    
    hierarchical.pupilSTD.slope(end+1) = m;
    hierarchical.pupilSTD.rSquared(end+1) = rSquared;
    
    % background
    NaNIndices = isnan(pooledTimeVaryingCorrelationStruct.background.correlationValues);
    x = pooledTimeVaryingCorrelationStruct.background.pupilValues;
    y = pooledTimeVaryingCorrelationStruct.background.correlationValues;
    x(NaNIndices) = [];
    y(NaNIndices) = [];
    
    data = [x', y'];
    [m, b] = TheilSen(data);
    
    yPredicted = x*m+b;
    yBar = nanmean(y);
    SStot = sum((y - yBar).^2);
    SSreg = sum((yPredicted - yBar).^2);
    SSres = sum((y - yPredicted).^2);
    rSquared = 1 - SSres/SStot;
    
    background.pupilSTD.slope(end+1) = m;
    background.pupilSTD.rSquared(end+1) = rSquared;
end

end
