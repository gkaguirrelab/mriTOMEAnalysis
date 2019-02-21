function [ meanCenteredTimeSeries ] = meanCenterTimeSeries( timeSeries )
%


% determine the number of time series
nTimeSeries = size(timeSeries, 1);

dims = size(timeSeries);
dimsize = size(timeSeries,2);
dimrep = ones(1,length(dims));
dimrep(2) = dimsize;

meanCenteredTimeSeries = (timeSeries - repmat(mean(timeSeries,2),dimrep))./repmat(mean(timeSeries,2),dimrep);

% determine if there are any all NaN rows, which would result if the input
% was row was all 0
NaNRows = find(all(isnan(meanCenteredTimeSeries),2));
for ii = 1:length(NaNRows)
   meanCenteredTimeSeries(NaNRows(ii),:) = zeros(1, dimsize); 
end

end