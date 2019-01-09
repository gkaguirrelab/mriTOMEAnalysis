function [ meanTimeSeries, timeSeriesPerVoxel, voxelIndices ] = extractTimeSeriesFromMask( functionalScan, mask, varargin )
% This function extract the time series from each voxel included in the
% inputted mask.
%
% Syntax:
%  [ meanTimeSeries, timeSeriesPerVoxel, voxelIndices ] = extractTimeSeriesFromMask( functionalScan, mask)
%
% Description:
%  This routine loops over every non-zero voxel included in the inputted
%  gray matter mask. For each voxel, we extract the time series from the
%  inputted functional volume in that same voxel location. We save these
%  extracted time series in a matrix. The routine can also meanCenter the
%  time series of each voxel, if desired. The central tendency of all
%  voxels is also outputted, and it can be specified whether the central
%  tendency should be mean, median, or PCA. The routine will also plot the
%  "mean" time series across all voxels.
%
% Inputs:
%  functionalScan:      - a structure that represents the functional scan
%                         of interest
%  mask:                - a structure, in which the .vol subfield specifies
%                         the voxels of interest. Voxels that are 0 are
%                         ignored, voxels that are 1 indicate to extract
%                         the time series from the functional volume from
%                         the corresponding voxel.
%
% Optional key-value pairs:
%  'meanCenter'         - a logical, which determines whether or not to mean
%                         center the time series of each voxel.
%  'whichCentralTendency' - a string which determines how to take the
%                         central tendency across voxels. Options include
%                         'mean', 'median', or 'PCA'.
%  'saveName'           - a string which specifies the full path to which
%                         to save the relevant output of this code. If
%                         empty, no results will be saved out.
%
% Outputs:
%  meanTimeSeries:       - a 1 x n vector, where n is the number of TRs in
%                          the functional volume. The value at each TR is
%                          the chosen central tendency across all voxels
%  timeSeriesPerVoxel    - a m x n matrix, where m specifies the number of
%                          voxels and n specifies the number of TRs. Each
%                          row is the time series of each voxel, and these
%                          results may or may not have been mean centered
%                          depending on the key-value pair 'meanCenter'
%  voxelIndices          - a 1 x m cell array, where m corresponds to the
%                          number of voxels of interest. The contents of
%                          each cell is the x, y, and z coordinates of
%                          where that voxel came from. The value of m
%                          corresponds to the voxel identity of the row of
%                          timeSeriesPerVoxel

%% Input Parser
p = inputParser; p.KeepUnmatched = true;
p.addParameter('meanCenter', true, @islogical);
p.addParameter('whichCentralTendency', 'mean', @ischar);
p.addParameter('saveName', [], @ischar);
p.parse(varargin{:});

%% Apply the mask
% confirm that registration happened the way we think we did and that
% freeview isn't misleading us. if we visualize this, such as with imagesec
% in MATLAB, we can see that the zero'ed out voxels are largely where we'd
% want them to be in v1
superImposedMask.vol = (1-mask.vol).*functionalScan.vol;



accumulatedTimeSeries_withZeros = mask.vol.*functionalScan.vol; % still contains voxels with 0s

% convert 4D matrix to 2D matrix, where each row is a separate time series
% corresponding to a different voxel in the mask

% dimensions of our functional data
nXIndices = size(accumulatedTimeSeries_withZeros, 1);
nYIndices = size(accumulatedTimeSeries_withZeros, 2);
nZIndices = size(accumulatedTimeSeries_withZeros, 3);
nTRs = size(accumulatedTimeSeries_withZeros, 4);

% variable to pool voxels that have not been masked out
timeSeriesPerVoxel = [];
nNonZeroVoxel = 1;

for xx = 1:nXIndices
    for yy = 1:nYIndices
        for zz = 1:nZIndices
            if ~isempty(find([accumulatedTimeSeries_withZeros(xx,yy,zz,:)] ~= 0))
                timeSeriesPerVoxel(nNonZeroVoxel,:) = functionalScan.vol(xx,yy,zz,:);
                timeSeriesPerVoxel(nNonZeroVoxel, :) = reshape(timeSeriesPerVoxel(nNonZeroVoxel,:),1,nTRs);
                voxelIndices{nNonZeroVoxel} = [xx, yy, zz];
                nNonZeroVoxel = nNonZeroVoxel + 1;
            end
        end
    end
end

% mean center each row
if p.Results.meanCenter
    for rr = 1:size(timeSeriesPerVoxel)
        
        runData = timeSeriesPerVoxel(rr,:);
        
        
        % convert to percent signal change relative to the mean
        voxelMeanVec = mean(runData,2);
        PSC = ((runData - voxelMeanVec)./voxelMeanVec);
        timeSeriesPerVoxel(rr,:) = PSC;
    end
    
end


% take the mean
plotFig = figure;

% take the central tendency
if strcmp(p.Results.whichCentralTendency, 'mean')
    
    meanTimeSeries = mean(timeSeriesPerVoxel,1);
elseif strcmp(p.Results.whichCentralTendency, 'median')
    meanTimeSeries = median(timeSeriesPerVoxel,1);
elseif strcmp(p.Results.whichCentralTendency, 'PCA')
    [coeffs] = pca(timeSeriesPerVoxel);
    meanTimeSeries = coeffs(:,1);
end


tr = functionalScan.tr/1000;
timebase = 0:tr:(length(meanTimeSeries)*tr-tr);
plot(timebase, meanTimeSeries)
set(gcf, 'un', 'n', 'pos', [0.05 .05 1 0.4])
xlabel('Time (s)')
ylabel('BOLD Signal')

if ~isempty(p.Results.saveName)
    
    
    saveName = p.Results.saveName;
    [savePath, fileName ] = fileparts(saveName);
    
    if ~exist(savePath, 'dir')
        mkdir(savePath);
    end
    
    saveas(plotFig, [saveName, '.png'], 'png')

    save(saveName, 'meanTimeSeries', 'timeSeriesPerVoxel', 'voxelIndices', '-v7.3');
    
end


end

