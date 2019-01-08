function [ statsVolume ] = makeWholeBrainMap(stats, voxelIndices, templateVolume)
% Make whole-brain map from the inputted stats.
%
% Syntax:
%  [ statsVolume ] = makeWholeBrainMap(stats, voxelIndices, templateVolume)
%
% Inputs:
%  stats: 					- A vector of with length equal 
%							  to the number of voxels of interest. The value of each vector 
% 							  will be placed into a voxel on a whole brain map
%  voxelIndices             - a 1 x m cell array, where m corresponds to the
%                             number of voxels of interest. The contents of
%                             each cell is the x, y, and z coordinates of
%                             where that voxel came from. The value of m
%                             corresponds to the voxel identity of the row of
%                             timeSeriesPerVoxel
%  templateVolume			- a structure that represents the functional volume of interest. 
%							  It is used as a template for how the voxels are arranged.
%
% Outputs:
%  statsVolume				- a structure, where the .vol subfield contains the inputted 
%						      stats at the appropriate voxel location


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