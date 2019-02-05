function batch_analyzeCovariateLag

% set up error log
errorLogPath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/errorLogs/');
currentTime = clock;
errorLogFilename = ['errorLog_CovariateLag_', num2str(currentTime(1)), '-', num2str(currentTime(2)), '-', num2str(currentTime(3)), '_', num2str(currentTime(4)), num2str(currentTime(5))];
system(['echo "', 'SubjectID', ',', 'runName', '" > ', [errorLogPath, errorLogFilename]]);

subjects = {'TOME_3001', 'TOME_3002', 'TOME_3003', 'TOME_3004', 'TOME_3005', 'TOME_3008', 'TOME_3009', 'TOME_3011', 'TOME_3012', 'TOME_3013', 'TOME_3014', 'TOME_3015', 'TOME_3016', 'TOME_3018', 'TOME_3020', 'TOME_3022', 'TOME_3023', 'TOME_3024', 'TOME_3025', 'TOME_3026', 'TOME_3029', 'TOME_3032', 'TOME_3033', 'TOME_3034', 'TOME_3035', 'TOME_3036', 'TOME_3038', 'TOME_3040'};

V1Correlations = [];
IPLCorrelations = [];

paths = definePaths('TOME_3001');
plotFig = figure;
hold on
counter = 1;
lagRange = -20000:100:20000;
for ss = 1:length(subjects)
    subjectID = subjects{ss};
    
    [ runNames ] = getRunsPerSubject(subjectID);
    V1CorrelationsPerSubject = [];
    IPLCorrelationsPerSubject = [];
    for rr = 1:length(runNames)
        
        runName = runNames{rr};
        
        fprintf('Now analyzing Subject %s, Run %s\n', subjectID, runName);
        
        %try
            [V1CorrelationsPerSubject(end+1, :), IPLCorrelationsPerSubject(end+1, :)] = analyzeCovariateLag(subjectID, runName, 'lagRange', lagRange, 'covariateType', 'pupilDiameterBandpassedConvolved');
            system(['echo "', subjectID, ',', runName, '" >> ', [errorLogPath, 'completedRuns']]);
        %catch
            system(['echo "', subjectID, ',', runName, '" >> ', [errorLogPath, errorLogFilename]]);
        %end
        
        
    end
    counter = counter + 1;
    V1Correlations(end+1,:) = mean(V1CorrelationsPerSubject,1);
    IPLCorrelations(end+1,:) = mean(IPLCorrelationsPerSubject,1);
    if size(V1Correlations,1) > 1
        
        
        
        close all
        plotFig = figure;
        hold on
        h1 = shadedErrorBar( lagRange, mean(IPLCorrelations,1), std(IPLCorrelations,1), 'r');
        h2 = shadedErrorBar( lagRange, mean(V1Correlations,1), std(V1Correlations,1), 'b');
        
        xlim([lagRange(1), lagRange(end)])
        xlabel('Lag (ms)')
        ylabel('Average Correlation')
        legend([h1.mainLine,h2.mainLine],'IPL', 'V1')
        orient(plotFig, 'landscape')
        title(['# Subjects = ', num2str(counter)]);
        
        print(plotFig, fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/wholeBrain', 'lagCorrelation.pdf'), '-dpdf', '-fillpage')
    end
end

end
