function [ meanTimeSeries, timeSeriesPerRow] = extractTimeSeriesFromMaskCIFTI(mask, grayordinates, varargin)

%% Input Parser
p = inputParser; p.KeepUnmatched = true;
p.addParameter('meanCenter', true, @islogical);
p.addParameter('whichCentralTendency', 'mean', @ischar);
p.addParameter('saveName', [], @ischar);
p.parse(varargin{:});

% expand mask to be of the same dimension as the grayordinates
expandedMask = repmat(mask, 1, size(grayordinates,2));

timeSeriesPerRow = grayordinates .* expandedMask;
timeSeriesPerRow = timeSeriesPerRow(any(timeSeriesPerRow,2),:);

if p.Results.meanCenter
    timeSeriesPerRow = meanCenterTimeSeries(timeSeriesPerRow);
end

if strcmp(p.Results.whichCentralTendency, 'mean')    
    meanTimeSeries = mean(timeSeriesPerRow,1);
elseif strcmp(p.Results.whichCentralTendency, 'median')
    meanTimeSeries = median(timeSeriesPerRow,1);
elseif strcmp(p.Results.whichCentralTendency, 'PCA')
    [coeffs] = pca(timeSeriesPerRow);
    meanTimeSeries = coeffs(:,1);
end

end