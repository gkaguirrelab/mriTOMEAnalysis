function plotMRINormals(lateralMRILeft, lateralMRIRight, ...
                        anteriorMRILeft, anteriorMRIRight, ...
                        posteriorMRILeft, posteriorMRIRight)

    % This function plots the normals for a single subject. Left and right
    % ears are separated along the x-axis to visualize correct RAS orient. 
                    
    % Plot left ear
    quiver3(-3,0,0,lateralMRILeft(1),lateralMRILeft(2),lateralMRILeft(3),'k')
    hold on
    axis equal
    xlabel('x')
    ylabel('y')
    zlabel('z')
    quiver3(-3,0,0,anteriorMRILeft(1),anteriorMRILeft(2),anteriorMRILeft(3),'g')
    quiver3(-3,0,0,posteriorMRILeft(1),posteriorMRILeft(2),posteriorMRILeft(3),'b')

    % Plot the right ear
    quiver3(0,0,0,lateralMRIRight(1),lateralMRIRight(2),lateralMRIRight(3),'r')
    xlabel('x')
    ylabel('y')
    zlabel('z')
    axis equal
    quiver3(0,0,0,anteriorMRIRight(1),anteriorMRIRight(2),anteriorMRIRight(3),'g')
    quiver3(0,0,0,posteriorMRIRight(1),posteriorMRIRight(2),posteriorMRIRight(3),'b')
    hold off
end