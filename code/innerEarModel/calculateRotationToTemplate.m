function rotationMatrix = calculateRotationToTemplate(subjectNormalFolder, templateNormalFolder)

% Load template normals
[lateralMRILeftTemplate, lateralMRIRightTemplate, ...
 anteriorMRILeftTemplate, anteriorMRIRightTemplate, ...
 posteriorMRILeftTemplate, posteriorMRIRightTemplate] = loadMRINormals(templateNormalFolder);

% Load subject normals
[lateralMRILeftSubject, lateralMRIRightSubject, ...
 anteriorMRILeftSubject, anteriorMRIRightSubject, ...
 posteriorMRILeftSubject, posteriorMRIRightSubject] = loadMRINormals(subjectNormalFolder); 

% Concatanate subject and template normal points into a struct
Sub = [lateralMRILeftSubject', anteriorMRILeftSubject', posteriorMRILeftSubject', lateralMRIRightSubject', anteriorMRIRightSubject', posteriorMRIRightSubject'];
Temp = [lateralMRILeftTemplate', anteriorMRILeftTemplate', posteriorMRILeftTemplate', lateralMRIRightTemplate', anteriorMRIRightTemplate', posteriorMRIRightTemplate'];

% Calculate centroids 
centroidSub = mean(Sub,2);
centroidTemp = mean(Temp,2);

% Calculate familiar covariance 
H = (Sub - centroidSub)*(Temp - centroidTemp)';

% SVD to find the rotation 
[U,S,V] = svd(H);
rotationMatrix = V*U';

% Plot to check the fit
% plotMRINormals(lateralMRILeftTemplate, lateralMRIRightTemplate, ...
%                anteriorMRILeftTemplate, anteriorMRIRightTemplate, ...
%                posteriorMRILeftTemplate, posteriorMRIRightTemplate)
% hold on
% 
% plotMRINormals(lateralMRILeftSubject, lateralMRIRightSubject, ...
%  anteriorMRILeftSubject, anteriorMRIRightSubject, ...
%  posteriorMRILeftSubject, posteriorMRIRightSubject) 
% hold on
% plotMRINormals(R*lateralMRILeftSubject', R*lateralMRIRightSubject', ...
%  R*anteriorMRILeftSubject', R*anteriorMRIRightSubject', ...
%  R*posteriorMRILeftSubject', R*posteriorMRIRightSubject')  
end