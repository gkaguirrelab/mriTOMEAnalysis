function [ meanCenteredTimeSeries ] = meanCenterTimeSeries( timeSeries )
%


% determine the number of time series
nTimeSeries = size(timeSeries, 1);

dims = size(timeSeries);
dimsize = size(timeSeries,2);
dimrep = ones(1,length(dims));
dimrep(2) = dimsize;

meanCenteredTimeSeries = (timeSeries - repmat(mean(timeSeries,2),dimrep))./repmat(mean(timeSeries,2),dimrep);

end