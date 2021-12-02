function allNormals = plotAllSubjects(downloadFolder)

folders = dir(downloadFolder);
folders(1) = [];
folders(1) = [];
allNormals = {};
for ii = 1:length(folders)
    [lateralMRILeft, lateralMRIRight, anteriorMRILeft, anteriorMRIRight, ...
     posteriorMRILeft, posteriorMRIRight] = loadMRINormals(fullfile(folders(ii).folder,folders(ii).name));
 
    if strcmp(folders(ii).name, 'TOME_3001')
        anteriorMRILeft.normal = -anteriorMRILeft.normal;
        posteriorMRIRight.normal = -posteriorMRIRight.normal;
    elseif strcmp(folders(ii).name, 'TOME_3002')
        posteriorMRIRight.normal = -posteriorMRIRight.normal;
    elseif strcmp(folders(ii).name, 'TOME_3003')    
        posteriorMRIRight.normal = -posteriorMRIRight.normal;    
    elseif strcmp(folders(ii).name, 'TOME_3004')    
        anteriorMRIRight.normal = -anteriorMRIRight.normal;
        posteriorMRIRight.normal = -posteriorMRIRight.normal;
    elseif strcmp(folders(ii).name, 'TOME_3005')    
        posteriorMRIRight.normal = -posteriorMRIRight.normal;
    elseif strcmp(folders(ii).name, 'TOME_3007')    
        posteriorMRIRight.normal = -posteriorMRIRight.normal;
    elseif strcmp(folders(ii).name, 'TOME_3008')    
        anteriorMRILeft.normal = -anteriorMRILeft.normal;    
        posteriorMRIRight.normal = -posteriorMRIRight.normal;
    elseif strcmp(folders(ii).name, 'TOME_3009') 
        posteriorMRILeft.normal = -posteriorMRILeft.normal;    
        anteriorMRIRight.normal = -anteriorMRIRight.normal;
        posteriorMRIRight.normal = -posteriorMRIRight.normal;
    elseif strcmp(folders(ii).name, 'TOME_3011') 
        anteriorMRILeft.normal = -anteriorMRILeft.normal;   
        posteriorMRIRight.normal = -posteriorMRIRight.normal;    
    elseif strcmp(folders(ii).name, 'TOME_3012') 
        posteriorMRIRight.normal = -posteriorMRIRight.normal;   
    elseif strcmp(folders(ii).name, 'TOME_3013') 
        anteriorMRILeft.normal = -anteriorMRILeft.normal;  
        anteriorMRIRight.normal = -anteriorMRIRight.normal;   
        posteriorMRIRight.normal = -posteriorMRIRight.normal;        
    elseif strcmp(folders(ii).name, 'TOME_3014') 
        posteriorMRILeft.normal = -posteriorMRILeft.normal;           
        posteriorMRIRight.normal = -posteriorMRIRight.normal;
    elseif strcmp(folders(ii).name, 'TOME_3015')  
        posteriorMRIRight.normal = -posteriorMRIRight.normal;
    elseif strcmp(folders(ii).name, 'TOME_3017')  
        posteriorMRILeft.normal = -posteriorMRILeft.normal;    
        anteriorMRIRight.normal = -anteriorMRIRight.normal;    
        posteriorMRIRight.normal = -posteriorMRIRight.normal;   
    elseif strcmp(folders(ii).name, 'TOME_3018') 
        posteriorMRIRight.normal = -posteriorMRIRight.normal;     
    elseif strcmp(folders(ii).name, 'TOME_3019') 
        anteriorMRILeft.normal = -anteriorMRILeft.normal;    
        posteriorMRIRight.normal = -posteriorMRIRight.normal;  
    elseif strcmp(folders(ii).name, 'TOME_3020')   
        posteriorMRIRight.normal = -posteriorMRIRight.normal;     
    elseif strcmp(folders(ii).name, 'TOME_3022')  
        posteriorMRIRight.normal = -posteriorMRIRight.normal;   
    elseif strcmp(folders(ii).name, 'TOME_3024')  
        anteriorMRIRight.normal = -anteriorMRIRight.normal;    
    elseif strcmp(folders(ii).name, 'TOME_3025')    
        anteriorMRIRight.normal = -anteriorMRIRight.normal; 
        posteriorMRIRight.normal = -posteriorMRIRight.normal;        
    elseif strcmp(folders(ii).name, 'TOME_3026') 
        posteriorMRILeft.normal = -posteriorMRILeft.normal;     
        posteriorMRIRight.normal = -posteriorMRIRight.normal;    
    elseif strcmp(folders(ii).name, 'TOME_3027')  
        anteriorMRILeft.normal = -anteriorMRILeft.normal;          
        posteriorMRILeft.normal = -posteriorMRILeft.normal;     
        posteriorMRIRight.normal = -posteriorMRIRight.normal;   
    elseif strcmp(folders(ii).name, 'TOME_3028')  
        anteriorMRILeft.normal = -anteriorMRILeft.normal;  
        anteriorMRIRight.normal = -anteriorMRIRight.normal;
        posteriorMRIRight.normal = -posteriorMRIRight.normal;   
    elseif strcmp(folders(ii).name, 'TOME_3029') 
        posteriorMRIRight.normal = -posteriorMRIRight.normal;  
    elseif strcmp(folders(ii).name, 'TOME_3030') 
        posteriorMRILeft.normal = -posteriorMRILeft.normal;
        anteriorMRIRight.normal = -anteriorMRIRight.normal;
    elseif strcmp(folders(ii).name, 'TOME_3031')    
        posteriorMRIRight.normal = -posteriorMRIRight.normal; 
    elseif strcmp(folders(ii).name, 'TOME_3032') 
        posteriorMRIRight.normal = -posteriorMRIRight.normal;   
    elseif strcmp(folders(ii).name, 'TOME_3033')
        anteriorMRILeft.normal = -anteriorMRILeft.normal;       
        anteriorMRIRight.normal = -anteriorMRIRight.normal;  
        posteriorMRIRight.normal = -posteriorMRIRight.normal;     
    elseif strcmp(folders(ii).name, 'TOME_3034')   
        posteriorMRIRight.normal = -posteriorMRIRight.normal;     
    elseif strcmp(folders(ii).name, 'TOME_3035') 
        anteriorMRILeft.normal = -anteriorMRILeft.normal;  
        anteriorMRIRight.normal = -anteriorMRIRight.normal;         
        posteriorMRIRight.normal = -posteriorMRIRight.normal;   
    elseif strcmp(folders(ii).name, 'TOME_3036')  
        anteriorMRIRight.normal = -anteriorMRIRight.normal;  
        posteriorMRIRight.normal = -posteriorMRIRight.normal;   
    elseif strcmp(folders(ii).name, 'TOME_3037')    
        anteriorMRILeft.normal = -anteriorMRILeft.normal;   
        posteriorMRIRight.normal = -posteriorMRIRight.normal;      
    elseif strcmp(folders(ii).name, 'TOME_3039')  
        posteriorMRILeft.normal = -posteriorMRILeft.normal;  
        posteriorMRIRight.normal = -posteriorMRIRight.normal;            
    elseif strcmp(folders(ii).name, 'TOME_3040')  
        anteriorMRILeft.normal = -anteriorMRILeft.normal;   
        anteriorMRIRight.normal = -anteriorMRIRight.normal;    
        posteriorMRIRight.normal = -posteriorMRIRight.normal;    
    elseif strcmp(folders(ii).name, 'TOME_3042')    
        anteriorMRILeft.normal = -anteriorMRILeft.normal; 
        posteriorMRIRight.normal = -posteriorMRIRight.normal;  
    elseif strcmp(folders(ii).name, 'TOME_3043')    
        anteriorMRILeft.normal = -anteriorMRILeft.normal;   
        posteriorMRILeft.normal = -posteriorMRILeft.normal;         
        anteriorMRIRight.normal = -anteriorMRIRight.normal;
        posteriorMRIRight.normal = -posteriorMRIRight.normal;        
    elseif strcmp(folders(ii).name, 'TOME_3044')   
        posteriorMRILeft.normal = -posteriorMRILeft.normal; 
        posteriorMRIRight.normal = -posteriorMRIRight.normal; 
    elseif strcmp(folders(ii).name, 'TOME_3045')  
        posteriorMRIRight.normal = -posteriorMRIRight.normal;        
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

averageLateralLeft.normal = averageLateralLeft.normal/43;
averageLateralRight.normal = averageLateralRight.normal/43;
averageAnteriorLeft.normal = averageAnteriorLeft.normal/43;
averageAnteriorRight.normal = averageAnteriorRight.normal/43;
averagePosteriorLeft.normal = averagePosteriorLeft.normal/43;
averagePosteriorRight.normal = averagePosteriorRight.normal/43;

calcAP = rad2deg(atan2(norm(cross(averageAnteriorLeft.normal,averagePosteriorLeft.normal)), dot(averageAnteriorLeft.normal,averagePosteriorLeft.normal)));
calcAL = rad2deg(atan2(norm(cross(averageAnteriorLeft.normal,averageLateralLeft.normal)), dot(averageAnteriorLeft.normal,averageLateralLeft.normal)));
calcPL = rad2deg(atan2(norm(cross(averagePosteriorLeft.normal,averageLateralLeft.normal)), dot(averagePosteriorLeft.normal,averageLateralLeft.normal)));
fprintf(['Calculated angle between Anterior and Posterior Left ear is ' num2str(calcAP) '\n'])
fprintf(['Calculated angle between Anterior and Lateral Left ear is ' num2str(calcAL) '\n'])
fprintf(['Calculated angle between Posterior and Lateral Left ear is ' num2str(calcPL) '\n'])

calcAP = rad2deg(atan2(norm(cross(averageAnteriorRight.normal,averagePosteriorRight.normal)), dot(averageAnteriorRight.normal,averagePosteriorRight.normal)));
calcAL = rad2deg(atan2(norm(cross(averageAnteriorRight.normal,averageLateralRight.normal)), dot(averageAnteriorRight.normal,averageLateralRight.normal)));
calcPL = rad2deg(atan2(norm(cross(averagePosteriorRight.normal,averageLateralRight.normal)), dot(averagePosteriorRight.normal,averageLateralRight.normal)));
fprintf(['Calculated angle between Anterior and Posterior Right ear is ' num2str(calcAP) '\n'])
fprintf(['Calculated angle between Anterior and Lateral Right ear is ' num2str(calcAL) '\n'])
fprintf(['Calculated angle between Posterior and Lateral Right ear is ' num2str(calcPL) '\n'])

figure
plotMRINormals(averageLateralLeft, averageLateralRight, ...
               averageAnteriorLeft, averageAnteriorRight, ...
               averagePosteriorLeft, averagePosteriorRight)
end