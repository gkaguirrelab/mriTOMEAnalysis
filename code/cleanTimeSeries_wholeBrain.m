function [ cleanedFunctionalScan, betaVolume, rSquaredVolume, pearsonRVolume ] = cleanTimeSeries( functionalScan, regressors, regressorsTimebase, varargin)

p = inputParser; p.KeepUnmatched = true;
p.addParameter('meanCenterRegressors', true, @islogical);
p.addParameter('meanCenterVoxels', true, @islogical);
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
totalTime = functionalScan.tr*size(functionalScan.vol,4);

% add the timebases to the packets.
thePacket.stimulus.timebase = regressorsTimebase;
thePacket.response.timebase = 0:functionalScan.tr:totalTime-functionalScan.tr;

% mean center the regressors, if asked
if p.Results.meanCenterRegressors
    regressors = regressors - nanmean(regressors);
    regressors = regressors ./ nanstd(regressors);
end

% add the regressors to the
nRegressors = size(regressors,2);
for nn = 1:nRegressors
    
    thePacket.stimulus.values(end+1,:) = regressors(:,nn)';
    
end
defaultParamsInfo.nInstances = size(thePacket.stimulus.values,1);


%% Do the fitting
temporalFit = tfeIAMP('verbosity','none');
%% Loop over voxels, and perform the IAMP fit

% dimensions of our functional data
nXIndices = size(functionalScan.vol, 1);
nYIndices = size(functionalScan.vol, 2);
nZIndices = size(functionalScan.vol, 3);
nTRs = size(functionalScan.vol, 4);

betaVolume = functionalScan;
rSquaredVolume = functionalScan;
betaVolume.vol = [];
rSquaredVolume.vol = [];

cleanedFunctionalScan = functionalScan;
cleanedFunctionScan.vol = zeros(size(functionalScan.vol));

betaVolume = functionalScan;
betaVolume.vol = zeros(nXIndices, nYIndices, nZIndices, size(thePacket.stimulus.values,1));

pearsonRVolume = functionalScan;
pearsonRVolume.vol = zeros(nXIndices, nYIndices, nZIndices);

rSquaredVolume = functionalScan;
rSquaredVolume.vol = zeros(nXIndices, nYIndices, nZIndices);

totalIndices = nXIndices * nYIndices * nZIndices;

nWorkers = startParpool( [], true );
%parfor (ii = 1:totalIndices, nWorkers)
for ii = 1:totalIndices
    [xx, yy, zz] = ind2sub([nXIndices; nYIndices; nZIndices], ii);
    voxelTimeSeries = functionalScan.vol(xx,yy,zz,:);
    voxelTimeSeries = reshape(voxelTimeSeries,1,nTRs);
    
    thePacket.response.values = voxelTimeSeries;
    
    
    
    if ~isempty(find(thePacket.response.values,1))
        
        if (p.Results.meanCenterVoxels)
            thePacket.response.values = (thePacket.response.values - mean(thePacket.response.values))./nanstd(thePacket.response.values);
        end
        % TFE linear regression here
        [paramsFit,~,modelResponseStruct] = temporalFit.fitResponse(thePacket,...
            'defaultParamsInfo', defaultParamsInfo, 'errorType','1-r2', 'verbosity', 'none');
        
        % remove signal related to regressors to yield clean time series
        cleanedVoxelTimeSeries = thePacket.response.values - modelResponseStruct.values;
        
        beta = paramsFit.paramMainMatrix;
        
        correlationMatrix = corrcoef(modelResponseStruct.values, thePacket.response.values, 'Rows', 'complete');
        rSquared = correlationMatrix(1,2)^2;
        
        pearsonR = correlationMatrix(1,2);
    else
        cleanedVoxelTimeSeries = thePacket.response.values;
        beta = 0;
        rSquared = 0;
        pearsonR = 0;
    end
    
    cleanedFunctionalScan.vol(xx,yy,zz,:) = cleanedVoxelTimeSeries;
    betaVolume.vol(xx,yy,zz,:) = beta;
    rSquaredVolume.vol(xx,yy,zz,1) = rSquared;
    pearsonRVolume.vol(xx,yy,zz,1) = pearsonR;
    
    
    
    
    
end

%% Local function: to get parpool running
    function [ nWorkers ] = startParpool( nWorkers, verbose )
        % Open and configure the parpool
        %
        % Syntax:
        %  [ nWorkers ] = startParpool( nWorkers, verbosity )
        %
        % Description:
        %   Several stages of transparentTrack make use of the parpool. This
        %   routine opens the parpool (if it does not currently exist) and returns
        %   the number of available workers.
        %
        % Inputs:
        %   nWorkers              - Scalar. The number of workers requested.
        %   verbose               - Boolean. Defaults to false if not passed.
        %
        % Outputs:
        %   nWorkers              - Scalar. The number of workers available.
        %
        
        % Set the verbose flag to false if not passed
        if nargin==1
            verbose = false;
        end
        
        % Silence the timezone warning
        warningState = warning;
        warning('off','MATLAB:datetime:NonstandardSystemTimeZoneFixed');
        warning('off','MATLAB:datetime:NonstandardSystemTimeZone');
        
        % If a parallel pool does not exist, attempt to create one
        poolObj = gcp('nocreate');
        if isempty(poolObj)
            if verbose
                tic
                fprintf(['Opening parallel pool. Started ' char(datetime('now')) '\n']);
            end
            if isempty(nWorkers)
                parpool;
            else
                parpool(nWorkers);
            end
            poolObj = gcp;
            if isempty(poolObj)
                nWorkers=0;
            else
                nWorkers = poolObj.NumWorkers;
            end
            if verbose
                toc
                fprintf('\n');
            end
        else
            nWorkers = poolObj.NumWorkers;
        end
        
        % Restore the warning state
        warning(warningState);
        
    end % function -- startParpool

end