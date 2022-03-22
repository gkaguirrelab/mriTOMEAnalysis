function [lateralMRILeft, lateralMRIRight, ...
          anteriorMRILeft, anteriorMRIRight, ...
          posteriorMRILeft, posteriorMRIRight] = loadMRINormals(planeFolder, useAllFids)

      % This function loads fidicuals for each canal for a single subject
      % that were downloaded with the downloadSubjectNormals.m function.
      % Then it does PCA on these markups to find the vectors that are
      % parallel to the plane. Finally, it rotates the sigh of the TOME
      % vectors that have an opposite sign of the majority of vectors
      %    Inputs:
      %        planeFolder: A subject folder created by the downloadSubjectNormals.m function
      %        useAllFids: If set to true, the function uses all fidicuals
      %                    if false, use 5 main ones. We used only 5 for
      %                    the inner ear analysis.
      
    % If use all fids  
    if isequal(useAllFids, 0)
        % Calculate PCA 
        lateralMRILeft_points = pca(load(fullfile(planeFolder, 'left_lat.mat'), 'point_array').point_array);
        lateralMRIRight_points = pca(load(fullfile(planeFolder, 'right_lat.mat'), 'point_array').point_array);
        anteriorMRILeft_points = pca(load(fullfile(planeFolder, 'left_ant.mat'), 'point_array').point_array);
        anteriorMRIRight_points = pca(load(fullfile(planeFolder, 'right_ant.mat'), 'point_array').point_array);
        posteriorMRILeft_points = pca(load(fullfile(planeFolder, 'left_post.mat'), 'point_array').point_array);
        posteriorMRIRight_points = pca(load(fullfile(planeFolder, 'right_post.mat'), 'point_array').point_array);           
        
        % 3rd eigenvector is the plane normal
        lateralMRILeft = lateralMRILeft_points(:,3);
        lateralMRIRight = lateralMRIRight_points(:,3);
        anteriorMRILeft = anteriorMRILeft_points(:,3);
        anteriorMRIRight = anteriorMRIRight_points(:,3);
        posteriorMRILeft = posteriorMRILeft_points(:,3);
        posteriorMRIRight = posteriorMRIRight_points(:,3);

        % Here I manually change signs to make all normals point to the same 
        % direction.
        if contains(planeFolder, 'TOME_3007') || contains(planeFolder, 'TOME_3014') || contains(planeFolder, 'TOME_3021') || contains(planeFolder, 'TOME_3022') || contains(planeFolder, 'TOME_3030') || contains(planeFolder, 'TOME_3044')  
            posteriorMRILeft = -posteriorMRILeft;   
        elseif contains(planeFolder, 'TOME_3024')     
            anteriorMRIRight = -anteriorMRIRight;  
        end

        anteriorMRIRight = -anteriorMRIRight;
    % If not use all fids
    elseif isequal(useAllFids,1)
        % Split the fcsv files to get the first 5 fidicuals for each canal
        lateralFidsLeft = cellfun(@(x)regexp(x,',','split'),splitlines(fileread(fullfile(planeFolder, 'fids_InnerEarAtlas_SSC_lat_left.fcsv'))),'UniformOutput',0);
        lateralFidsRight = cellfun(@(x)regexp(x,',','split'),splitlines(fileread(fullfile(planeFolder, 'fids_InnerEarAtlas_SSC_lat_right.fcsv'))),'UniformOutput',0);
        anteriorFidsLeft = cellfun(@(x)regexp(x,',','split'),splitlines(fileread(fullfile(planeFolder, 'fids_InnerEarAtlas_SSC_ant_left.fcsv'))),'UniformOutput',0);
        anteriorFidsRight = cellfun(@(x)regexp(x,',','split'),splitlines(fileread(fullfile(planeFolder, 'fids_InnerEarAtlas_SSC_ant_right.fcsv'))),'UniformOutput',0);
        posteriorFidsLeft = cellfun(@(x)regexp(x,',','split'),splitlines(fileread(fullfile(planeFolder, 'fids_InnerEarAtlas_SSC_post_left.fcsv'))),'UniformOutput',0);
        posteriorFidsRight = cellfun(@(x)regexp(x,',','split'),splitlines(fileread(fullfile(planeFolder, 'fids_InnerEarAtlas_SSC_post_right.fcsv'))),'UniformOutput',0);        
        
        % Do PCA
        lateralFidsLeft = pca(cell2mat(cellfun(@(x) [str2num(x{2}) str2num(x{3}) str2num(x{4})], lateralFidsLeft(4:end), 'UniformOutput', false)));
        lateralFidsRight = pca(cell2mat(cellfun(@(x) [str2num(x{2}) str2num(x{3}) str2num(x{4})], lateralFidsRight(4:end), 'UniformOutput', false)));
        anteriorFidsLeft = pca(cell2mat(cellfun(@(x) [str2num(x{2}) str2num(x{3}) str2num(x{4})], anteriorFidsLeft(4:end), 'UniformOutput', false)));
        anteriorFidsRight = pca(cell2mat(cellfun(@(x) [str2num(x{2}) str2num(x{3}) str2num(x{4})], anteriorFidsRight(4:end), 'UniformOutput', false)));
        posteriorFidsLeft = pca(cell2mat(cellfun(@(x) [str2num(x{2}) str2num(x{3}) str2num(x{4})], posteriorFidsLeft(4:end), 'UniformOutput', false)));
        posteriorFidsRight = pca(cell2mat(cellfun(@(x) [str2num(x{2}) str2num(x{3}) str2num(x{4})], posteriorFidsRight(4:end), 'UniformOutput', false)));
        
        % Get the 3rd eigenvector
        lateralMRILeft = lateralFidsLeft(:,3);
        lateralMRIRight = lateralFidsRight(:,3);
        anteriorMRILeft = anteriorFidsLeft(:,3);
        anteriorMRIRight = anteriorFidsRight(:,3);
        posteriorMRILeft = posteriorFidsLeft(:,3);
        posteriorMRIRight = posteriorFidsRight(:,3);
    end
    
%         %  Flip the signs of the rogue vectors 
%         if contains(planeFolder, 'TOME_3014') || contains(planeFolder, 'TOME_3021') || contains(planeFolder, 'TOME_3022') || contains(planeFolder, 'TOME_3044')  
%             posteriorMRILeft = -posteriorMRILeft;   
%         end
% 
%         anteriorMRIRight = -anteriorMRIRight; 
%         
        % Another way to flip signs which is more systmatic 
if sum(lateralMRILeft.*[0 0 1]') < 0
lateralMRILeft = -lateralMRILeft;
end
if sum(lateralMRIRight.*[0 0 1]') <0
lateralMRIRight = -lateralMRIRight;
end
if sum(anteriorMRILeft.*[1 0 0]') <0
anteriorMRILeft = -anteriorMRILeft;
end
if sum(anteriorMRIRight.*[-1 0 0]') <0
anteriorMRIRight = -anteriorMRIRight;
end
if sum(posteriorMRILeft.*[0 1 0]') <0
posteriorMRILeft = -posteriorMRILeft;
end
if sum(posteriorMRIRight.*[0 1 0]') <0
posteriorMRIRight = -posteriorMRIRight;
end
end
          