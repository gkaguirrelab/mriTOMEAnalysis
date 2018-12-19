function [ cleanedTimeSeries, stats ] = cleanTimeSeries( inputTimeSeries, regressors, regressorsTimebase, varargin)

p = inputParser; p.KeepUnmatched = true;
p.addParameter('TR',800, @isnumber);
p.addParameter('totalTime',336000, @isnumber);
p.addParameter('meanCenterRegressors', true, @islogical);
p.addParameter('zeroNansInRegressors', true, @islogical);
p.addParameter('saveName', [], @ischar);
p.parse(varargin{:});


%% Start assembling the packet
% stuff that we won't need to fill on
thePacket.kernel = [];
thePacket.metaData = [];
thePacket.stimulus.timebase = [];
thePacket.stimulus.values = [];
thePacket.response.timebase = [];
thePacket.response.values = [];

% based on the number of samples, we can figure out the timebase
totalTime = p.Results.totalTime;

% add the timebases to the packets.
thePacket.stimulus.timebase = regressorsTimebase;
thePacket.response.timebase = 0:p.Results.TR:totalTime-p.Results.TR;

% mean center the regressors, if asked
nRegressors = size(regressors,2);
regressorsOriginal = regressors;
if p.Results.meanCenterRegressors
    for nn = 1:nRegressors
        regressors(:,nn) = regressors(:,nn) - nanmean(regressors(:,nn));
        regressors(:,nn) = regressors(:,nn) ./ nanstd(regressors(:,nn));
        if (p.Results.zeroNansInRegressors)
            nanIndices = find(isnan(regressors(:,nn)));
            regressors(nanIndices,nn) = 0;
        end
    end
else
    for nn = 1:nRegressors
        if (p.Results.zeroNansInRegressors)
            nanIndices = find(isnan(regressors(:,nn)));
            regressors(nanIndices,nn) = 0;
        end
    end
end

% add the regressors to the 
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
    [paramsFit,~,modelResponseStruct] = temporalFit.fitResponse(thePacket,...
       'defaultParamsInfo', defaultParamsInfo, 'searchMethod','linearRegression','errorType','1-r2');
%        'defaultParamsInfo', defaultParamsInfo, 'errorType','1-r2', 'verbosity', 'none');
    

    % remove signal related to regressors to yield clean time series
    cleanedTimeSeries(tt,:) = thePacket.response.values - modelResponseStruct.values;
    beta(tt,:) = paramsFit.paramMainMatrix;
    correlationMatrix = corrcoef(modelResponseStruct.values, thePacket.response.values, 'Rows', 'complete');
    rSquared(tt) = correlationMatrix(1,2)^2;
    pearsonR(tt) = correlationMatrix(1,2);
    
end

stats.beta = beta;
stats.rSquared = rSquared;
stats.pearsonR = pearsonR;

if ~isempty(p.Results.saveName)
    
    
    saveName = p.Results.saveName;
    [savePath, fileName ] = fileparts(saveName);
    
    if ~exist(savePath, 'dir')
        mkdir(savePath);
    end
    

    save(saveName, 'cleanedTimeSeries', '-v7.3');
    
end

end