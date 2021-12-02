function [LateralVector, AnteriorVector, PosteriorVector] =  oneEar()

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

%% Recalculate angles between vectors to make sure the earlier calculations are correct 
calcAP = rad2deg(atan2(norm(cross(AnteriorVector,PosteriorVector)), dot(AnteriorVector,PosteriorVector)));
calcAL = rad2deg(atan2(norm(cross(AnteriorVector,LateralVector)), dot(AnteriorVector,LateralVector)));
calcPL = rad2deg(atan2(norm(cross(PosteriorVector,LateralVector)), dot(PosteriorVector,LateralVector)));
fprintf(['Calculated angle between Anterior and Posterior vectors is ' num2str(calcAP) '\n'])
fprintf(['Calculated angle between Anterior and Lateral vectors is ' num2str(calcAL) '\n'])
fprintf(['Calculated angle between Posterior and Lateral vectors is ' num2str(calcPL) '\n'])

% Plot one ear
quiver3(0,0,0,LateralVector(1),LateralVector(2),LateralVector(3),'r')
hold on
xlabel('x')
ylabel('y')
zlabel('z')
quiver3(0,0,0,AnteriorVector(1),AnteriorVector(2),AnteriorVector(3),'g')
quiver3(0,0,0,PosteriorVector(1),PosteriorVector(2),PosteriorVector(3),'b')
