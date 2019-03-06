function [ cleanedTimeSeries, stats ] = cleanTimeSeries( inputTimeSeries, regressors, regressorsTimebase, varargin)
% Model regressors in inputted time series data.
%
% Syntax:
%  [ cleanedTimeSeries, stats ] = cleanTimeSeries( inputTimeSeries, regressors, regressorsTimebase)
%
% Description:
%  This routine loops over all voxels in the inputTimeSeries and
%  performs a regression of the inputted regressors against that BOLD
%  time series. The model fits of that regression are subtracted from
%  the original voxel time series to yield a "cleaned" time series. The
%  beta, pearson R, and R2 value of each regression are also outputted.
%
% Inputs:
%  inputTimeSeries: 		- a m x n matrix, where m corresponds to the number of time series
%							  and n corresponds to the number of TRs. The routine loops
%							  over rows.
%  regressors:				- a r x s matrix in which r corresponds to the number
%							  regressors and s corresponds to the number of timepoints
%							  for each regressor
%  regressorsTimebase       - the timebase that describes the regressors. It should be of
%							  the same length s as the number of columns of the regressors
%							  matrix.
%
% Optional key-value pairs:
%  'TR'                     - the length of time between each acquisition of the
%							  functional volume that gave the inputTimeSeries.
%  'totalTime'				- the total time, in ms, of the functional acqusition that
%							  gave the inputTimeSeries
%  'meanCenterRegressors'   - a logical that determines whether to mean center each regressor
%  'zeroNansInRegressors'   - a logical that determines whether to replace all NaN values
%							  with 0 in the regressor, after mean centering has been performed
%  'saveName'				- a string that determines where to save any of the results.
%						      If empty, the default, nothing is saved.
%
% Outputs:
%  cleanedTimeSeries        - a m x n matrix, where m corresponds to the number of time series
%							  and n corresponds to the number of TRs. The routine loops
%							  over rows. The values of each voxel represent the residual
%							  after the regression was performed.
%  stats					- A structure with subfields beta, pearsonR, and rSquared that
%							  describe the summary statistics from the regression for each
%							  time series.  Each subfield is a vector of with length equal
%							  to the number of time series.

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
nRegressors = size(regressors,1);
regressorsOriginal = regressors;
if p.Results.meanCenterRegressors
    for nn = 1:nRegressors
        regressors(nn,:) = meanCenterTimeSeries(regressors(nn,:));
        
        % if desired, remove NaN values and replace them with 0. As these
        % covariates are being mean centered, putting NaN values at 0
        % essentially makes them irrelevant in determining final scaling.
        if (p.Results.zeroNansInRegressors)
            nanIndices = find(isnan(regressors(nn,:)));
            regressors(nn,nanIndices) = 0;
        end
    end
else
    for nn = 1:nRegressors
        if (p.Results.zeroNansInRegressors)
            nanIndices = find(isnan(regressors(nn,:)));
            regressors(nn,nanIndices) = 0;
        end
    end
end

% add the regressors to the
for nn = 1:nRegressors
    
    thePacket.stimulus.values(end+1,:) = regressors(nn,:);
    
end
defaultParamsInfo.nInstances = size(thePacket.stimulus.values,1);


%% Do the fitting
temporalFit = tfeIAMP('verbosity','none');
nTimeSeries = size(inputTimeSeries,1);
for tt = 1:nTimeSeries
    
    % load up the time series data from our given row
    thePacket.response.values = inputTimeSeries(tt,:);
    
    % if the entire response is 0s or NaNs, don't bother trying to fit.
    if sum(any(thePacket.response.values)) == 0 || sum(isnan(thePacket.response.values)) == length(thePacket.response.values)
        cleanedTimeSeries(tt,:) = thePacket.response.values;
        beta(tt,:) = NaN;
        rSquared(tt) = NaN;
        pearsonR(tt) = NaN;
    else
        % TFE linear regression 
        [paramsFit,~,modelResponseStruct] = temporalFit.fitResponse(thePacket,...
            'defaultParamsInfo', defaultParamsInfo, 'searchMethod','linearRegression','errorType','1-r2');        
        
        % remove signal related to regressors to yield clean time series
        cleanedTimeSeries(tt,:) = thePacket.response.values - modelResponseStruct.values;
        
        % save out stats
        beta(tt,:) = paramsFit.paramMainMatrix;
        correlationMatrix = corrcoef(modelResponseStruct.values, thePacket.response.values, 'Rows', 'complete');
        rSquared(tt) = correlationMatrix(1,2)^2;
        pearsonR(tt) = correlationMatrix(1,2);
        
    end
    
end

% package up the stats
stats.beta = beta';
stats.rSquared = rSquared;
stats.pearsonR = pearsonR;

% save out stats, if desired
if ~isempty(p.Results.saveName)
    
    
    saveName = p.Results.saveName;
    [savePath, fileName ] = fileparts(saveName);
    
    if ~exist(savePath, 'dir')
        mkdir(savePath);
    end
    
    
    save(saveName, 'cleanedTimeSeries', '-v7.3');
    
end

end