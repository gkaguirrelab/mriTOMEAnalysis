function [ meanCenteredTimeSeries ] = meanCenterTimeSeries( timeSeries )
% Mean center time series within a matrix
%
% Syntax:
%  [ meanCenteredTimeSeries ] = meanCenterTimeSeries( timeSeries )
%
% Description:
%  This routine will mean center and normalize each row of a time series
%  matrix. The last part of the routine is some kind of bug fix, where I
%  have noticed that sometimes all elements of a time series are 0, which
%  when trying to normalize results in NaN values. Later tfe seems to
%  prefer 0s in this context, so I force these all NaN rows to be all 0s.
%
% Inputs:
%  timeSeries:              - a m x n matrix, where m represents different
%                             time series of n observations each
%
% Outputs:
%  meanCenteredTimeSeries  - a m x n matrix, where m represents different
%                             time series of n observations each, following
%                             mean-centering and normalization.



% determine the number of time series
nTimeSeries = size(timeSeries, 1);

% determine the other dimensions, including the number of time points
dims = size(timeSeries);
dimsize = size(timeSeries,2);
dimrep = ones(1,length(dims));
dimrep(2) = dimsize;

% perform the mean centering
meanCenteredTimeSeries = (timeSeries - repmat(mean(timeSeries,2),dimrep))./repmat(mean(timeSeries,2),dimrep);

% determine if there are any all NaN rows, which would result if the input
% was row was all 0
NaNRows = find(all(isnan(meanCenteredTimeSeries),2));
for ii = 1:length(NaNRows)
   meanCenteredTimeSeries(NaNRows(ii),:) = zeros(1, dimsize); 
end

end