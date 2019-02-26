function [ timeVaryingCorrelation ] = calculateTimeVaryingCorrelation(timeSeriesOne, timeSeriesTwo, windowLength, varargin)

%{
subjectID = 'TOME_3005';
runName = 'rfMRI_REST_AP_Run1';
timeSeriesPath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID);
load(fullfile(timeSeriesPath, [runName, '_timeSeriesCIFTI']));

timebase = 0:800:420*800-800
timeSeriesOne = meanTimeSeries.V1v_lh_mask;
timeSeriesTwo = meanTimeSeries.V1v_rh_mask;
windowLength = 100;

[ timeVaryingCorrelation_slidingWindowPearson ] = calculateTimeVaryingCorrelation(timeSeriesOne, timeSeriesTwo, windowLength)
[ timeVaryingCorrelation_mtd ] = calculateTimeVaryingCorrelation(timeSeriesOne, timeSeriesTwo, windowLength, 'correlationMethod', 'mtd')

plotFig = figure;
hold on
plot(timebase, timeVaryingCorrelation_slidingWindowPearson);
plot(timebase, timeVaryingCorrelation_mtd);
legend('Sliding Window Pearson', 'MTD')

plotFig = figure;
subplot(1,2,1)
[ covariates ] = makeEyeSignalCovariates(subjectID, runName)
pupilStruct = [];
% resample the pupil data to the same temporal resolution as the BOLD data
pupilStruct.timebase = covariates.timebase;
pupilStruct.values = covariates.pupilDiameterConvolved;
temporalFit = tfeIAMP('verbosity','none');
pupilStruct = temporalFit.resampleTimebase(pupilStruct, timebase, 'resampleMethod', 'resample');
    

plot(pupilStruct.values, timeVaryingCorrelation_slidingWindowPearson, '.')
xlabel('Pupil Diameter Convolved (mm)');
ylabel('Sliding Window Pearson (mean centered)');

subplot(1,2,2)
plot(pupilStruct.values, timeVaryingCorrelation_mtd, '.')
xlabel('Pupil Diameter Convolved (mm)');
ylabel('MTD (mean centered)');

%}


p = inputParser; p.KeepUnmatched = true;

p.addParameter('correlationMethod', 'slidingWindowPearson', @ischar);
p.addParameter('normalizeTimeVaryingCorrelation', true, @islogical);

p.parse(varargin{:});

if strcmp(p.Results.correlationMethod, 'slidingWindowPearson')
    timeVaryingCorrelation = zeros(1,length(timeSeriesOne));
    timeVaryingCorrelation(1:windowLength) = NaN;
    timeVaryingCorrelation(end-windowLength+1:end) = NaN;
    
    for ii = round(windowLength/2)+1:length(timeSeriesOne) - round(windowLength/2)
        indicesInWindow = (ii - round(windowLength/2)):(ii + round(windowLength/2));
        
        correlationMatrix = corrcoef(timeSeriesOne(indicesInWindow), timeSeriesTwo(indicesInWindow));
        timeVaryingCorrelation(ii) = correlationMatrix(1,2);
    
    end
    
    timeVaryingCorrelation = (timeVaryingCorrelation - nanmean(timeVaryingCorrelation))./nanmean(timeVaryingCorrelation);
    
end

if strcmp(p.Results.correlationMethod, 'mtd')
   data = [timeSeriesOne', timeSeriesTwo']; 
   direction = 0; % middle, not forward
   trim = 1; % trim 0s
   mtd = coupling(data, windowLength, direction, trim);
   timeVaryingCorrelation = reshape(mtd(1,2,:), 1, 420);
   timeVaryingCorrelation = (timeVaryingCorrelation - nanmean(timeVaryingCorrelation))./nanmean(timeVaryingCorrelation);

end
   
    


%% Local function from the Basset group
function mtd = coupling(data,window,direction,trim)
%COUPLING        Time-resolved connectivity
%
%   MTD = coupling(data,window);
%   MTD = coupling(data,window,direction);
%   MTD = coupling(data,window,direction,trim);
%
%	Creates a functional coupling metric from an input matrix 'data'
%	data: should be organized in 'time x nodes' matrix
%	window: smoothing parameter for simple moving average of coupling metric (1 = forward; 0 = middle [default])
%   trim: whether to trim zeros from the end of the 3d matrix (1=yes; 0=no [default])
%
%   Inputs:
%       data,
%           time series data organized as TIME x NODES.
%       window,
%           window length (time points).
%       direction,
%           mirrored or forward facing window
%       trim,
%           determines whether to trim data or append with zeros.
%
%       Note: see Shine et al (2015) for a discussion of window length and smoothing options.
%
%   Outputs:
%       MTD,
%           time-varying connectivity matrix


    % check inputs and define variables
    
    if nargin==2
        direction=0; trim=0;
    elseif nargin==2
        trim=0;
    end

    [ts,nodes] = size(data);

    %calculate temporal derivative
    td = diff(data);

    %standardize data
    data_std = std(td);

    for i = 1:nodes
         td(:,i) = td(:,i) / data_std(1,i);
    end


    % [...] = zscore(X,FLAG,DIM) standardizes X by working along the dimension
    %    DIM of X. Pass in FLAG==0 to use the default normalization by N-1, or 1 to use N.


    %functional coupling score
    fc = bsxfun(@times,permute(td,[1,3,2]),permute(td,[1,2,3]));



    %temporal smoothing (credit: T. C. O'Haver, 2008.)
    mtd_temp = zeros(nodes,nodes,ts-1);
    
    for j = 1:nodes
        for k = 1:nodes
            mtd_temp(j,k,:) = smooth(squeeze(fc(:,j,k)),window);
        end
    end


    %window type (0 = middle; 1 = forward facing)

    mtd = zeros(nodes,nodes,ts);

    if direction == 1
        mtd(:,:,1:ts-round(window/2+1)) = mtd_temp(:,:,round(window/2+1):end);
    elseif direction == 0
        mtd(:,:,1:ts-1) = mtd_temp;
    end



    %trim ends (0 = no; 1 = yes)?

    if trim == 1 && direction == 0
        mtd(:,:,ts-round(window/2):end) = NaN;
        mtd(:,:,1:round(window/2)) = NaN;
    elseif trim == 1 && direction == 1
        mtd(:,:,(ts-window):end) = NaN;
    end

end

end