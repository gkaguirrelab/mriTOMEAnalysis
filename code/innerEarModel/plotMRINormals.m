function plotMRINormals(lateralMRILeft, lateralMRIRight, ...
                        anteriorMRILeft, anteriorMRIRight, ...
                        posteriorMRILeft, posteriorMRIRight, dashed, thick)

    % This function plots the normals for a single subject. Left and right
    % ears are separated along the x-axis to visualize correct RAS orient. 

    if true(dashed)
        % Plot left ear
        quiver3(-3,0,0,lateralMRILeft(1),lateralMRILeft(2),lateralMRILeft(3),'r','LineStyle', '--')
        hold on
        axis equal
        xlabel('x')
        ylabel('y')
        zlabel('z')
        quiver3(-3,0,0,anteriorMRILeft(1),anteriorMRILeft(2),anteriorMRILeft(3),'g','LineStyle', '--')
        quiver3(-3,0,0,posteriorMRILeft(1),posteriorMRILeft(2),posteriorMRILeft(3),'y','LineStyle', '--')

        % Plot the right ear
        quiver3(0,0,0,lateralMRIRight(1),lateralMRIRight(2),lateralMRIRight(3),'r','LineStyle', '--')
        xlabel('x')
        ylabel('y')
        zlabel('z')
        axis equal
        quiver3(0,0,0,anteriorMRIRight(1),anteriorMRIRight(2),anteriorMRIRight(3),'g','LineStyle', '--')
        quiver3(0,0,0,posteriorMRIRight(1),posteriorMRIRight(2),posteriorMRIRight(3),'y','LineStyle', '--')
        hold off
    elseif true(thick)
        % Plot left ear
        quiver3(-3,0,0,lateralMRILeft(1),lateralMRILeft(2),lateralMRILeft(3),'r','linewidth',5,'color', [0.6350 0.0780 0.1840])
        hold on
        axis equal
        xlabel('x')
        ylabel('y')
        zlabel('z')
        quiver3(-3,0,0,anteriorMRILeft(1),anteriorMRILeft(2),anteriorMRILeft(3),'g','linewidth',5,'color', [0.4660 0.6740 0.1880])
        quiver3(-3,0,0,posteriorMRILeft(1),posteriorMRILeft(2),posteriorMRILeft(3),'y','linewidth',5,'color', [0.9290 0.6940 0.1250])

        % Plot the right ear
        quiver3(0,0,0,lateralMRIRight(1),lateralMRIRight(2),lateralMRIRight(3),'r','linewidth',5, 'color', [0.6350 0.0780 0.1840])
        xlabel('x')
        ylabel('y')
        zlabel('z')
        axis equal
        quiver3(0,0,0,anteriorMRIRight(1),anteriorMRIRight(2),anteriorMRIRight(3),'g','linewidth',5, 'color', [0.4660 0.6740 0.1880])
        quiver3(0,0,0,posteriorMRIRight(1),posteriorMRIRight(2),posteriorMRIRight(3),'y','linewidth',5,'color', [0.9290 0.6940 0.1250])
        hold off

    else 
        quiver3(-3,0,0,lateralMRILeft(1),lateralMRILeft(2),lateralMRILeft(3),'r')
        hold on
        axis equal
        xlabel('x')
        ylabel('y')
        zlabel('z')
        quiver3(-3,0,0,anteriorMRILeft(1),anteriorMRILeft(2),anteriorMRILeft(3),'g')
        quiver3(-3,0,0,posteriorMRILeft(1),posteriorMRILeft(2),posteriorMRILeft(3),'y')

        % Plot the right ear
        quiver3(0,0,0,lateralMRIRight(1),lateralMRIRight(2),lateralMRIRight(3),'r')
        xlabel('x')
        ylabel('y')
        zlabel('z')
        axis equal
        quiver3(0,0,0,anteriorMRIRight(1),anteriorMRIRight(2),anteriorMRIRight(3),'g')
        quiver3(0,0,0,posteriorMRIRight(1),posteriorMRIRight(2),posteriorMRIRight(3),'y')
        hold off    
    end