function [lateralMRILeft, lateralMRIRight, ...
          anteriorMRILeft, anteriorMRIRight, ...
          posteriorMRILeft, posteriorMRIRight] = loadMRINormals(planeFolder)
      
      
    lateralMRILeft = load(fullfile(planeFolder, 'left_lat.mat'), 'normal');
    lateralMRIRight = load(fullfile(planeFolder, 'right_lat.mat'), 'normal');
    anteriorMRILeft = load(fullfile(planeFolder, 'left_ant.mat'), 'normal');
    anteriorMRIRight = load(fullfile(planeFolder, 'right_ant.mat'), 'normal');
    posteriorMRILeft = load(fullfile(planeFolder, 'left_post.mat'), 'normal');
    posteriorMRIRight = load(fullfile(planeFolder, 'right_post.mat'), 'normal');

end
          