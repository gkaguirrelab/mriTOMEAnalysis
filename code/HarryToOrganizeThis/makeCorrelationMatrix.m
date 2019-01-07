function [ combinedCorrelationMatrix, acrossHemisphereCorrelationMatrix] = makeCorrelationMatrix(timeSeriesStruct, varargin)

p = inputParser; p.KeepUnmatched = true;
p.addParameter('desiredOrder',[], @iscell);
p.parse(varargin{:});


labels = fieldnames(timeSeriesStruct);
nTimeSeries = length(labels);

% pool our time series together into a matrix for ease of operation
for ii = 1:nTimeSeries
    if ~strcmp(labels{ii}, 'V1Combined')
        timeSeriesAccumulator(:,ii) = timeSeriesStruct.(labels{ii});
        splitNewLabel = strsplit(labels{ii}, '_');
        newLabels{ii} = [splitNewLabel{1}, ' ' splitNewLabel{2}];
    end
end

%% pool our time series together into left or right hemisphere groups
leftCounter = 1;
rightCounter = 1;
for ii = 1:nTimeSeries
    if ~strcmp(labels{ii}, 'V1Combined')
        splitNewLabel = strsplit(labels{ii}, '_');
        if strcmp(splitNewLabel{2}, 'rh')
            rhTimeSeriesAccumulator(:, rightCounter) = timeSeriesStruct.(labels{ii});
            splitNewLabel = strsplit(labels{ii}, '_');
            
            rhLabel{rightCounter} = [splitNewLabel{1}];
            rightCounter = rightCounter + 1;
        elseif strcmp(splitNewLabel{2}, 'lh')
            lhTimeSeriesAccumulator(:, leftCounter) = timeSeriesStruct.(labels{ii});
            splitNewLabel = strsplit(labels{ii}, '_');
            
            lhLabel{leftCounter} = [splitNewLabel{1}];
            
            leftCounter = leftCounter + 1;
            
        end
    end
    
end

if ~isempty(p.Results.desiredOrder)
    [values, rhIndices] = ismember(p.Results.desiredOrder, rhLabel);
    [values, lhIndices] = ismember(p.Results.desiredOrder, lhLabel);
    rhLabel = p.Results.desiredOrder;
    lhLabel = p.Results.desiredOrder;
    rhTimeSeriesAccumulator = rhTimeSeriesAccumulator(:, rhIndices);
    lhTimeSeriesAccumulator = lhTimeSeriesAccumulator(:, lhIndices);
end




% compute the correlation matrix for left and right sides
[rhCorrelationMatrix] = corrcoef(rhTimeSeriesAccumulator, 'Rows', 'complete');
[lhCorrelationMatrix] = corrcoef(lhTimeSeriesAccumulator, 'Rows', 'complete');

combinedCorrelationMatrix = [(rhCorrelationMatrix + lhCorrelationMatrix)/2];



% plot the rh correlation matrix
plotFig = figure;
imagesc(combinedCorrelationMatrix)

% pretty it up
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
title('Within Hemisphere')
colorbar
colors = redblue(100);
colormap(colors)
caxis([-1 1])

%% Compare across hemispheres
for rr = 1:length(rhLabel)
    for ll = 1:length(lhLabel)
        
        
        pearsonCorrelation = corrcoef(rhTimeSeriesAccumulator(:,rr), lhTimeSeriesAccumulator(:,ll), 'Rows', 'complete');
        pearsonCorrelation = pearsonCorrelation(1,2);
        
        acrossHemisphereCorrelationMatrix(rr,ll) = pearsonCorrelation;
        
    end
end

plotFig = figure;
imagesc(acrossHemisphereCorrelationMatrix)

% pretty it up
set(gca, 'XTick', 1:length(rhLabel))
set(gca, 'YTick', 1:length(rhLabel))
set(gca, 'XTickLabel', rhLabel)
set(gca, 'YTickLabel', rhLabel)
set(gca,'YDir','normal')
xlabel('Left Hemisphere')
ylabel('Right Hemisphere')
title('Between Hemisphere')
colorbar
colors = redblue(100);
colormap(colors)
caxis([-1 1])

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