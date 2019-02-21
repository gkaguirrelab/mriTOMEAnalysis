function [ meanTimeSeries, timeSeriesPerRow] = extractTimeSeriesFromMaskCIFTI(mask, grayordinates)

% expand mask to be of the same dimension as the grayordinates
expandedMask = repmat(mask, 1, size(grayordinates,2));

timeSeriesPerRow = grayordinates .* timeSeriesPerRow;
timeSeriesPerRow = timeSeriesPerRow(any(timeSeriesPerRow,2),:);


end