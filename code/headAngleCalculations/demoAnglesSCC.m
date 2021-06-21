% This is example code that provides the Euler angles that describe the
% orientation of each of the semi-circular canals with respect to the B0
% magnetic field.
%
% The example is performed for one subject (TOME_3045). The demo requires
% the "normals" directory that Ozzy is able to produce using Ahmad's SCC
% template fitting code. The demo also accesses the T2 NIFTI file
% associated with this subject to obtain the angles of the FOV of the
% imaging acquisition w.r.t. the B0 field.


showPlot = true;


%% Identify the ImageOrientationPatientDICOM from a NIFTI image

% The acquisition ID for the T2 image for TOME_3046
% To get this ID:
%{
    fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));
    sessionID = '5cf166af36da2300403a9c43';
    acqList = fw.getSessionAcquisitions(sessionID);
    acqID = acqList{find(cellfun(@(x) strcmp(x.label,'T2w_SPC'),acqList))}.id;
%}

acqID = '5cf1724336da2300473b7b75'; 

% Get the acquisition container
fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));
acquisition = fw.get(acqID);

% We know that the 2nd file is the nifti file. One could write some code to
% check that this is true, or to identify which of the files has the nifti
% suffix
fileIdx = 2;

% Get this file container
file = acquisition.files{2};

% The value we want is the orientation of the FoV w.r.t. the scanner bore
iop = file.info.ImageOrientationPatientDICOM;

% Derive rotation matrix m from ImageOrientationPatientDICOM
xyzR = iop(1:3);
xyzC = iop(4:6);
xyzS = [ (xyzR(2) * xyzC(3)) - (xyzR(3) * xyzC(2)) ; ...
    (xyzR(3) * xyzC(1)) - (xyzC(1) * xyzC(3)) ; ...
    (xyzR(1) * xyzC(2)) - (xyzR(2) * xyzC(1))  ...
    ];
m = [xyzR xyzC xyzS];

% adjust m to wrap the Euler angles and center them on zero
m = eul2rotm(deg2rad(rad2deg(rotm2eul(m,'ZYX')) + [-90 0 90]),'ZYX');

% Prepare plot elements
if showPlot
    sccList = {'lat','ant','post'};
    sideList = {'right','left'};
    colorList = {'r','g','b'};
    figHandle=figure();
end

% Set up a table to hold the results
T = table('Size',[6 3],'VariableTypes',{'string','string','double'});
T.Properties.VariableNames = {'Side','Canal','Angle w.r.t B0'};
sides = {'right','left'};
canals = {'lat','ant','post'};

% Now loop through the canals
for cc=1:3
    for ss=1:2
        fileName = fullfile('/Users/aguirre/Desktop/normals',[sideList{ss} '_' sccList{cc} '.mat']);
        load(fileName);
        
        % Rotate the plane normal, offset, and point array by the IOP
        % rotation matrix
        offset = m*offset';
        normal = m*normal';
        point_array=(m*point_array')';
        
        R1 = [offset, normal];
        R2 = [0 0 0; 0 0 1]';
        [~,angle_xz] = angleRays( R1, R2 );
        
        % Report the values for this subject to the screen
        str = sprintf([sideList{ss} '_' sccList{cc} ' (' colorList{cc} '), angle w.r.t B0: %2.1f degrees'],angle_xz);
        disp(str);
        
        % Save the value in the table
        row = 2*(cc-1)+ss;
        T(row,1)=sides(ss);
        T(row,2)=canals(cc);
        T(row,3)={angle_xz};
        
        % Construct the plot if requested
        if showPlot
            plot3(point_array(:,1),point_array(:,2),point_array(:,3),['*' colorList{cc}])
            hold on
            quiver3(offset(1),offset(2),offset(3),normal(1),normal(2),normal(3),5,['-' colorList{cc}],'LineWidth',3)
        end
        
    end
end

% Clean up plot
if showPlot
    axis equal
    xlabel('Left (-) -- Right (+)')
    ylabel('Posterior (-) -- Anterior (+)')
    zlabel('Inferior (-) -- Superior (+)')
end

% Save the table
fileName = '/Users/aguirre/Desktop/TOME_3046_CanalAnglesWithB0.csv';
writetable(T,fileName)



%% LOCAL FUNCTION
function [angle_xy, angle_xz] = angleRays( R1, R2 )
% Returns the angle in degrees between two rays
%
% Syntax:
%  [angle_xy, angle_xz] = angleRays( R1, R2 )
%
% Description:
%   Just what it says on the tin.
%
% Inputs:
%   R1, R2                - 3x2 matrix that specifies a vector of the form
%                           [p; u], corresponding to
%                               R = p + t*u
%                           where p is vector origin, u is the direction
%                           expressed as a unit step, and t is unity for a
%                           unit vector.
%
% Outputs:
%   angle_xy, angle_xz    - Scalars. Angles in degrees between the rays
%                           projected on the xy and xz planes.
%
% Examples:
%{
    p = [0;0;0];
    u = [1;0;0];
    R1 = quadric.normalizeRay([p, u]);
    p = [0;0;0];
    u = [1;tand(15);tand(-7)];
    R2 = quadric.normalizeRay([p, u]);
    [angle, angle_xy, angle_xz] = quadric.angleRays( R1, R2 );
%}

% Obtain the angles as projected on the xy and xz planes
u1_xy = [R1(1,2);R1(2,2);0];
u2_xy = [R2(1,2);R2(2,2);0];
angle_xy = rad2deg(atan2(norm(cross(u1_xy,u2_xy)), dot(u1_xy,u2_xy)));

% Make the angle signed with respect to the R1 vector
angle_xy = angle_xy*sign(dot([0;0;1],cross(u1_xy,u2_xy)));

u1_xz = [R1(1,2);0;R1(3,2)];
u2_xz = [R2(1,2);0;R2(3,2)];
angle_xz = rad2deg(atan2(norm(cross(u1_xz,u2_xz)), dot(u1_xz,u2_xz)));

% Make the angle signed with respect to the R1 vector
angle_xz = angle_xz*sign(dot([0;1;0],cross(u1_xz,u2_xz)));


end


