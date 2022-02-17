% Set the model
anteriorLeft = [1 0 0];
anteriorRight = [-1 0 0];
posteriorLeft = [0 1 0];
posteriorRight = [0 1 0];
lateralLeft = [0 0 1];
lateralRight = [0 0 1];

folders = dir('C:\Users\ozenc\Desktop\ForOzzy\ForOzzy\tome');
folders(1:2) = [];
allNormals = {};

subjectNum = 0;
avg = zeros(3,6);
avgAfter = zeros(3,6);
% Loop through subjects
for ii = 1:length(folders)
    
    % Load normals
    [lateralMRILeft, lateralMRIRight, anteriorMRILeft, anteriorMRIRight, ...
     posteriorMRILeft, posteriorMRIRight] = loadMRINormals(fullfile(folders(ii).folder,folders(ii).name));
    
    Sub = [lateralMRILeft, lateralMRIRight, anteriorMRILeft, anteriorMRIRight, posteriorMRILeft, posteriorMRIRight];
    Temp = [lateralLeft', lateralRight', anteriorLeft', anteriorRight', posteriorLeft', posteriorRight'];

    % Add to avg 
    avg = avg + Sub;
    subjectNum = subjectNum + 1;
    
    % Calculate centroids 
    centroidSub = mean(Sub,2);
    centroidTemp = mean(Temp,2);

    % Calculate familiar covariance 
    H = (Temp - centroidTemp)*(Sub - centroidSub)';

    % SVD to find the rotation 
    [U,S,V] = svd(H);
    x.R = inv(V*U');

    % Rotate the subject matrix
    lateralMRILeftNew = x.R*lateralMRILeft;
    lateralMRIRightNew = x.R*lateralMRIRight;
    anteriorMRILeftNew = x.R*anteriorMRILeft;
    anteriorMRIRightNew = x.R*anteriorMRIRight;
    posteriorMRILeftNew = x.R*posteriorMRILeft;
    posteriorMRIRightNew = x.R*posteriorMRIRight;    
    
    subNew = [lateralMRILeftNew, lateralMRIRightNew, ...
              anteriorMRILeftNew, anteriorMRIRightNew, ...
              posteriorMRILeftNew, posteriorMRIRightNew];
    avgAfter = avgAfter + subNew;
          
    plotMRINormals(lateralMRILeftNew, lateralMRIRightNew, ...
                        anteriorMRILeftNew, anteriorMRIRightNew, ...
                        posteriorMRILeftNew, posteriorMRIRightNew, false, false)
    hold on
end
    
SubAvg = avg / subjectNum;
SubAfterAvg = avgAfter / subjectNum;
plotMRINormals(SubAvg(:,1), SubAvg(:,2), ...
               SubAvg(:,3), SubAvg(:,4), ...
               SubAvg(:,5), SubAvg(:,6), true, false)
hold on
plotMRINormals(SubAfterAvg(:,1), SubAfterAvg(:,2), ...
               SubAfterAvg(:,3), SubAfterAvg(:,4), ...
               SubAfterAvg(:,5), SubAfterAvg(:,6), false, true)  
         