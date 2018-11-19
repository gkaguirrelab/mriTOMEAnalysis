function [ averageCorrelationMatrix ] = makeAverageCorrelationMatrix(varargin)

potentialSubjects = dir(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'correlationMatrices', 'TOME_3005'));
subjects = {'TOME_3005', 'TOME_3035', 'TOME_3037', 'TOME_3020', 'TOME_3029', 'TOME_3042'};
for ss = 1:length(subjects)
    potentialSubjects(ss).name = subjects{ss};
end

for ss = 1:length(potentialSubjects)
    potentialRuns = dir(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'correlationMatrices', potentialSubjects(ss).name, '*.mat'));
    subjectID = potentialSubjects(ss).name;
    if ~strcmp(subjectID, 'TOME_3003')
        for rr = 1:length(potentialRuns)
            if ~contains(potentialRuns(rr).name, 'postEye')
                runNameFull = potentialRuns(rr).name;
                runNameSplit = strsplit(runNameFull, '.');
                runName = runNameSplit{1};
                correlationMatrix = load(fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'correlationMatrices', potentialSubjects(ss).name,potentialRuns(rr).name));
                pooledCorrelationMatrices_acrossHemisphere.(subjectID).(runName) = 0.5*(log(1+correlationMatrix.acrossHemisphereCorrelationMatrix) - log(1-correlationMatrix.acrossHemisphereCorrelationMatrix));
                pooledCorrelationMatrices_combined.(subjectID).(runName) = 0.5*(log(1+correlationMatrix.combinedCorrelationMatrix) - log(1-correlationMatrix.combinedCorrelationMatrix));
            end
        end
    end
end

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

meanMatrix = pooledMatrices./totalRuns;
        
plotFig = figure;
subplot(1,2,1);
imagesc(meanMatrix)

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

meanMatrix = pooledMatrices./totalRuns;
        
subplot(1,2,2);
imagesc(meanMatrix)

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

savePath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'correlationMatrices');
h = gcf;
set(h,'PaperOrientation','landscape');
print(plotFig, fullfile(savePath,'averagedCorrelationMatrices'), '-dpdf', '-fillpage')


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