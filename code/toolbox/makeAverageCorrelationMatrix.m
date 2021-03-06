function [ preEyeCorrelationsByType, postEyeCorrelationsByType ] = makeAverageCorrelationMatrix(subjectList, varargin)

p = inputParser; p.KeepUnmatched = true;
p.addParameter('saveName', [], @ischar);
p.parse(varargin{:});
 
%% make average correlation matrix prior to removal of eye signals
for ss = 1:length(subjectList)
    potentialsubjectList(ss).name = subjectList{ss};
end

homotopicIndices_within = [6,11,16,21,26,31];
hierarchicalIndices_within = [2,3,7,9,13,14,24,23,30,28,34,35];
backgroundIndices_within = [5,4,12,10,18,17,20,19,27,25,33,32];

homotopicIndices_between = [6, 11, 16, 21, 26, 31, 1, 8, 15, 22, 29, 36];
hierarchicalIndices_between = [];
backgroundIndices_between = [5,4,12,10,18,17,20,19,27,25,33,32];


homotopicCorrelations_preEye = [];
hierarchicalCorrelations_preEye = [];
backgroundCorrelations_preEye = [];

for ss = 1:length(potentialsubjectList)
    potentialRuns = dir(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'correlationMatrices', potentialsubjectList(ss).name, '*.mat'));
    subjectID = potentialsubjectList(ss).name;
    
    for rr = 1:length(potentialRuns)
        if ~contains(potentialRuns(rr).name, 'postEye')
            runNameFull = potentialRuns(rr).name;
            runNameSplit = strsplit(runNameFull, '.');
            runName = runNameSplit{1};
            correlationMatrix = load(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'correlationMatrices', potentialsubjectList(ss).name,potentialRuns(rr).name));
            % between hemispheres
            pooledCorrelationMatrices_acrossHemisphere.(subjectID).(runName) = 0.5*(log(1+correlationMatrix.acrossHemisphereCorrelationMatrix) - log(1-correlationMatrix.acrossHemisphereCorrelationMatrix));
            homotopicCorrelations_preEye = [homotopicCorrelations_preEye, pooledCorrelationMatrices_acrossHemisphere.(subjectID).(runName)(homotopicIndices_between)];
            hierarchicalCorrelations_preEye = [hierarchicalCorrelations_preEye, pooledCorrelationMatrices_acrossHemisphere.(subjectID).(runName)(hierarchicalIndices_between)];
            backgroundCorrelations_preEye = [backgroundCorrelations_preEye, pooledCorrelationMatrices_acrossHemisphere.(subjectID).(runName)(backgroundIndices_between)];
            
            % within hemisphere
            pooledCorrelationMatrices_combined.(subjectID).(runName) = 0.5*(log(1+correlationMatrix.combinedCorrelationMatrix) - log(1-correlationMatrix.combinedCorrelationMatrix));
            homotopicCorrelations_preEye = [homotopicCorrelations_preEye, pooledCorrelationMatrices_combined.(subjectID).(runName)(homotopicIndices_within)];
            hierarchicalCorrelations_preEye = [hierarchicalCorrelations_preEye, pooledCorrelationMatrices_combined.(subjectID).(runName)(hierarchicalIndices_within)];
            backgroundCorrelations_preEye = [backgroundCorrelations_preEye, pooledCorrelationMatrices_combined.(subjectID).(runName)(backgroundIndices_within)];

            
        end
    end
    
end

preEyeCorrelationsByType.hierarchical = hierarchicalCorrelations_preEye;
preEyeCorrelationsByType.homotopic = homotopicCorrelations_preEye;
preEyeCorrelationsByType.background = backgroundCorrelations_preEye;

pooledMatrices = zeros(6,6);
subjectIDs = fieldnames(pooledCorrelationMatrices_combined);
totalRuns = 0;
for ss = 1:length(subjectIDs)
    runNames = fieldnames(pooledCorrelationMatrices_combined.(subjectIDs{ss}));
    for rr = 1:length(runNames)
        pooledMatrices = pooledMatrices + pooledCorrelationMatrices_combined.(subjectIDs{ss}).(runNames{rr});
        totalRuns = totalRuns + 1;
    end
end

withinHemisphere_preEye_meanMatrix = pooledMatrices./totalRuns;

plotFig = figure;
subplot(1,2,1);
im = imagesc(withinHemisphere_preEye_meanMatrix);

% pretty it up
rhLabel = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
title('Within Hemisphere')
colorbar
colors = redblue(100);
colormap(colors)
caxis([-1.25 1.25])
pbaspect([1 1 1])
hold on;
rectangle('Position', [5.5, 5.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [4.5, 4.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [3.5, 3.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [2.5, 2.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [1.5, 1.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [0.5, 0.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
plot(1,1, '*', 'Color', 'k');
plot(2,2, '*', 'Color', 'k');
plot(3,3, '*', 'Color', 'k');
plot(4,4, '*', 'Color', 'k');
plot(5,5, '*', 'Color', 'k');
plot(6,6, '*', 'Color', 'k');



pooledMatrices = zeros(6,6);
subjectIDs = fieldnames(pooledCorrelationMatrices_acrossHemisphere);
totalRuns = 0;
for ss = 1:length(subjectIDs)
    runNames = fieldnames(pooledCorrelationMatrices_acrossHemisphere.(subjectIDs{ss}));
    for rr = 1:length(runNames)
        pooledMatrices = pooledMatrices + pooledCorrelationMatrices_acrossHemisphere.(subjectIDs{ss}).(runNames{rr});
        totalRuns = totalRuns + 1;
    end
end

betweenHemisphere_preEye_meanMatrix = pooledMatrices./totalRuns;

subplot(1,2,2);
imagesc(betweenHemisphere_preEye_meanMatrix)

% pretty it up
rhLabel = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
xlabel('Left Hemisphere')
ylabel('Right Hemisphere')
title('Between Hemispheres')
colorbar
colors = redblue(100);
colormap(colors)
caxis([-1.25 1.25])
pbaspect([1 1 1])

if ~isempty(p.Results.saveName)
    h = gcf;
    set(h,'PaperOrientation','landscape');
    print(plotFig, [p.Results.saveName, '_preEye.pdf'], '-dpdf', '-fillpage')
end

%% make average correlation matrix for after removal of eye signals
for ss = 1:length(subjectList)
    potentialsubjectList(ss).name = subjectList{ss};
end


homotopicCorrelations_postEye = [];
hierarchicalCorrelations_postEye = [];
backgroundCorrelations_postEye = [];

for ss = 1:length(potentialsubjectList)
    potentialRuns = dir(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'correlationMatrices', potentialsubjectList(ss).name, '*.mat'));
    subjectID = potentialsubjectList(ss).name;
    
    for rr = 1:length(potentialRuns)
        if contains(potentialRuns(rr).name, 'postEye')
            runNameFull = potentialRuns(rr).name;
            runNameSplit = strsplit(runNameFull, '.');
            runName = runNameSplit{1};
            correlationMatrix = load(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'correlationMatrices', potentialsubjectList(ss).name,potentialRuns(rr).name));
            pooledCorrelationMatrices_postEye_acrossHemisphere.(subjectID).(runName) = 0.5*(log(1+correlationMatrix.acrossHemisphereCorrelationMatrix_postEye) - log(1-correlationMatrix.acrossHemisphereCorrelationMatrix_postEye));
            homotopicCorrelations_postEye = [homotopicCorrelations_postEye, pooledCorrelationMatrices_postEye_acrossHemisphere.(subjectID).(runName)(homotopicIndices_between)];
            hierarchicalCorrelations_postEye = [hierarchicalCorrelations_postEye, pooledCorrelationMatrices_postEye_acrossHemisphere.(subjectID).(runName)(hierarchicalIndices_between)];
            backgroundCorrelations_postEye = [backgroundCorrelations_postEye, pooledCorrelationMatrices_postEye_acrossHemisphere.(subjectID).(runName)(backgroundIndices_between)];
            
            pooledCorrelationMatrices_postEye_combined.(subjectID).(runName) = 0.5*(log(1+correlationMatrix.combinedCorrelationMatrix_postEye) - log(1-correlationMatrix.combinedCorrelationMatrix_postEye));
            homotopicCorrelations_postEye = [homotopicCorrelations_postEye, pooledCorrelationMatrices_postEye_combined.(subjectID).(runName)(homotopicIndices_within)];
            hierarchicalCorrelations_postEye = [hierarchicalCorrelations_postEye, pooledCorrelationMatrices_postEye_combined.(subjectID).(runName)(hierarchicalIndices_within)];
            backgroundCorrelations_postEye = [backgroundCorrelations_postEye, pooledCorrelationMatrices_postEye_combined.(subjectID).(runName)(backgroundIndices_within)];
        end
    end
    
end

postEyeCorrelationsByType.hierarchical = hierarchicalCorrelations_postEye;
postEyeCorrelationsByType.homotopic = homotopicCorrelations_postEye;
postEyeCorrelationsByType.background = backgroundCorrelations_postEye;

pooledMatrices = zeros(6,6);
subjectIDs = fieldnames(pooledCorrelationMatrices_postEye_combined);
totalRuns = 0;
for ss = 1:length(subjectIDs)
    runNames = fieldnames(pooledCorrelationMatrices_postEye_combined.(subjectIDs{ss}));
    for rr = 1:length(runNames)
        pooledMatrices = pooledMatrices + pooledCorrelationMatrices_postEye_combined.(subjectIDs{ss}).(runNames{rr});
        totalRuns = totalRuns + 1;
    end
end

withinHemisphere_postEye_meanMatrix = pooledMatrices./totalRuns;

plotFig = figure;
subplot(1,2,1);
imagesc(withinHemisphere_postEye_meanMatrix)

% pretty it up
rhLabel = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
title('Within Hemisphere')
colorbar
colors = redblue(100);
colormap(colors)
caxis([-1.25 1.25])
pbaspect([1 1 1])
hold on;
rectangle('Position', [5.5, 5.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [4.5, 4.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [3.5, 3.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [2.5, 2.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [1.5, 1.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [0.5, 0.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
plot(1,1, '*', 'Color', 'k');
plot(2,2, '*', 'Color', 'k');
plot(3,3, '*', 'Color', 'k');
plot(4,4, '*', 'Color', 'k');
plot(5,5, '*', 'Color', 'k');
plot(6,6, '*', 'Color', 'k');


pooledMatrices = zeros(6,6);
subjectIDs = fieldnames(pooledCorrelationMatrices_postEye_acrossHemisphere);
totalRuns = 0;
for ss = 1:length(subjectIDs)
    runNames = fieldnames(pooledCorrelationMatrices_postEye_acrossHemisphere.(subjectIDs{ss}));
    for rr = 1:length(runNames)
        pooledMatrices = pooledMatrices + pooledCorrelationMatrices_postEye_acrossHemisphere.(subjectIDs{ss}).(runNames{rr});
        totalRuns = totalRuns + 1;
    end
end

betweenHemisphere_postEye_meanMatrix = pooledMatrices./totalRuns;

subplot(1,2,2);
imagesc(betweenHemisphere_postEye_meanMatrix)

% pretty it up
rhLabel = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
xlabel('Left Hemisphere')
ylabel('Right Hemisphere')
title('Between Hemispheres')
colorbar
colors = redblue(100);
colormap(colors)
caxis([-1.25 1.25])
pbaspect([1 1 1])

if ~isempty(p.Results.saveName)
    h = gcf;
    set(h,'PaperOrientation','landscape');
    print(plotFig, [p.Results.saveName, '_postEye.pdf'], '-dpdf', '-fillpage')
end
%% make difference correlation matrix
withinHemisphereDifference = withinHemisphere_postEye_meanMatrix - withinHemisphere_preEye_meanMatrix;
betweenHemisphereDifference = betweenHemisphere_postEye_meanMatrix - betweenHemisphere_preEye_meanMatrix;

plotFig = figure;
subplot(1,2,1);
imagesc(withinHemisphereDifference)

% pretty it up
rhLabel = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
title('Within Hemisphere Difference')
colorbar
colors = redblue(100);
colormap(colors)
caxis([-0.25 0.25])
pbaspect([1 1 1])
hold on;
rectangle('Position', [5.5, 5.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [4.5, 4.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [3.5, 3.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [2.5, 2.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [1.5, 1.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [0.5, 0.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
plot(1,1, '*', 'Color', 'k');
plot(2,2, '*', 'Color', 'k');
plot(3,3, '*', 'Color', 'k');
plot(4,4, '*', 'Color', 'k');
plot(5,5, '*', 'Color', 'k');
plot(6,6, '*', 'Color', 'k');

subplot(1,2,2);
imagesc(betweenHemisphereDifference)

% pretty it up
rhLabel = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
xlabel('Left Hemisphere')
ylabel('Right Hemisphere')
title('Between Hemispheres Difference')
colorbar
colors = redblue(100);
colormap(colors)
caxis([-0.25 0.25])
pbaspect([1 1 1])

if ~isempty(p.Results.saveName)
    h = gcf;
    set(h,'PaperOrientation','landscape');
    print(plotFig, [p.Results.saveName, '_differences.pdf'], '-dpdf', '-fillpage')
end
%% Plot some information about correlation by connection type
connectionTypes = {'hierarchical', 'homotopic', 'background'};

% first bootstrap to get confidence intervals
nBootstraps = 10000;
for cc = 1:length(connectionTypes)
    bootstrapResultsPreEye.(connectionTypes{cc}) = [];
    for bb = 1:nBootstraps
        bootstrapIndices = datasample(1:length(preEyeCorrelationsByType.(connectionTypes{cc})), length(preEyeCorrelationsByType.(connectionTypes{cc})));
        bootstrapResultsPreEye.(connectionTypes{cc}) = [bootstrapResultsPreEye.(connectionTypes{cc}), mean(preEyeCorrelationsByType.(connectionTypes{cc})(bootstrapIndices))];
    end
    SEMPreEye.(connectionTypes{cc}) = std(bootstrapResultsPreEye.(connectionTypes{cc}));
    meanPreEye.(connectionTypes{cc}) = mean(bootstrapResultsPreEye.(connectionTypes{cc}));
end

bootstrapResultsPreEye.homotopicHierarchicalCombined = [];
for bb = 1:nBootstraps
    bootstrapIndicesHomotopic = datasample(1:length(preEyeCorrelationsByType.homotopic), length(preEyeCorrelationsByType.homotopic));
    bootstrapIndicesHierarchical = datasample(1:length(preEyeCorrelationsByType.hierarchical), length(preEyeCorrelationsByType.hierarchical));
    bootstrapResultsPreEye.homotopicHierarchicalCombined = [bootstrapResultsPreEye.homotopicHierarchicalCombined, mean([preEyeCorrelationsByType.homotopic(bootstrapIndicesHomotopic), preEyeCorrelationsByType.hierarchical(bootstrapIndicesHierarchical)])];
end
SEMPreEye.homotopicHierarchicalCombined = std(bootstrapResultsPreEye.homotopicHierarchicalCombined);
meanPreEye.homotopicHierarchicalCombined = mean(bootstrapResultsPreEye.homotopicHierarchicalCombined);


for cc = 1:length(connectionTypes)
    bootstrapResultsPostEye.(connectionTypes{cc}) = [];
    for bb = 1:nBootstraps
        bootstrapIndices = datasample(1:length(postEyeCorrelationsByType.(connectionTypes{cc})), length(postEyeCorrelationsByType.(connectionTypes{cc})));
        bootstrapResultsPostEye.(connectionTypes{cc}) = [bootstrapResultsPostEye.(connectionTypes{cc}), mean(postEyeCorrelationsByType.(connectionTypes{cc})(bootstrapIndices))];
    end
    SEMPostEye.(connectionTypes{cc}) = std(bootstrapResultsPostEye.(connectionTypes{cc}));
    meanPostEye.(connectionTypes{cc}) = mean(bootstrapResultsPostEye.(connectionTypes{cc}));
end

bootstrapResultsPostEye.homotopicHierarchicalCombined = [];
for bb = 1:nBootstraps
    bootstrapIndicesHomotopic = datasample(1:length(postEyeCorrelationsByType.homotopic), length(postEyeCorrelationsByType.homotopic));
    bootstrapIndicesHierarchical = datasample(1:length(postEyeCorrelationsByType.hierarchical), length(postEyeCorrelationsByType.hierarchical));
    bootstrapResultsPostEye.homotopicHierarchicalCombined = [bootstrapResultsPostEye.homotopicHierarchicalCombined, mean([postEyeCorrelationsByType.homotopic(bootstrapIndicesHomotopic), postEyeCorrelationsByType.hierarchical(bootstrapIndicesHierarchical)])];
end
SEMPostEye.homotopicHierarchicalCombined = std(bootstrapResultsPostEye.homotopicHierarchicalCombined);
meanPostEye.homotopicHierarchicalCombined = mean(bootstrapResultsPostEye.homotopicHierarchicalCombined);

for cc = 1:length(connectionTypes)
    bootstrapResultsDifference.(connectionTypes{cc}) = [];
    for bb = 1:nBootstraps
        bootstrapIndices = datasample(1:length(postEyeCorrelationsByType.(connectionTypes{cc})), length(postEyeCorrelationsByType.(connectionTypes{cc})));
        bootstrapResultsDifference.(connectionTypes{cc}) = [bootstrapResultsDifference.(connectionTypes{cc}), mean(postEyeCorrelationsByType.(connectionTypes{cc})(bootstrapIndices)) - mean(preEyeCorrelationsByType.(connectionTypes{cc})(bootstrapIndices))];
    end
    SEMDifference.(connectionTypes{cc}) = std(bootstrapResultsDifference.(connectionTypes{cc}));
    meanDifference.(connectionTypes{cc}) = mean(bootstrapResultsDifference.(connectionTypes{cc}));
end

plotFig = figure;
subplot(1,3,1);
barwitherr([SEMPreEye.hierarchical, SEMPreEye.homotopic, SEMPreEye.background], [meanPreEye.hierarchical, meanPreEye.homotopic, meanPreEye.background]);
title('Pre-Eye Signal Removal')
ylabel('Regional Correlation, +/- SEM')
xticklabels({'Hierarhical', 'Homotopic', 'Background'})
xtickangle(45);

subplot(1,3,2);
barwitherr([SEMPostEye.hierarchical, SEMPostEye.homotopic, SEMPostEye.background], [meanPostEye.hierarchical, meanPostEye.homotopic, meanPostEye.background]);
title('Post-Eye Signal Removal')
ylabel('Regional Correlation, +/- SEM')
xticklabels({'Hierarhical', 'Homotopic', 'Background'})
xtickangle(45);

subplot(1,3,3);
barwitherr([SEMDifference.hierarchical, SEMDifference.homotopic, SEMDifference.background], [meanDifference.hierarchical, meanDifference.homotopic, meanDifference.background]);
title('Post-Pre Difference')
ylabel('Regional Correlation, +/- SEM')
xticklabels({'Hierarhical', 'Homotopic', 'Background'})
xtickangle(45);

if ~isempty(p.Results.saveName)
    print(plotFig, [p.Results.saveName, '_meanCorrelationByConnectionType.pdf'], '-dpdf', '-fillpage')
end


plotFig = figure;
subplot(1,2,1);
barwitherr([SEMPreEye.homotopicHierarchicalCombined, SEMPreEye.background], [meanPreEye.homotopicHierarchicalCombined, meanPreEye.background]);
title('Before Eye Signal Removal')
ylabel('Regional Correlation (z''), +/- SEM');
xticklabels({'Hierarchical and Homotopic', 'Background'})
xtickangle(45)
pbaspect([1 1 1])


subplot(1,2,2);
barwitherr([SEMPostEye.homotopicHierarchicalCombined, SEMPostEye.background], [meanPostEye.homotopicHierarchicalCombined, meanPostEye.background]);
title('After Eye Signal Removal')
ylabel('Regional Correlation (z''), +/- SEM');
xticklabels({'Hierarchical and Homotopic', 'Background'})
xtickangle(45)
pbaspect([1 1 1])

if ~isempty(p.Results.saveName)
    print(plotFig, [p.Results.saveName, '_meanCorrelation_hierarchicalHomotopicCombined.pdf'], '-dpdf', '-fillpage')
end

%% VSS plot
plotFig = figure; 
subplot(3,3,1);
imagesc(withinHemisphere_preEye_meanMatrix);
rhLabel = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
title('Within Hemisphere')
colorbar
colors = redblue(100);
colormap(colors)
caxis([-1.25 1.25])
pbaspect([1 1 1])
hold on;
rectangle('Position', [5.5, 5.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [4.5, 4.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [3.5, 3.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [2.5, 2.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [1.5, 1.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [0.5, 0.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
plot(1,1, '*', 'Color', 'k');
plot(2,2, '*', 'Color', 'k');
plot(3,3, '*', 'Color', 'k');
plot(4,4, '*', 'Color', 'k');
plot(5,5, '*', 'Color', 'k');
plot(6,6, '*', 'Color', 'k');

subplot(3,3,2);
imagesc(betweenHemisphere_preEye_meanMatrix);
rhLabel = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
xlabel('Left Hemisphere')
ylabel('Right Hemisphere')
title('Between Hemispheres')
colorbar
colors = redblue(100);
colormap(colors)
caxis([-1.25 1.25])
pbaspect([1 1 1])

subplot(3,3,3);
barwitherr([SEMPreEye.hierarchical, SEMPreEye.homotopic, SEMPreEye.background], [meanPreEye.hierarchical, meanPreEye.homotopic, meanPreEye.background]);
title('Pre-Eye Signal Removal')
ylabel('Regional Correlation, +/- SEM')
xticklabels({'Hierarhical', 'Homotopic', 'Background'})
xtickangle(45);
ylim([0 0.9]);


subplot(3,3,4);
imagesc(withinHemisphere_postEye_meanMatrix);
rhLabel = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
title('Within Hemisphere')
colorbar
colors = redblue(100);
colormap(colors)
caxis([-1.25 1.25])
pbaspect([1 1 1])
hold on;
rectangle('Position', [5.5, 5.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [4.5, 4.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [3.5, 3.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [2.5, 2.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [1.5, 1.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [0.5, 0.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
plot(1,1, '*', 'Color', 'k');
plot(2,2, '*', 'Color', 'k');
plot(3,3, '*', 'Color', 'k');
plot(4,4, '*', 'Color', 'k');
plot(5,5, '*', 'Color', 'k');
plot(6,6, '*', 'Color', 'k');

subplot(3,3,5);
imagesc(betweenHemisphere_postEye_meanMatrix);
rhLabel = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
xlabel('Left Hemisphere')
ylabel('Right Hemisphere')
title('Between Hemispheres')
colorbar
colors = redblue(100);
colormap(colors)
caxis([-1.25 1.25])
pbaspect([1 1 1])

subplot(3,3,6);
barwitherr([SEMPostEye.hierarchical, SEMPostEye.homotopic, SEMPostEye.background], [meanPostEye.hierarchical, meanPostEye.homotopic, meanPostEye.background]);
title('Post-Eye Signal Removal')
ylabel('Regional Correlation, +/- SEM')
ylim([0 0.9]);
xticklabels({'Hierarhical', 'Homotopic', 'Background'})
xtickangle(45);

subplot(3,3,7);
imagesc(withinHemisphereDifference);
rhLabel = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
title('Within Hemisphere')
colorbar
colors = redblue(100);
colormap(colors)
caxis([-0.25 0.25])
pbaspect([1 1 1])
hold on;
rectangle('Position', [5.5, 5.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [4.5, 4.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [3.5, 3.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [2.5, 2.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [1.5, 1.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
rectangle('Position', [0.5, 0.5, 1, 1], 'FaceColor', 'y', 'LineWidth', 0.1)
plot(1,1, '*', 'Color', 'k');
plot(2,2, '*', 'Color', 'k');
plot(3,3, '*', 'Color', 'k');
plot(4,4, '*', 'Color', 'k');
plot(5,5, '*', 'Color', 'k');
plot(6,6, '*', 'Color', 'k');

subplot(3,3,8);
imagesc(betweenHemisphereDifference);
rhLabel = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
xlabel('Left Hemisphere')
ylabel('Right Hemisphere')
title('Between Hemispheres')
colorbar
colors = redblue(100);
colormap(colors)
caxis([-0.25 0.25])
pbaspect([1 1 1])

subplot(3,3,9);
barwitherr([SEMDifference.hierarchical, SEMDifference.homotopic, SEMDifference.background], [meanDifference.hierarchical, meanDifference.homotopic, meanDifference.background]);
title('Post-Pre Difference')
ylabel('Regional Correlation, +/- SEM')
xticklabels({'Hierarhical', 'Homotopic', 'Background'})
xtickangle(45); 

if ~isempty(p.Results.saveName)
    set(plotFig, 'Renderer','painters');
    set(plotFig, 'Position', [269 131 1050 854])
    print(plotFig, [p.Results.saveName, '_VSS.pdf'], '-dpdf')
end

% homotopic, hierarchical, background key
homotopicIndices_within = [6,11,16,21,26,31];
hierarchicalIndices_within = [2,3,7,9,13,14,24,23,30,28,34,35];
backgroundIndices_within = [5,4,12,10,18,17,20,19,27,25,33,32];

homotopicIndices_between = [6, 11, 16, 21, 26, 31, 1, 8, 15, 22, 29, 36];
hierarchicalIndices_between = [];
backgroundIndices_between = [5,4,12,10,18,17,20,19,27,25,33,32];
matrixTemplate = zeros(6,6);


plotFig = figure;
subplot(2,3,2);
homotopic_within = matrixTemplate;
homotopic_within(homotopicIndices_within) = 1;
imagesc(homotopic_within);
rhLabel = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
pbaspect([1 1 1])


subplot(2,3,5);
homotopic_between = matrixTemplate;
homotopic_between(homotopicIndices_between) = 1;
imagesc(homotopic_between);
rhLabel = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
pbaspect([1 1 1])


subplot(2,3,1);
hierarchical_within = matrixTemplate;
hierarchical_within(hierarchicalIndices_within) = 1;
imagesc(hierarchical_within);
rhLabel = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
pbaspect([1 1 1])


subplot(2,3,4)
hierarchical_between = matrixTemplate;
hierarchical_between(hierarchicalIndices_between) = 1;
imagesc(hierarchical_between);
rhLabel = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
pbaspect([1 1 1])


subplot(2,3,3);
background_within = matrixTemplate;
background_within(backgroundIndices_within) = 1;
imagesc(background_within);
rhLabel = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
pbaspect([1 1 1])


subplot(2,3,6);
background_between = matrixTemplate;
background_between(backgroundIndices_between) = 1;
imagesc(background_between);
rhLabel = {'V3v', 'V2v', 'V1v', 'V1d', 'V2d', 'V3d'};
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
pbaspect([1 1 1])

 if ~isempty(p.Results.saveName)
    print(plotFig, [p.Results.saveName, '_connectionKey.pdf'], '-dpdf', '-fillpage')
end

%% Local function just to make colormap for easier comparison to Butt et al 2015
    function c = redblue(m)
        %REDBLUE    Shades of red and blue color map
        %   REDBLUE(M), is an M-by-3 matrix that defines a colormap.
        %   The colors begin with bright blue, range through shades of
        %   blue to white, and then through shades of red to bright red.
        %   REDBLUE, by itself, is the same length as the current figure's
        %   colormap. If no figure exists, MATLAB creates one.
        %
        %   For example, to reset the colormap of the current figure:
        %
        %             colormap(redblue)
        %
        %   See also HSV, GRAY, HOT, BONE, COPPER, PINK, FLAG,
        %   COLORMAP, RGBPLOT.
        %   Adam Auton, 9th October 2009
        if nargin < 1, m = size(get(gcf,'colormap'),1); end
        if (mod(m,2) == 0)
            % From [0 0 1] to [1 1 1], then [1 1 1] to [1 0 0];
            m1 = m*0.5;
            r = (0:m1-1)'/max(m1-1,1);
            g = r;
            r = [r; ones(m1,1)];
            g = [g; flipud(g)];
            b = flipud(r);
        else
            % From [0 0 1] to [1 1 1] to [1 0 0];
            m1 = floor(m*0.5);
            r = (0:m1-1)'/max(m1,1);
            g = r;
            r = [r; ones(m1+1,1)];
            g = [g; 1; flipud(g)];
            b = flipud(r);
        end
        c = [r g b];
    end

end