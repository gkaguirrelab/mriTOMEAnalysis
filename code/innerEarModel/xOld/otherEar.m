function [LateralVectorOtherEar, AnteriorVectorOtherEar, PosteriorVectorOtherEar] = otherEar()

% [LateralVector, AnteriorVector, PosteriorVector] = oneEar();
[LateralVector, AnteriorVector, PosteriorVector] =  oneEar();

%% Do vector rotation
% Combine vectors
V=[LateralVector,AnteriorVector,PosteriorVector]; 

% Combine angles between vectors and convert to radian
ag=[11.3,103.4,83.2]*pi/180; 

%initial guess: all Euler angles=0 i.e. no rotation
p0=[0,0,0];         

% Lower and upper bounds 
pmin=[0,0,0]; pmax=[2*pi,pi,2*pi]; 

% Minimization options
options=optimoptions('fmincon','Display','notify');  

%Do the minimization
[p,sse]=fmincon(@(p)sumsqerr(p,V,ag),p0,[],[],[],[],pmin,pmax,[],options);

%Extract best-fit Euler angles
a=p(1); b=p(2); c=p(3);

%Compute best-fit rotation matrix
R=[cos(b)*cos(c),sin(a)*sin(b)*cos(c)-cos(a)*sin(c),cos(a)*sin(b)*cos(c)+sin(a)*sin(c);...
   cos(b)*sin(c),sin(a)*sin(b)*sin(c)+cos(a)*cos(c),cos(a)*sin(b)*sin(c)-sin(a)*cos(c);...
  -sin(b)       ,sin(a)*cos(b)                     ,cos(a)*cos(b)];

%Compute new vectors=rotated vectors
Vnew=R*V;

LateralVectorOtherEar = Vnew(:,1);
AnteriorVectorOtherEar = Vnew(:,2);
PosteriorVectorOtherEar = Vnew(:,3);

% Recalculate angles between vectors to make sure the earlier calculations are correct 
calcAP = rad2deg(atan2(norm(cross(AnteriorVector,PosteriorVector)), dot(AnteriorVector,PosteriorVector)));
calcAL = rad2deg(atan2(norm(cross(AnteriorVector,LateralVector)), dot(AnteriorVector,LateralVector)));
calcPL = rad2deg(atan2(norm(cross(PosteriorVector,LateralVector)), dot(PosteriorVector,LateralVector)));
fprintf(['Calculated angle between Anterior and Posterior vectors is ' num2str(calcAP) '\n'])
fprintf(['Calculated angle between Anterior and Lateral vectors is ' num2str(calcAL) '\n'])
fprintf(['Calculated angle between Posterior and Lateral vectors is ' num2str(calcPL) '\n'])

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

% Plot one ear
quiver3(0,0,0,LateralVector(1),LateralVector(2),LateralVector(3),'k')
hold on
xlabel('x')
ylabel('y')
zlabel('z')
quiver3(0,0,0,AnteriorVector(1),AnteriorVector(2),AnteriorVector(3),'g')
quiver3(0,0,0,PosteriorVector(1),PosteriorVector(2),PosteriorVector(3),'b')

% Plot the other ear
quiver3(0,1,0,LateralVectorOtherEar(1),LateralVectorOtherEar(2),LateralVectorOtherEar(3),'r')
hold on
xlabel('x')
ylabel('y')
zlabel('z')
quiver3(0,1,0,AnteriorVectorOtherEar(1),AnteriorVectorOtherEar(2),AnteriorVectorOtherEar(3),'g')
quiver3(0,1,0,PosteriorVectorOtherEar(1),PosteriorVectorOtherEar(2),PosteriorVectorOtherEar(3),'b')


function sse=sumsqerr(angles,V,ag)
%Compute sum squared error between actual and goal angles.
%Assumes vectors V and goal angles axg,ayg,azg are known within the function.
%Input: angles=[a,b,c]=rotation angles about x,y,z axes respectively.
%Output: sse(scalar)

%Extract Euler angles
a=angles(1); b=angles(2); c=angles(3);
%Extract goal angles between old and new vectors
axg=ag(1); ayg=ag(2); azg=ag(3);

%Compute rotation matrix
R=[cos(b)*cos(c),sin(a)*sin(b)*cos(c)-cos(a)*sin(c),cos(a)*sin(b)*cos(c)+sin(a)*sin(c);...
   cos(b)*sin(c),sin(a)*sin(b)*sin(c)+cos(a)*cos(c),cos(a)*sin(b)*sin(c)-sin(a)*cos(c);...
  -sin(b)       ,sin(a)*cos(b)                     ,cos(a)*cos(b)];
%Compute the new vectors
Vnew=R*V;
%Compute the angles between the old and new vectors 
ax=acos(Vnew(:,1)'*V(:,1)/(norm(Vnew(:,1))*norm(V(:,1))));
ay=acos(Vnew(:,2)'*V(:,2)/(norm(Vnew(:,2))*norm(V(:,2))));
az=acos(Vnew(:,3)'*V(:,3)/(norm(Vnew(:,3))*norm(V(:,3))));
%Compute sum squared error=dot product of goal angles with angles.
sse=(axg-ax)^2+(ayg-ay)^2+(azg-az)^2;
end
end