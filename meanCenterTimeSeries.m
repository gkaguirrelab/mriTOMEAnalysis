function [ meanCenteredTimeSeries ] = meanCenterTimeSeries( timeSeries )
%


% determine the number of time series
nTimeSeries = size(timeSeries, 1);

for rr = 1:nTimeSeries
    meanCenteredTimeSeries(rr,:) = (timeSeries(rr,:) - nanmean(timeSeries(rr,:))./nanmean(timeSeries(rr,:));
end

end