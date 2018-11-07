function [ cleanedTimeSeries ] = cleanTimeSeries( inputTimeSeries, regressors, varargin)

p = inputParser; p.KeepUnmatched = true;
p.addParameter('TR',800, @isnumber);
p.addParameter('meanCenterRegressors', true, @islogical);
p.parse(varargin{:});


%% Start assembling the packet
% stuff that we won't need to fill on
thePacket.kernel = [];
thePacket.metaData = [];
thePacket.stimulus.timebase = [];
thePacket.stimulus.values = [];
thePacket.response.timebase = [];
thePacket.response.values = [];

% makig the timebase
TR = p.Results.TR;
deltaT = 0.8*1000;
totalTime = 336*1000;

% this will serve as the timebase for both the response as well as the
% regressors
timebase = 0:deltaT:totalTime-TR;

% add the timebases to the packets.
thePacket.stimulus.timebase = timebase;
thePacket.response.timebase = timebase;

% mean center the regressors, if asked
regressors = regressors - nanmean(regressors);
regressors = regressors ./ nanstd(regressors);

% add the regressors to the 
nRegressors = size(regressors,2);
for nn = 1:nRegressors
    
    thePacket.stimulus.values(end+1,:) = regressors(:,nn)';
    
end
defaultParamsInfo.nInstances = size(thePacket.stimulus.values,1);


%% Do the fitting
temporalFit = tfeIAMP('verbosity','none');
nTimeSeries = size(inputTimeSeries,1);
for tt = 1:nTimeSeries
    
    thePacket.response.values = inputTimeSeries(tt,:);
    
    % TFE linear regression here
    [paramsFit,fVal,modelResponseStruct] = temporalFit.fitResponse(thePacket,...
        'defaultParamsInfo', defaultParamsInfo, 'searchMethod','linearRegression','errorType','1-r2');
    
    % remove signal related to regressors to yield clean time series
    cleanedTimeSeries(tt,:) = thePacket.response.values - modelResponseStruct.values;
    
end

end