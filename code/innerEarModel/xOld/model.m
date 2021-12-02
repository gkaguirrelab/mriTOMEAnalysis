function [LateralVector, AnteriorVector, PosteriorVector, LateralVectorOtherEar, AnteriorVectorOtherEar, PosteriorVectorOtherEar] =  model()

% Plot della Santina inner ear vectors

% Define the mean angles between SSC
AnteriorPosterior = 92.1;
AnteriorLateral = 84.4;
Posteriorlateral = 86.2;

% Create an anterior unit vector
LateralVector = [0; 0; 1];

%% Anterior
% Counter clockwise x rotation to posterior direction from anterior direction
rotationx = [1            0                           0             ; ... 
             0    cosd(AnteriorLateral)   -sind(AnteriorLateral); ...
             0    sind(AnteriorLateral)   cosd(AnteriorLateral)];

% Define posterior
AnteriorVector = rotationx*LateralVector;

%% Lateral
% Initial rotation about y-axis to lateral direction from anterior direction  
rotationy = [cosd(Posteriorlateral)        0         sind(Posteriorlateral); ... 
                      0                    1                   0          ; ...
             -sind(Posteriorlateral)       0         cosd(Posteriorlateral)];

PosteriorVector = rotationy*LateralVector;

% Calculate theta angle to rotate lateral vector towards the posterior
% vector about the z-axis
sindtheta = (cosd(Posteriorlateral)*cosd(AnteriorLateral)-cosd(AnteriorPosterior))/(sind(Posteriorlateral)*sind(AnteriorLateral));
theta = asind(sindtheta);

% Define z rotation towards posterior vector
rotationz = [cosd(theta)    -sind(theta)      0; ... 
             sind(theta)    cosd(theta)       0; ...
                 0               0            1];

PosteriorVector = rotationz*PosteriorVector;

% % Plot one ear
% quiver3(0,0,0,LateralVector(1),LateralVector(2),LateralVector(3),'r')
% hold on
% xlabel('x')
% ylabel('y')
% zlabel('z')
% quiver3(0,0,0,AnteriorVector(1),AnteriorVector(2),AnteriorVector(3),'g')
% quiver3(0,0,0,PosteriorVector(1),PosteriorVector(2),PosteriorVector(3),'b')
% axis equal

LateralVectorOtherEar = LateralVector;
AnteriorVectorOtherEar = rotz(180)*AnteriorVector;
PosteriorVectorOtherEar = PosteriorVector;

xvec = [1;0;0];
% quiver3(0,0,0,xvec(1),xvec(2),xvec(3),'m')
degreeDiff = 90 - 86.2;
intervec = roty(degreeDiff)*PosteriorVector;
% quiver3(0,0,0,intervec(1),intervec(2),intervec(3),'y')
rotateAngle = rad2deg(atan2(norm(cross(intervec,xvec)), dot(intervec,xvec)));
PosteriorVectorOtherEar = rotz(2*-rotateAngle-0.0109)*PosteriorVector;

% % Plot the other ear
% quiver3(0,-3,0,LateralVectorOtherEar(1),LateralVectorOtherEar(2),LateralVectorOtherEar(3),'k')
% hold on
% xlabel('x')
% ylabel('y')
% zlabel('z')
% quiver3(0,-3,0,AnteriorVectorOtherEar(1),AnteriorVectorOtherEar(2),AnteriorVectorOtherEar(3),'g')
% quiver3(0,-3,0,PosteriorVectorOtherEar(1),PosteriorVectorOtherEar(2),PosteriorVectorOtherEar(3),'b')
% axis equal

% Recalculate angles between vectors to make sure the earlier calculations are correct 
calcAP = rad2deg(atan2(norm(cross(AnteriorVectorOtherEar,PosteriorVectorOtherEar)), dot(AnteriorVectorOtherEar,PosteriorVectorOtherEar)));
calcAL = rad2deg(atan2(norm(cross(AnteriorVectorOtherEar,LateralVectorOtherEar)), dot(AnteriorVectorOtherEar,LateralVectorOtherEar)));
calcPL = rad2deg(atan2(norm(cross(PosteriorVectorOtherEar,LateralVectorOtherEar)), dot(PosteriorVectorOtherEar,LateralVectorOtherEar)));
fprintf(['Calculated angle between Anterior and Posterior vectors is ' num2str(calcAP) '\n'])
fprintf(['Calculated angle between Anterior and Lateral vectors is ' num2str(calcAL) '\n'])
fprintf(['Calculated angle between Posterior and Lateral vectors is ' num2str(calcPL) '\n'])

% Check the angles between left-right
ant = rad2deg(atan2(norm(cross(AnteriorVectorOtherEar,AnteriorVector)), dot(AnteriorVectorOtherEar,AnteriorVector)));
lat = rad2deg(atan2(norm(cross(LateralVectorOtherEar,LateralVector)), dot(LateralVectorOtherEar,LateralVector)));
post = rad2deg(atan2(norm(cross(PosteriorVectorOtherEar,PosteriorVector)), dot(PosteriorVectorOtherEar,PosteriorVector)));
fprintf(['Calculated angle between Lateral left-right ' num2str(lat) '\n'])
fprintf(['Calculated angle between Anterior left-right ' num2str(ant) '\n'])
fprintf(['Calculated angle between Posterior left-right ' num2str(post) '\n'])
end
