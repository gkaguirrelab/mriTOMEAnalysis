% function rotationMatrix = calculateRotationToTemplate(subjectNormalFolder, templateNormalFolder)

templateNormalFolder = 'C:\Users\ozenc\Documents\MATLAB\projects\mriTOMEAnalysis\code\innerEarModel\templateFids';
subjectNormalFolder = 'C:\Users\ozenc\Desktop\ForOzzy\ForOzzy\tome\TOME_3045';

% Load template normals
[lateralMRILeftTemplate, lateralMRIRightTemplate, ...
 anteriorMRILeftTemplate, anteriorMRIRightTemplate, ...
 posteriorMRILeftTemplate, posteriorMRIRightTemplate] = loadMRINormals(templateNormalFolder);

% % Load subject normals
% [lateralMRILeftSubject, lateralMRIRightSubject, ...
%  anteriorMRILeftSubject, anteriorMRIRightSubject, ...
%  posteriorMRILeftSubject, posteriorMRIRightSubject] = loadMRINormals(subjectNormalFolder);

%% TEST SUBJECT FIXES
% Extract best fit euler 
a=-pi/24 ; b=0; c=0;

B = [cos(b)*cos(c),sin(a)*sin(b)*cos(c)-cos(a)*sin(c),cos(a)*sin(b)*cos(c)+sin(a)*sin(c);...
     cos(b)*sin(c),sin(a)*sin(b)*sin(c)+cos(a)*cos(c),cos(a)*sin(b)*sin(c)-sin(a)*cos(c);...
     -sin(b)       ,sin(a)*cos(b)                     ,cos(a)*cos(b)];

lateralMRILeftSubject = (B*lateralMRILeftTemplate')';
lateralMRIRightSubject = (B*lateralMRIRightTemplate')';
anteriorMRILeftSubject = (B*anteriorMRILeftTemplate')';
anteriorMRIRightSubject = (B*anteriorMRIRightTemplate')';
posteriorMRILeftSubject = (B*posteriorMRILeftTemplate')';
posteriorMRIRightSubject = (B*posteriorMRIRightTemplate')';

plotMRINormals(lateralMRILeftTemplate, lateralMRIRightTemplate, ...
               anteriorMRILeftTemplate, anteriorMRIRightTemplate, ...
               posteriorMRILeftTemplate, posteriorMRIRightTemplate)
hold on

% plotMRINormals(lateralMRILeftSubject, lateralMRIRightSubject, ...
%  anteriorMRILeftSubject, anteriorMRIRightSubject, ...
%  posteriorMRILeftSubject, posteriorMRIRightSubject)  
%%
% Set options for minimization routine 
options=optimoptions('fmincon','Display','iter'); 

% Lower and upper bounds for search
p0=[0, 0, 0]; 
pmin=[pi/30,pi/30,pi/30]; pmax=[pi/20,pi/20,pi/20]; %lower, upper bounds

%Do the minimization
[p, diff]=fmincon(@(p)cosDiff(p, lateralMRILeftSubject, lateralMRIRightSubject, anteriorMRILeftSubject, anteriorMRIRightSubject, posteriorMRILeftSubject, posteriorMRIRightSubject, lateralMRILeftTemplate, lateralMRIRightTemplate, anteriorMRILeftTemplate, anteriorMRIRightTemplate, posteriorMRILeftTemplate, posteriorMRIRightTemplate),p0,[],[],[],[],pmin,pmax,[],options);

% Extract best fit euler 
a=p(1); b=p(2); c=p(3);

% Calculate the rotation matrix
R = [cos(b)*cos(c),sin(a)*sin(b)*cos(c)-cos(a)*sin(c),cos(a)*sin(b)*cos(c)+sin(a)*sin(c);...
     cos(b)*sin(c),sin(a)*sin(b)*sin(c)+cos(a)*cos(c),cos(a)*sin(b)*sin(c)-sin(a)*cos(c);...
     -sin(b)       ,sin(a)*cos(b)                     ,cos(a)*cos(b)];

hold on
plotMRINormals(R*lateralMRILeftSubject', R*lateralMRIRightSubject', ...
 R*anteriorMRILeftSubject', R*anteriorMRIRightSubject', ...
 R*posteriorMRILeftSubject', R*posteriorMRIRightSubject')        

function diff = cosDiff(eulerAngles, SLL, SLR, SAL, SAR, SPL, SPR, ...
                       TLL, TLR, TAL, TAR, TPL, TPR)

averageLeftSubject = (SLL + SAL + SPL)/3;
averageRightSubject = (SLR + SAR + SPR)/3;
averageSubjectHead = (averageLeftSubject + averageRightSubject)/2;

averageLeftTemplate = (TLL + TAL + TPL)/3;
averageRightTemplate = (TLR + TAR + TPR)/3;
averageTemplateHead = (averageLeftTemplate + averageRightTemplate)/2;




% cosSim = dot(averageSubjectHead,averageTemplateHead)/(norm(averageSubjectHead)*norm(averageTemplateHead));
% 
% %Extract Euler angles
% a=eulerAngles(1); b=eulerAngles(2); c=eulerAngles(3);
% 
% %Compute rotation matrix
% rotationMatrix=[cos(b)*cos(c),sin(a)*sin(b)*cos(c)-cos(a)*sin(c),cos(a)*sin(b)*cos(c)+sin(a)*sin(c);...
%                 cos(b)*sin(c),sin(a)*sin(b)*sin(c)+cos(a)*cos(c),cos(a)*sin(b)*sin(c)-sin(a)*cos(c);...
%                 -sin(b)       ,sin(a)*cos(b)                     ,cos(a)*cos(b)];
% 
% %Compute the new vectors
% SLLNew = (rotationMatrix*SLL')';
% SLRNew = (rotationMatrix*SLR')';
% SALNew = (rotationMatrix*SAL')';
% SARNew = (rotationMatrix*SAR')';
% SPLNew = (rotationMatrix*SPL')';
% SPRNew = (rotationMatrix*SPR')';
% 
% averageLeftSubjectNew = (SLLNew + SALNew + SPLNew)/3;
% averageRightSubjectNew = (SLRNew + SARNew + SPRNew)/3;
% averageSubjectHeadNew = (averageLeftSubjectNew + averageRightSubjectNew)/2;
% 
% cosSimNew = dot(averageSubjectHeadNew,averageTemplateHead)/(norm(averageSubjectHeadNew)*norm(averageTemplateHead));
% diff = (cosSimNew-cosSim)^2;


%KEEEEEEEEEEEEEEEE
% % Calculate the angles between current and target vectors
% lateralLeftAngleCurrent = rad2deg(atan2(norm(cross(SLL,TLL)), dot(SLL,TLL)));
% lateralRightAngleCurrent = rad2deg(atan2(norm(cross(SLR,TLR)), dot(SLR,TLR)));
% anteriorLeftAngleCurrent = rad2deg(atan2(norm(cross(SAL,TAL)), dot(SAL,TAL)));
% anteriorRightAngleCurrent = rad2deg(atan2(norm(cross(SAR,TAR)), dot(SAR,TAR)));
% posteriorLeftAngleCurrent = rad2deg(atan2(norm(cross(SPL,TPL)), dot(SPL,TPL)));
% posteriorRightAngleCurrent = rad2deg(atan2(norm(cross(SPR,TPR)), dot(SPR,TPR)));                                 
%                                  
% %Extract Euler angles
% a=eulerAngles(1); b=eulerAngles(2); c=eulerAngles(3);
% 
% %Compute rotation matrix
% rotationMatrix=[cos(b)*cos(c),sin(a)*sin(b)*cos(c)-cos(a)*sin(c),cos(a)*sin(b)*cos(c)+sin(a)*sin(c);...
%                 cos(b)*sin(c),sin(a)*sin(b)*sin(c)+cos(a)*cos(c),cos(a)*sin(b)*sin(c)-sin(a)*cos(c);...
%                 -sin(b)       ,sin(a)*cos(b)                     ,cos(a)*cos(b)];
% 
% %Compute the new vectors
% lateralNewLeft = (rotationMatrix*SLL')';
% lateralNewRight = (rotationMatrix*SLR')';
% anteriorNewLeft = (rotationMatrix*SAL')';
% anteriorNewRight = (rotationMatrix*SAR')';
% posteriorNewLeft = (rotationMatrix*SPL')';
% posteriorNewRight = (rotationMatrix*SPR')';
% 
% % Calculate the angles between new and target vectors
% lateralLeftAngleNew = rad2deg(atan2(norm(cross(lateralNewLeft,TLL)), dot(lateralNewLeft,TLL)));
% lateralRightAngleNew = rad2deg(atan2(norm(cross(lateralNewRight,TLR)), dot(lateralNewRight,TLR)));
% anteriorLeftAngleNew = rad2deg(atan2(norm(cross(anteriorNewLeft,TAL)), dot(anteriorNewLeft,TAL)));
% anteriorRightAngleNew = rad2deg(atan2(norm(cross(anteriorNewRight,TAR)), dot(anteriorNewRight,TAR)));
% posteriorLeftAngleNew = rad2deg(atan2(norm(cross(posteriorNewLeft,TPL)), dot(posteriorNewLeft,TPL)));
% posteriorRightAngleNew = rad2deg(atan2(norm(cross(posteriorNewRight,TPR)), dot(posteriorNewRight,TPR)));
% 
% % Calculate the angles between the input and target vectors
% %Compute sum squared error=dot product of goal angles with angles.
% sse=(lateralLeftAngleNew-lateralLeftAngleCurrent)^2+(lateralRightAngleNew-lateralRightAngleCurrent)^2+(anteriorLeftAngleNew-anteriorLeftAngleCurrent)^2+(anteriorRightAngleCurrent-anteriorRightAngleNew)^2+(posteriorLeftAngleCurrent-posteriorLeftAngleNew)^2+(posteriorRightAngleCurrent-posteriorRightAngleNew)^2;
end
% end