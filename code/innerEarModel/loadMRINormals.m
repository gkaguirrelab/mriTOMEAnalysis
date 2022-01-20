function [lateralMRILeft, lateralMRIRight, ...
          anteriorMRILeft, anteriorMRIRight, ...
          posteriorMRILeft, posteriorMRIRight] = loadMRINormals(planeFolder)
    
%     % This function loads normal files
%       
%     lateralMRILeft = load(fullfile(planeFolder, 'left_lat.mat'), 'normal').normal;
%     lateralMRIRight = load(fullfile(planeFolder, 'right_lat.mat'), 'normal').normal;
%     anteriorMRILeft = load(fullfile(planeFolder, 'left_ant.mat'), 'normal').normal;
%     anteriorMRIRight = load(fullfile(planeFolder, 'right_ant.mat'), 'normal').normal;
%     posteriorMRILeft = load(fullfile(planeFolder, 'left_post.mat'), 'normal').normal;
%     posteriorMRIRight = load(fullfile(planeFolder, 'right_post.mat'), 'normal').normal;
%     
%     This calculates PCA from points
    lateralMRILeft_points = pca(load(fullfile(planeFolder, 'left_lat.mat'), 'point_array').point_array);
    lateralMRIRight_points = pca(load(fullfile(planeFolder, 'right_lat.mat'), 'point_array').point_array);
    anteriorMRILeft_points = pca(load(fullfile(planeFolder, 'left_ant.mat'), 'point_array').point_array);
    anteriorMRIRight_points = pca(load(fullfile(planeFolder, 'right_ant.mat'), 'point_array').point_array);
    posteriorMRILeft_points = pca(load(fullfile(planeFolder, 'left_post.mat'), 'point_array').point_array);
    posteriorMRIRight_points = pca(load(fullfile(planeFolder, 'right_post.mat'), 'point_array').point_array);    
    
    lateralMRILeft = lateralMRILeft_points(:,3);
    lateralMRIRight = lateralMRIRight_points(:,3);
    anteriorMRILeft = anteriorMRILeft_points(:,3);
    anteriorMRIRight = anteriorMRIRight_points(:,3);
    posteriorMRILeft = posteriorMRILeft_points(:,3);
    posteriorMRIRight = posteriorMRIRight_points(:,3);

    % Here I manually change signs to make all normals point to the same 
    % direction. Not RAS yet.
    if contains(planeFolder, 'TOME_3007') || contains(planeFolder, 'TOME_3014') || contains(planeFolder, 'TOME_3021') || contains(planeFolder, 'TOME_3022') || contains(planeFolder, 'TOME_3030') || contains(planeFolder, 'TOME_3044')  
        posteriorMRILeft = -posteriorMRILeft;   
    elseif contains(planeFolder, 'TOME_3024')     
        anteriorMRIRight = -anteriorMRIRight;  
    end
    
    anteriorMRIRight = -anteriorMRIRight;
end
          