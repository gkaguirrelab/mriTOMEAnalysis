function allNormals = plotAllSubjects(downloadFolder)

% This function plots all TOME ear normals together on a single plot. 
%     Inputs:
%         downloadFolder - The saveLoc variable you specified for the
%         downloadSubjectNormals.m function.
%     Outputs:
%         allNormals - all normal vectors saved in a cell. Rows are
%         subjects and 6 columns are the ear canals. The order goes lateral
%         left/right, anterior left/right, posterior left/right

% Get folders directory and remove the first two paths as they contain "." 
% and ".."
folders = dir(downloadFolder);
folders(1:2) = [];
allNormals = {};

% Loop through subjects
for ii = 1:length(folders)
    
    % Load normals
    [lateralMRILeft, lateralMRIRight, anteriorMRILeft, anteriorMRIRight, ...
     posteriorMRILeft, posteriorMRIRight] = loadMRINormals(fullfile(folders(ii).folder,folders(ii).name), false);
    
    % Save normals from all subjects to a separate cell
    allNormals{ii,1} = lateralMRILeft;
    allNormals{ii,2} = lateralMRIRight;
    allNormals{ii,3} = anteriorMRILeft;
    allNormals{ii,4} = anteriorMRIRight;
    allNormals{ii,5} = posteriorMRILeft;
    allNormals{ii,6} = posteriorMRIRight;    
    
    % Plot the subject and hold on
    plotMRINormals(lateralMRILeft, lateralMRIRight, anteriorMRILeft, anteriorMRIRight, ...
                   posteriorMRILeft, posteriorMRIRight, false, false)
    hold on
end
title('Normals from all subjects')
hold off 

% Create empty structs for angle relationships
anteriorToLateralLeft = [];
lateralToPosteriorLeft = [];
anteriorToPosteriorLeft = [];
anteriorToLateralRight = [];
lateralToPosteriorRight = [];
anteriorToPosteriorRight = [];

% Loop through each subject and calculate the angle relationships. Put them
% into their respective structs
for ii = 1:length(allNormals)
    anteriorToLateralLeft(ii,1) = rad2deg(atan2(norm(cross(allNormals{ii,3},allNormals{ii,1})), dot(allNormals{ii,3},allNormals{ii,1})));
    lateralToPosteriorLeft(ii,1) = rad2deg(atan2(norm(cross(allNormals{ii,1},allNormals{ii,5})), dot(allNormals{ii,1},allNormals{ii,5})));
    anteriorToPosteriorLeft(ii,1) = rad2deg(atan2(norm(cross(allNormals{ii,3},allNormals{ii,5})), dot(allNormals{ii,3},allNormals{ii,5})));
    
    anteriorToLateralRight(ii,1) = rad2deg(atan2(norm(cross(allNormals{ii,4},allNormals{ii,2})), dot(allNormals{ii,4},allNormals{ii,2})));
    lateralToPosteriorRight(ii,1) = rad2deg(atan2(norm(cross(allNormals{ii,2},allNormals{ii,6})), dot(allNormals{ii,2},allNormals{ii,6})));
    anteriorToPosteriorRight(ii,1) = rad2deg(atan2(norm(cross(allNormals{ii,4},allNormals{ii,6})), dot(allNormals{ii,4},allNormals{ii,6})));    
end 

% Report the mean and std angle relationships. Bootstrap mean and std
fprintf('Left side\n')
fprintf(['Anterior to lateral ' num2str(mean(anteriorToLateralLeft)) ' SD: ' num2str(std(anteriorToLateralLeft)) '\n'])
fprintf(['Lateral to posterior ' num2str(mean(lateralToPosteriorLeft)) ' SD: ' num2str(std(lateralToPosteriorLeft)) '\n'])
fprintf(['Anterior to posterior ' num2str(mean(anteriorToPosteriorLeft)) ' SD: ' num2str(std(anteriorToPosteriorLeft)) '\n\n'])

fprintf('Right side\n')
fprintf(['Anterior to lateral ' num2str(mean(anteriorToLateralRight)) ' SD: ' num2str(std(anteriorToLateralRight)) '\n'])
fprintf(['Lateral to posterior ' num2str(mean(lateralToPosteriorRight)) ' SD: ' num2str(std(lateralToPosteriorRight)) '\n'])
fprintf(['Anterior to posterior ' num2str(mean(anteriorToPosteriorRight)) ' SD: ' num2str(std(anteriorToPosteriorRight)) '\n'])        
              
end