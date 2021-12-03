function [allNormals, averageNormals] = plotAllSubjects(downloadFolder)

folders = dir(downloadFolder);
folders(1) = [];
folders(1) = [];
allNormals = {};
for ii = 1:length(folders)
    [lateralMRILeft, lateralMRIRight, anteriorMRILeft, anteriorMRIRight, ...
     posteriorMRILeft, posteriorMRIRight] = loadMRINormals(fullfile(folders(ii).folder,folders(ii).name));

    if contains(downloadFolder, 'tome')    
        if strcmp(folders(ii).name, 'TOME_3001') || strcmp(folders(ii).name, 'TOME_3008') || strcmp(folders(ii).name, 'TOME_3011') || strcmp(folders(ii).name, 'TOME_3019') || strcmp(folders(ii).name, 'TOME_3037') || strcmp(folders(ii).name, 'TOME_3042')
            anteriorMRILeft.normal = -anteriorMRILeft.normal;
            posteriorMRIRight.normal = -posteriorMRIRight.normal;        
        elseif strcmp(folders(ii).name, 'TOME_3002') || strcmp(folders(ii).name, 'TOME_3003') || strcmp(folders(ii).name, 'TOME_3005') || strcmp(folders(ii).name, 'TOME_3007') || strcmp(folders(ii).name, 'TOME_3012') || strcmp(folders(ii).name, 'TOME_3015') || strcmp(folders(ii).name, 'TOME_3018') || strcmp(folders(ii).name, 'TOME_3020') || strcmp(folders(ii).name, 'TOME_3022') || strcmp(folders(ii).name, 'TOME_3029') || strcmp(folders(ii).name, 'TOME_3031') || strcmp(folders(ii).name, 'TOME_3032') || strcmp(folders(ii).name, 'TOME_3034') || strcmp(folders(ii).name, 'TOME_3045') 
            posteriorMRIRight.normal = -posteriorMRIRight.normal;
        elseif strcmp(folders(ii).name, 'TOME_3004') || strcmp(folders(ii).name, 'TOME_3025') || strcmp(folders(ii).name, 'TOME_3036')     
            anteriorMRIRight.normal = -anteriorMRIRight.normal;
            posteriorMRIRight.normal = -posteriorMRIRight.normal;
        elseif strcmp(folders(ii).name, 'TOME_3009') || strcmp(folders(ii).name, 'TOME_3017')
            posteriorMRILeft.normal = -posteriorMRILeft.normal;    
            anteriorMRIRight.normal = -anteriorMRIRight.normal;
            posteriorMRIRight.normal = -posteriorMRIRight.normal; 
        elseif strcmp(folders(ii).name, 'TOME_3013') || strcmp(folders(ii).name, 'TOME_3028') || strcmp(folders(ii).name, 'TOME_3033') || strcmp(folders(ii).name, 'TOME_3035') || strcmp(folders(ii).name, 'TOME_3040') 
            anteriorMRILeft.normal = -anteriorMRILeft.normal;  
            anteriorMRIRight.normal = -anteriorMRIRight.normal;   
            posteriorMRIRight.normal = -posteriorMRIRight.normal;         
        elseif strcmp(folders(ii).name, 'TOME_3014') || strcmp(folders(ii).name, 'TOME_3026') || strcmp(folders(ii).name, 'TOME_3039') || strcmp(folders(ii).name, 'TOME_3044')
            posteriorMRILeft.normal = -posteriorMRILeft.normal;           
            posteriorMRIRight.normal = -posteriorMRIRight.normal;    
        elseif strcmp(folders(ii).name, 'TOME_3024')  
            anteriorMRIRight.normal = -anteriorMRIRight.normal;  
        elseif strcmp(folders(ii).name, 'TOME_3027')  
            anteriorMRILeft.normal = -anteriorMRILeft.normal;          
            posteriorMRILeft.normal = -posteriorMRILeft.normal;     
            posteriorMRIRight.normal = -posteriorMRIRight.normal;     
        elseif strcmp(folders(ii).name, 'TOME_3030') 
            posteriorMRILeft.normal = -posteriorMRILeft.normal;
            anteriorMRIRight.normal = -anteriorMRIRight.normal;                       
        elseif strcmp(folders(ii).name, 'TOME_3043')    
            anteriorMRILeft.normal = -anteriorMRILeft.normal;   
            posteriorMRILeft.normal = -posteriorMRILeft.normal;         
            anteriorMRIRight.normal = -anteriorMRIRight.normal;
            posteriorMRIRight.normal = -posteriorMRIRight.normal;            
        end       
    elseif contains(downloadFolder, 'dataset-1')
        if strcmp(folders(ii).name, 'sub-001')
            anteriorMRILeft.normal = -anteriorMRILeft.normal;
            posteriorMRIRight.normal = -posteriorMRIRight.normal;   
        elseif strcmp(folders(ii).name, 'sub-002')   
            posteriorMRILeft.normal = -posteriorMRILeft.normal;     
        elseif strcmp(folders(ii).name, 'sub-003') || strcmp(folders(ii).name, 'sub-004') || strcmp(folders(ii).name, 'sub-008') || strcmp(folders(ii).name, 'sub-013') || strcmp(folders(ii).name, 'sub-017') || strcmp(folders(ii).name, 'sub-018') || strcmp(folders(ii).name, 'sub-023') || strcmp(folders(ii).name, 'sub-024')  
            posteriorMRIRight.normal = -posteriorMRIRight.normal;            
        elseif strcmp(folders(ii).name, 'sub-005')   
            anteriorMRILeft.normal = -anteriorMRILeft.normal;   
            anteriorMRIRight.normal = -anteriorMRIRight.normal;
            posteriorMRIRight.normal = -posteriorMRIRight.normal;   
        elseif strcmp(folders(ii).name, 'sub-009') 
            posteriorMRILeft.normal = -posteriorMRILeft.normal; 
            anteriorMRIRight.normal = -anteriorMRIRight.normal;
            posteriorMRIRight.normal = -posteriorMRIRight.normal; 
        elseif strcmp(folders(ii).name, 'sub-011') 
            posteriorMRILeft.normal = -posteriorMRILeft.normal; 
            posteriorMRIRight.normal = -posteriorMRIRight.normal;  
        elseif strcmp(folders(ii).name, 'sub-014') || strcmp(folders(ii).name, 'sub-026')    
            posteriorMRIRight.normal = -posteriorMRIRight.normal;
            anteriorMRIRight.normal = -anteriorMRIRight.normal;      
        end
    elseif contains(downloadFolder, 'dataset-2')
        if strcmp(folders(ii).name, 'sub-001') || strcmp(folders(ii).name, 'sub-006') || strcmp(folders(ii).name, 'sub-008') || strcmp(folders(ii).name, 'sub-010') || strcmp(folders(ii).name, 'sub-012') || strcmp(folders(ii).name, 'sub-014') || strcmp(folders(ii).name, 'sub-015') || strcmp(folders(ii).name, 'sub-017') || strcmp(folders(ii).name, 'sub-019') || strcmp(folders(ii).name, 'sub-021') || strcmp(folders(ii).name, 'sub-023') || strcmp(folders(ii).name, 'sub-024') || strcmp(folders(ii).name, 'sub-025') || strcmp(folders(ii).name, 'sub-026') || strcmp(folders(ii).name, 'sub-027') || strcmp(folders(ii).name, 'sub-035') || strcmp(folders(ii).name, 'sub-037') || strcmp(folders(ii).name, 'sub-038') || strcmp(folders(ii).name, 'sub-039') || strcmp(folders(ii).name, 'sub-043') || strcmp(folders(ii).name, 'sub-044') || strcmp(folders(ii).name, 'sub-049') || strcmp(folders(ii).name, 'sub-050') || strcmp(folders(ii).name, 'sub-054') || strcmp(folders(ii).name, 'sub-058') || strcmp(folders(ii).name, 'sub-059') || strcmp(folders(ii).name, 'sub-062') || strcmp(folders(ii).name, 'sub-066') || strcmp(folders(ii).name, 'sub-067') || strcmp(folders(ii).name, 'sub-069')
            posteriorMRIRight.normal = -posteriorMRIRight.normal;   
        elseif strcmp(folders(ii).name, 'sub-002')
            posteriorMRIRight.normal = -posteriorMRIRight.normal;
            anteriorMRILeft.normal = -anteriorMRILeft.normal;                 
        elseif strcmp(folders(ii).name, 'sub-003') || strcmp(folders(ii).name, 'sub-013') || strcmp(folders(ii).name, 'sub-020') || strcmp(folders(ii).name, 'sub-022') || strcmp(folders(ii).name, 'sub-030') || strcmp(folders(ii).name, 'sub-042') || strcmp(folders(ii).name, 'sub-045') || strcmp(folders(ii).name, 'sub-047') || strcmp(folders(ii).name, 'sub-048') || strcmp(folders(ii).name, 'sub-056') || strcmp(folders(ii).name, 'sub-071')      
            anteriorMRIRight.normal = -anteriorMRIRight.normal;
            posteriorMRIRight.normal = -posteriorMRIRight.normal;  
        elseif strcmp(folders(ii).name, 'sub-004') 
            posteriorMRILeft.normal = -posteriorMRILeft.normal; 
            posteriorMRIRight.normal = -posteriorMRIRight.normal;   
        elseif strcmp(folders(ii).name, 'sub-007') || strcmp(folders(ii).name, 'sub-029') || strcmp(folders(ii).name, 'sub-055') || strcmp(folders(ii).name, 'sub-064')
            posteriorMRILeft.normal = -posteriorMRILeft.normal; 
            anteriorMRIRight.normal = -anteriorMRIRight.normal;
            posteriorMRIRight.normal = -posteriorMRIRight.normal;    
        elseif strcmp(folders(ii).name, 'sub-009') || strcmp(folders(ii).name, 'sub-031') || strcmp(folders(ii).name, 'sub-033') || strcmp(folders(ii).name, 'sub-034') || strcmp(folders(ii).name, 'sub-036') || strcmp(folders(ii).name, 'sub-046')
            anteriorMRILeft.normal = -anteriorMRILeft.normal; 
            anteriorMRIRight.normal = -anteriorMRIRight.normal;
            posteriorMRIRight.normal = -posteriorMRIRight.normal;                
        elseif strcmp(folders(ii).name, 'sub-018') || strcmp(folders(ii).name, 'sub-028')   
            posteriorMRILeft.normal = -posteriorMRILeft.normal;       
        elseif strcmp(folders(ii).name, 'sub-052') 
            anteriorMRILeft.normal = -anteriorMRILeft.normal; 
            posteriorMRIRight.normal = -posteriorMRIRight.normal;
            posteriorMRILeft.normal = -posteriorMRILeft.normal;             
        elseif strcmp(folders(ii).name, 'sub-053') || strcmp(folders(ii).name, 'sub-057') || strcmp(folders(ii).name, 'sub-060') || strcmp(folders(ii).name, 'sub-070')
            posteriorMRILeft.normal = -posteriorMRILeft.normal; 
            posteriorMRIRight.normal = -posteriorMRIRight.normal;              
        elseif strcmp(folders(ii).name, 'sub-065')
            posteriorMRILeft.normal = -posteriorMRILeft.normal; 
            posteriorMRIRight.normal = -posteriorMRIRight.normal; 
            anteriorMRIRight.normal = -anteriorMRIRight.normal; 
        elseif strcmp(folders(ii).name, 'sub-032')   
            anteriorMRIRight.normal = -anteriorMRIRight.normal;              
        elseif strcmp(folders(ii).name, 'sub-068')    
            posteriorMRILeft.normal = -posteriorMRILeft.normal; 
            anteriorMRIRight.normal = -anteriorMRIRight.normal;    
        end
    end

    allNormals{ii,1} = lateralMRILeft;
    allNormals{ii,2} = lateralMRIRight;
    allNormals{ii,3} = anteriorMRILeft;
    allNormals{ii,4} = anteriorMRIRight;
    allNormals{ii,5} = posteriorMRILeft;
    allNormals{ii,6} = posteriorMRIRight;    

    plotMRINormals(lateralMRILeft, lateralMRIRight, anteriorMRILeft, anteriorMRIRight, ...
                   posteriorMRILeft, posteriorMRIRight)
    hold on
end
hold off 

averageLateralLeft.normal = [0 0 0];
averageLateralRight.normal = [0 0 0];
averageAnteriorLeft.normal = [0 0 0];
averageAnteriorRight.normal = [0 0 0];
averagePosteriorLeft.normal = [0 0 0];
averagePosteriorRight.normal = [0 0 0];
for nn = 1:length(allNormals)
    averageLateralLeft.normal = averageLateralLeft.normal + allNormals{nn,1}.normal;
    averageLateralRight.normal = averageLateralRight.normal + allNormals{nn,2}.normal;
    averageAnteriorLeft.normal = averageAnteriorLeft.normal + allNormals{nn,3}.normal;
    averageAnteriorRight.normal = averageAnteriorRight.normal + allNormals{nn,4}.normal;
    averagePosteriorLeft.normal = averagePosteriorLeft.normal + allNormals{nn,5}.normal;
    averagePosteriorRight.normal = averagePosteriorRight.normal + allNormals{nn,6}.normal;
end

if contains(downloadFolder, 'tome')
    averageLateralLeft.normal = averageLateralLeft.normal/43;
    averageLateralRight.normal = averageLateralRight.normal/43;
    averageAnteriorLeft.normal = averageAnteriorLeft.normal/43;
    averageAnteriorRight.normal = averageAnteriorRight.normal/43;
    averagePosteriorLeft.normal = averagePosteriorLeft.normal/43;
    averagePosteriorRight.normal = averagePosteriorRight.normal/43;
elseif contains(downloadFolder, 'dataset-1')
    averageLateralLeft.normal = averageLateralLeft.normal/16;
    averageLateralRight.normal = averageLateralRight.normal/16;
    averageAnteriorLeft.normal = averageAnteriorLeft.normal/16;
    averageAnteriorRight.normal = averageAnteriorRight.normal/16;
    averagePosteriorLeft.normal = averagePosteriorLeft.normal/16;
    averagePosteriorRight.normal = averagePosteriorRight.normal/16;
elseif contains(downloadFolder, 'dataset-2')
    averageLateralLeft.normal = averageLateralLeft.normal/70;
    averageLateralRight.normal = averageLateralRight.normal/70;
    averageAnteriorLeft.normal = averageAnteriorLeft.normal/70;
    averageAnteriorRight.normal = averageAnteriorRight.normal/70;
    averagePosteriorLeft.normal = averagePosteriorLeft.normal/70;
    averagePosteriorRight.normal = averagePosteriorRight.normal/70;
end    
    
calcAP = rad2deg(atan2(norm(cross(averageAnteriorLeft.normal,averagePosteriorLeft.normal)), dot(averageAnteriorLeft.normal,averagePosteriorLeft.normal)));
calcAL = rad2deg(atan2(norm(cross(averageAnteriorLeft.normal,averageLateralLeft.normal)), dot(averageAnteriorLeft.normal,averageLateralLeft.normal)));
calcPL = rad2deg(atan2(norm(cross(averagePosteriorLeft.normal,averageLateralLeft.normal)), dot(averagePosteriorLeft.normal,averageLateralLeft.normal)));
fprintf(['Calculated angle between Anterior and Posterior Left ear is ' num2str(calcAP) '\n'])
fprintf(['Calculated angle between Anterior and Lateral Left ear is ' num2str(calcAL) '\n'])
fprintf(['Calculated angle between Posterior and Lateral Left ear is ' num2str(calcPL) '\n\n'])

calcAP = rad2deg(atan2(norm(cross(averageAnteriorRight.normal,averagePosteriorRight.normal)), dot(averageAnteriorRight.normal,averagePosteriorRight.normal)));
calcAL = rad2deg(atan2(norm(cross(averageAnteriorRight.normal,averageLateralRight.normal)), dot(averageAnteriorRight.normal,averageLateralRight.normal)));
calcPL = rad2deg(atan2(norm(cross(averagePosteriorRight.normal,averageLateralRight.normal)), dot(averagePosteriorRight.normal,averageLateralRight.normal)));
fprintf(['Calculated angle between Anterior and Posterior Right ear is ' num2str(calcAP) '\n'])
fprintf(['Calculated angle between Anterior and Lateral Right ear is ' num2str(calcAL) '\n'])
fprintf(['Calculated angle between Posterior and Lateral Right ear is ' num2str(calcPL) '\n\n'])

calcAP = rad2deg(atan2(norm(cross(averageAnteriorRight.normal,averageAnteriorLeft.normal)), dot(averageAnteriorRight.normal,averageAnteriorLeft.normal)));
calcAL = rad2deg(atan2(norm(cross(averageLateralRight.normal,averageLateralLeft.normal)), dot(averageLateralRight.normal,averageLateralLeft.normal)));
calcPL = rad2deg(atan2(norm(cross(averagePosteriorRight.normal,averagePosteriorLeft.normal)), dot(averagePosteriorRight.normal,averagePosteriorLeft.normal)));
fprintf(['Calculated angle between Anterior left-right ear is ' num2str(calcAP) '\n'])
fprintf(['Calculated angle between Lateral left-right ear is ' num2str(calcAL) '\n'])
fprintf(['Calculated angle between Posterior left-right ear is ' num2str(calcPL) '\n\n'])

figure
plotMRINormals(averageLateralLeft, averageLateralRight, ...
               averageAnteriorLeft, averageAnteriorRight, ...
               averagePosteriorLeft, averagePosteriorRight)
averageNormals = [averageLateralLeft, averageLateralRight, ...
                  averageAnteriorLeft, averageAnteriorRight, ...
                  averagePosteriorLeft, averagePosteriorRight];
end