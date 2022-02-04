function allNormals = plotAllSubjects(downloadFolder)

% This function corrects the signs of subjects depending on the dataset
% and plots all normals together. Also, it calculates the relationships 
% between the SSC angles 

% Get folders directory and remove the first two paths as they contain "." 
% and ".."
folders = dir(downloadFolder);
folders(1:2) = [];
allNormals = {};

% Loop through subjects
for ii = 1:length(folders)
    
    % Load normals
    [lateralMRILeft, lateralMRIRight, anteriorMRILeft, anteriorMRIRight, ...
     posteriorMRILeft, posteriorMRIRight] = loadMRINormals(fullfile(folders(ii).folder,folders(ii).name), true);
    
%     % Here I manually change signs to make all normals point to the same 
%     % direction. Not RAS yet.
%     if contains(downloadFolder, 'tome')    
%         if strcmp(folders(ii).name, 'TOME_3007') || strcmp(folders(ii).name, 'TOME_3014') || strcmp(folders(ii).name, 'TOME_3021') || strcmp(folders(ii).name, 'TOME_3022') || strcmp(folders(ii).name, 'TOME_3030') || strcmp(folders(ii).name, 'TOME_3044')
%             posteriorMRILeft = -posteriorMRILeft;        
%         elseif strcmp(folders(ii).name, 'TOME_3024') 
%             anteriorMRIRight = -anteriorMRIRight;      
%         end     
%     end
%     elseif contains(downloadFolder, 'dataset-1')
%         if strcmp(folders(ii).name, 'sub-001')
%             anteriorMRILeft = -anteriorMRILeft;
%             posteriorMRIRight = -posteriorMRIRight;   
%         elseif strcmp(folders(ii).name, 'sub-002')   
%             posteriorMRILeft = -posteriorMRILeft;     
%         elseif strcmp(folders(ii).name, 'sub-003') || strcmp(folders(ii).name, 'sub-004') || strcmp(folders(ii).name, 'sub-008') || strcmp(folders(ii).name, 'sub-013') || strcmp(folders(ii).name, 'sub-017') || strcmp(folders(ii).name, 'sub-018') || strcmp(folders(ii).name, 'sub-023') || strcmp(folders(ii).name, 'sub-024')  
%             posteriorMRIRight = -posteriorMRIRight;            
%         elseif strcmp(folders(ii).name, 'sub-005')   
%             anteriorMRILeft = -anteriorMRILeft;   
%             anteriorMRIRight = -anteriorMRIRight;
%             posteriorMRIRight = -posteriorMRIRight;   
%         elseif strcmp(folders(ii).name, 'sub-009') 
%             posteriorMRILeft = -posteriorMRILeft; 
%             anteriorMRIRight = -anteriorMRIRight;
%             posteriorMRIRight = -posteriorMRIRight; 
%         elseif strcmp(folders(ii).name, 'sub-011') 
%             posteriorMRILeft = -posteriorMRILeft; 
%             posteriorMRIRight = -posteriorMRIRight;  
%         elseif strcmp(folders(ii).name, 'sub-014') || strcmp(folders(ii).name, 'sub-026')    
%             posteriorMRIRight = -posteriorMRIRight;
%             anteriorMRIRight = -anteriorMRIRight;      
%         end
%     elseif contains(downloadFolder, 'dataset-2')
%         if strcmp(folders(ii).name, 'sub-001') || strcmp(folders(ii).name, 'sub-006') || strcmp(folders(ii).name, 'sub-008') || strcmp(folders(ii).name, 'sub-010') || strcmp(folders(ii).name, 'sub-012') || strcmp(folders(ii).name, 'sub-014') || strcmp(folders(ii).name, 'sub-015') || strcmp(folders(ii).name, 'sub-017') || strcmp(folders(ii).name, 'sub-019') || strcmp(folders(ii).name, 'sub-021') || strcmp(folders(ii).name, 'sub-023') || strcmp(folders(ii).name, 'sub-024') || strcmp(folders(ii).name, 'sub-025') || strcmp(folders(ii).name, 'sub-026') || strcmp(folders(ii).name, 'sub-027') || strcmp(folders(ii).name, 'sub-035') || strcmp(folders(ii).name, 'sub-037') || strcmp(folders(ii).name, 'sub-038') || strcmp(folders(ii).name, 'sub-039') || strcmp(folders(ii).name, 'sub-043') || strcmp(folders(ii).name, 'sub-044') || strcmp(folders(ii).name, 'sub-049') || strcmp(folders(ii).name, 'sub-050') || strcmp(folders(ii).name, 'sub-054') || strcmp(folders(ii).name, 'sub-058') || strcmp(folders(ii).name, 'sub-059') || strcmp(folders(ii).name, 'sub-062') || strcmp(folders(ii).name, 'sub-066') || strcmp(folders(ii).name, 'sub-067') || strcmp(folders(ii).name, 'sub-069')
%             posteriorMRIRight = -posteriorMRIRight;   
%         elseif strcmp(folders(ii).name, 'sub-002')
%             posteriorMRIRight = -posteriorMRIRight;
%             anteriorMRILeft = -anteriorMRILeft;                 
%         elseif strcmp(folders(ii).name, 'sub-003') || strcmp(folders(ii).name, 'sub-013') || strcmp(folders(ii).name, 'sub-020') || strcmp(folders(ii).name, 'sub-022') || strcmp(folders(ii).name, 'sub-030') || strcmp(folders(ii).name, 'sub-042') || strcmp(folders(ii).name, 'sub-045') || strcmp(folders(ii).name, 'sub-047') || strcmp(folders(ii).name, 'sub-048') || strcmp(folders(ii).name, 'sub-056') || strcmp(folders(ii).name, 'sub-071')      
%             anteriorMRIRight = -anteriorMRIRight;
%             posteriorMRIRight = -posteriorMRIRight;  
%         elseif strcmp(folders(ii).name, 'sub-004') 
%             posteriorMRILeft = -posteriorMRILeft; 
%             posteriorMRIRight = -posteriorMRIRight;   
%         elseif strcmp(folders(ii).name, 'sub-007') || strcmp(folders(ii).name, 'sub-029') || strcmp(folders(ii).name, 'sub-055') || strcmp(folders(ii).name, 'sub-064')
%             posteriorMRILeft = -posteriorMRILeft; 
%             anteriorMRIRight = -anteriorMRIRight;
%             posteriorMRIRight = -posteriorMRIRight;    
%         elseif strcmp(folders(ii).name, 'sub-009') || strcmp(folders(ii).name, 'sub-031') || strcmp(folders(ii).name, 'sub-033') || strcmp(folders(ii).name, 'sub-034') || strcmp(folders(ii).name, 'sub-036') || strcmp(folders(ii).name, 'sub-046')
%             anteriorMRILeft = -anteriorMRILeft; 
%             anteriorMRIRight = -anteriorMRIRight;
%             posteriorMRIRight = -posteriorMRIRight;                
%         elseif strcmp(folders(ii).name, 'sub-018') || strcmp(folders(ii).name, 'sub-028')   
%             posteriorMRILeft = -posteriorMRILeft;       
%         elseif strcmp(folders(ii).name, 'sub-052') 
%             anteriorMRILeft = -anteriorMRILeft; 
%             posteriorMRIRight = -posteriorMRIRight;
%             posteriorMRILeft = -posteriorMRILeft;             
%         elseif strcmp(folders(ii).name, 'sub-053') || strcmp(folders(ii).name, 'sub-057') || strcmp(folders(ii).name, 'sub-060') || strcmp(folders(ii).name, 'sub-070')
%             posteriorMRILeft = -posteriorMRILeft; 
%             posteriorMRIRight = -posteriorMRIRight;              
%         elseif strcmp(folders(ii).name, 'sub-065')
%             posteriorMRILeft = -posteriorMRILeft; 
%             posteriorMRIRight = -posteriorMRIRight; 
%             anteriorMRIRight = -anteriorMRIRight; 
%         elseif strcmp(folders(ii).name, 'sub-032')   
%             anteriorMRIRight = -anteriorMRIRight;              
%         elseif strcmp(folders(ii).name, 'sub-068')    
%             posteriorMRILeft = -posteriorMRILeft; 
%             anteriorMRIRight = -anteriorMRIRight;    
%         end
%     end

    % Getting RAS here by changing the signs of all left anterior and 
    % right posterior. I added this part as changing the orientation above 
    % to make RAS would take a while
%     anteriorMRILeft = -anteriorMRILeft;
%     posteriorMRIRight = -posteriorMRIRight;
%     anteriorMRIRight = -anteriorMRIRight;
    
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