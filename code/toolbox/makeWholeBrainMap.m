function makeWholeBrainMap(stats, voxelIndices, templateFile, saveName, varargin)
% Make whole-brain map from the inputted stats.
%
% Syntax:
%  [ statsVolume ] = makeWholeBrainMap(stats, voxelIndices, templateFile)
%
% Inputs:
%  stats: 					- A vector of with length equal
%							  to the number of voxels of interest. The
%							  value of each vector will be placed into a
%							  voxel on a whole brain map
%  voxelIndices             - a 1 x m cell array, where m corresponds to the
%                             number of voxels of interest. The contents of
%                             each cell is the x, y, and z coordinates of
%                             where that voxel came from. The value of m
%                             corresponds to the voxel identity of the row of
%                             timeSeriesPerVoxel
%  templateFile			    - a string that defines the full path to the a
%                             template which shows what type of output we
%                             want to create
%

%% Input parser
p = inputParser; p.KeepUnmatched = true;
p.addParameter('workbenchPath', '/Applications/workbench/bin_macosx64/', @ischar);
p.parse(varargin{:});


%% Determine whether we're working with a volume or CIFTI
if contains(templateFile, 'dtseries') || contains(templateFile, 'dscalar')
    fileType = 'CIFTI';
else
    fileType = 'volume';
end


if strcmp(fileType, 'volume')
    %% checks on the inputted data
    % make sure the length of the stats vector is as long as the length of the
    % cell array voxel indices
    assert(size(stats,1) == length(voxelIndices));
    
    %% Set up our output variable
    templateVolume = MRIread(templateFile);
    statsVolume = templateVolume;
    nStats = size(stats,2);
    statsVolume.vol = zeros(size(templateVolume.vol,1), size(templateVolume.vol,2), size(templateVolume.vol,3), nStats);
    clear templateVolume;
    %% Loop over voxels, stashing the relevant results within the voxel
    for vv = 1:length(voxelIndices)
        
        % determine the coordiantes for the relevant voxel
        xx = voxelIndices{vv}(1);
        yy = voxelIndices{vv}(2);
        zz = voxelIndices{vv}(3);
        
        % stash the result in that voxel
        statsVolume.vol(xx,yy,zz,:) = stats(vv, :);
        
    end
    MRIwrite(statsVolume, saveName);
end

if strcmp(fileType, 'CIFTI')
    % figure out where template file lives. we'll stash temporary results
    % there
    [ savePath ] = fileparts(templateFile);
    
    % write out the stats to a text file
    dlmwrite(fullfile(savePath, 'stats.txt'), stats', 'delimiter','\t')    
    % make the dscalar file
    system(['bash ', p.Results.workbenchPath, 'wb_command -cifti-convert -from-text "', fullfile(savePath, 'stats.txt'), '" "', templateFile, '" "', saveName, '"']);

end