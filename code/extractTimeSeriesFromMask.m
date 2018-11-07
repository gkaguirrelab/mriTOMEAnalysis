function [ meanTimeSeries, timeSeriesPerVoxel ] = extractTimeSeriesFromMask( functionalScan, mask, varargin )
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
                for tr = 1:nTRs
                    % stash voxels that hvae not been masked out
                    timeSeriesPerVoxel(nNonZeroVoxel, tr) = accumulatedTimeSeries_withZeros(xx,yy,zz,tr);
                end
                voxelIndices{nNonZeroVoxel} = [xx, yy, zz];
                nNonZeroVoxel = nNonZeroVoxel + 1;
            end
        end
    end
end

% mean center each row
for rr = 1:size(timeSeriesPerVoxel)
    
    runData = timeSeriesPerVoxel(rr,:);
    
    if p.Results.meanCenter
        % convert to percent signal change relative to the mean
        voxelMeanVec = mean(runData,2);
        PSC = 100*((runData - voxelMeanVec)./voxelMeanVec);
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

