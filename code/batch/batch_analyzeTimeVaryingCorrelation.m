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
for ss = 1:length(subjects)
    subjectID = subjects{ss};
    
    runNames = getRunsPerSubject(subjectID);
    
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
        [ pooledTimeVaryingCorrelationStruct] = analyzeTimeVaryingCorrelation(subjectID, runName, 'plotHandle', plotFig, 'pooledTimeVaryingCorrelationStruct', pooledTimeVaryingCorrelationStruct, 'correlationMethod', 'jumpingWindowPearson', 'pupilMetric', 'mean');
    end
    subplot(1,3,1);
    makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.homotopic.pupilValues, pooledTimeVaryingCorrelationStruct.homotopic.correlationValues)
    subplot(1,3,2);
    makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.hierarchical.pupilValues, pooledTimeVaryingCorrelationStruct.hierarchical.correlationValues)
    subplot(1,3,3);
    makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.background.pupilValues, pooledTimeVaryingCorrelationStruct.background.correlationValues)
    
    saveas(plotFig, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'timeVaryingCorrelation', [subjectID, '_mean.png']), 'png');
    close all
    
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
        [ pooledTimeVaryingCorrelationStruct] = analyzeTimeVaryingCorrelation(subjectID, runName, 'plotHandle', plotFig, 'pooledTimeVaryingCorrelationStruct', pooledTimeVaryingCorrelationStruct, 'correlationMethod', 'jumpingWindowPearson', 'pupilMetric', 'std');
    end
    subplot(1,3,1);
    makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.homotopic.pupilValues, pooledTimeVaryingCorrelationStruct.homotopic.correlationValues)
    subplot(1,3,2);
    makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.hierarchical.pupilValues, pooledTimeVaryingCorrelationStruct.hierarchical.correlationValues)
    subplot(1,3,3);
    makeBinScatterPlot(pooledTimeVaryingCorrelationStruct.background.pupilValues, pooledTimeVaryingCorrelationStruct.background.correlationValues)
    
    saveas(plotFig, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'timeVaryingCorrelation', [subjectID, '_std.png']), 'png');
    close all
end

end
