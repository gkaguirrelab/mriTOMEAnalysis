function [ statsVolume ] = makeWholeBrainMap(stats, voxelIndices, templateVolume)

%% Set up our output variable
statsVolume = templateVolume;
nStats = size(stats,2);
statsVolume.vol = zeros(size(templateVolume.vol,1), size(templateVolume.vol,2), size(templateVolume.vol,3), nStats);
clear templateVolume;

%% checks on the inputted data
% make sure the length of the stats vector is as long as the length of the
% cell array voxel indices
assert(size(stats,1) == length(voxelIndices));

%% Loop over voxels, stashing the relevant results within the voxel
for vv = 1:length(voxelIndices)
    
    % determine the coordiantes for the relevant voxel
    xx = voxelIndices{vv}(1);
    yy = voxelIndices{vv}(2);
    zz = voxelIndices{vv}(3);
    
    % stash the result in that voxel
    statsVolume.vol(xx,yy,zz,:) = stats(vv, :);
    
end

end