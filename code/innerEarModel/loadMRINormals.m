function [lateralMRILeft, lateralMRIRight, ...
          anteriorMRILeft, anteriorMRIRight, ...
          posteriorMRILeft, posteriorMRIRight] = loadMRINormals(planeFolder)
    
    % This function loads normal files
      
    lateralMRILeft = load(fullfile(planeFolder, 'left_lat.mat'), 'normal').normal;
    lateralMRIRight = load(fullfile(planeFolder, 'right_lat.mat'), 'normal').normal;
    anteriorMRILeft = load(fullfile(planeFolder, 'left_ant.mat'), 'normal').normal;
    anteriorMRIRight = load(fullfile(planeFolder, 'right_ant.mat'), 'normal').normal;
    posteriorMRILeft = load(fullfile(planeFolder, 'left_post.mat'), 'normal').normal;
    posteriorMRIRight = load(fullfile(planeFolder, 'right_post.mat'), 'normal').normal;

end
          