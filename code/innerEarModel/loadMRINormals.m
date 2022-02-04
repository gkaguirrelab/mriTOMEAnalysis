function [lateralMRILeft, lateralMRIRight, ...
          anteriorMRILeft, anteriorMRIRight, ...
          posteriorMRILeft, posteriorMRIRight] = loadMRINormals(planeFolder, useAllFids)

    if ~true(useAllFids)
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
    else
        lateralFidsLeft = cellfun(@(x)regexp(x,',','split'),splitlines(fileread(fullfile(planeFolder, 'fids_InnerEarAtlas_SSC_lat_left.fcsv'))),'UniformOutput',0);
        lateralFidsRight = cellfun(@(x)regexp(x,',','split'),splitlines(fileread(fullfile(planeFolder, 'fids_InnerEarAtlas_SSC_lat_right.fcsv'))),'UniformOutput',0);
        anteriorFidsLeft = cellfun(@(x)regexp(x,',','split'),splitlines(fileread(fullfile(planeFolder, 'fids_InnerEarAtlas_SSC_ant_left.fcsv'))),'UniformOutput',0);
        anteriorFidsRight = cellfun(@(x)regexp(x,',','split'),splitlines(fileread(fullfile(planeFolder, 'fids_InnerEarAtlas_SSC_ant_right.fcsv'))),'UniformOutput',0);
        posteriorFidsLeft = cellfun(@(x)regexp(x,',','split'),splitlines(fileread(fullfile(planeFolder, 'fids_InnerEarAtlas_SSC_post_left.fcsv'))),'UniformOutput',0);
        posteriorFidsRight = cellfun(@(x)regexp(x,',','split'),splitlines(fileread(fullfile(planeFolder, 'fids_InnerEarAtlas_SSC_post_right.fcsv'))),'UniformOutput',0);        
        
        lateralFidsLeft = pca(cell2mat(cellfun(@(x) [str2num(x{2}) str2num(x{3}) str2num(x{4})], lateralFidsLeft(4:end), 'UniformOutput', false)));
        lateralFidsRight = pca(cell2mat(cellfun(@(x) [str2num(x{2}) str2num(x{3}) str2num(x{4})], lateralFidsRight(4:end), 'UniformOutput', false)));
        anteriorFidsLeft = pca(cell2mat(cellfun(@(x) [str2num(x{2}) str2num(x{3}) str2num(x{4})], anteriorFidsLeft(4:end), 'UniformOutput', false)));
        anteriorFidsRight = pca(cell2mat(cellfun(@(x) [str2num(x{2}) str2num(x{3}) str2num(x{4})], anteriorFidsRight(4:end), 'UniformOutput', false)));
        posteriorFidsLeft = pca(cell2mat(cellfun(@(x) [str2num(x{2}) str2num(x{3}) str2num(x{4})], posteriorFidsLeft(4:end), 'UniformOutput', false)));
        posteriorFidsRight = pca(cell2mat(cellfun(@(x) [str2num(x{2}) str2num(x{3}) str2num(x{4})], posteriorFidsRight(4:end), 'UniformOutput', false)));
        
        lateralMRILeft = lateralFidsLeft(:,3);
        lateralMRIRight = lateralFidsRight(:,3);
        anteriorMRILeft = anteriorFidsLeft(:,3);
        anteriorMRIRight = anteriorFidsRight(:,3);
        posteriorMRILeft = posteriorFidsLeft(:,3);
        posteriorMRIRight = posteriorFidsRight(:,3);
    end
    
        % Here I manually change signs to make all normals point to the same 
        % direction. Not RAS yet.
        if contains(planeFolder, 'TOME_3014') || contains(planeFolder, 'TOME_3021') || contains(planeFolder, 'TOME_3022') || contains(planeFolder, 'TOME_3044')  
            posteriorMRILeft = -posteriorMRILeft;   
        end

        anteriorMRIRight = -anteriorMRIRight;    
    
end
          