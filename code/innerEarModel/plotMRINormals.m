function plotMRINormals(lateralMRILeft, lateralMRIRight, ...
                        anteriorMRILeft, anteriorMRIRight, ...
                        posteriorMRILeft, posteriorMRIRight)

    % Plot left ear
    quiver3(0,0,0,lateralMRILeft.normal(1),lateralMRILeft.normal(2),lateralMRILeft.normal(3),'k')
    hold on
    axis equal
    xlabel('x')
    ylabel('y')
    zlabel('z')
    quiver3(0,0,0,anteriorMRILeft.normal(1),anteriorMRILeft.normal(2),anteriorMRILeft.normal(3),'g')
    quiver3(0,0,0,posteriorMRILeft.normal(1),posteriorMRILeft.normal(2),posteriorMRILeft.normal(3),'b')

    % Plot the right ear
    quiver3(0,-3,0,lateralMRIRight.normal(1),lateralMRIRight.normal(2),lateralMRIRight.normal(3),'r')
    xlabel('x')
    ylabel('y')
    zlabel('z')
    axis equal
    quiver3(0,-3,0,anteriorMRIRight.normal(1),anteriorMRIRight.normal(2),anteriorMRIRight.normal(3),'g')
    quiver3(0,-3,0,posteriorMRIRight.normal(1),posteriorMRIRight.normal(2),posteriorMRIRight.normal(3),'b')
    hold off
end