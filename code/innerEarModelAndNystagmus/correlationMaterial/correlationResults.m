%% Cammille correlations 
% Set the code directory after tbUse
currentDirectory = pwd; 
pcaWithAllFids = true;

% Read YPR table, rename the first variable to 'Patient'
ypr = load(fullfile(currentDirectory, 'code', 'innerEarModelAndNystagmus', 'correlationMaterial', 'qformRots.mat'));
ypr = ypr.qformRots;
ypr = renamevars(ypr,'qformRots1','Patient');
ypr = renamevars(ypr,'qformRots2','Yaw');
ypr = renamevars(ypr,'qformRots3','Pitch');
ypr = renamevars(ypr,'qformRots4','Roll');
ypr.Roll = -ypr.Roll;             
               
% Read the nystagmus table and only retain the meanX and meanY columns 
nystagmus = readtable(fullfile(currentDirectory, 'code', 'innerEarModelAndNystagmus', 'correlationMaterial', 'nystagmus.xlsx'));

% Remove subjects that have no structurals in the rest ses from YPR values
% These are TOME_0012,18,19,21,30,44
subjectsToRemove = [find(strcmp('TOME_3012',nystagmus.Patient)),...
                    find(strcmp('TOME_3018',nystagmus.Patient)),...
                    find(strcmp('TOME_3019',nystagmus.Patient)),...
                    find(strcmp('TOME_3021',nystagmus.Patient)),...
                    find(strcmp('TOME_3030',nystagmus.Patient)),...
                    find(strcmp('TOME_3044',nystagmus.Patient))];
nystagmus(subjectsToRemove,:) = [];  
% Create a comparison table by combining two tables by the common rows
comparisonTable = innerjoin(ypr, nystagmus);

% Calculate std weights 
weights_x = 1./comparisonTable.StdX;
weights_y = 1./comparisonTable.StdY;

% Get the correlation between horizontal vs pitch and vertical vs roll
x = comparisonTable.Pitch; y = comparisonTable.MeanX;
fit = fitlm(x,y,'linear','RobustOpts','on','weights',weights_x);
ci = fit.coefCI;
ci = ci(2,:);
fprintf('Head pitch and horizontal nystagmus: R-squared = %2.2f slope[95%% CI] = %2.2f [%2.2f to %2.2f], p = %2.3f \n',fit.Rsquared.Adjusted,fit.Coefficients{2,1},ci,fit.coefTest)

x = comparisonTable.Roll; y = comparisonTable.MeanY;
fit = fitlm(x,y,'linear','RobustOpts','on','weights',weights_y);
ci = fit.coefCI;
ci = ci(2,:);
fprintf('Head roll and vertical nystagmus: R-squared = %2.2f slope[95%% CI] = %2.2f [%2.2f to %2.2f], p = %2.3f \n\n',fit.Rsquared.Adjusted,fit.Coefficients{2,1},ci,fit.coefTest)

% Inner ear correlations 
% Download the inner ear files
innerEarLoc = fullfile(currentDirectory, 'code', 'innerEarModelAndNystagmus', 'correlationMaterial', 'subjectNormals');
if ~isfolder(innerEarLoc)
    fprintf('Downloading inner ear normals.') 
    downloadSubjectNormals(innerEarLoc)
end

% Find the normal paths and set an empty cell for saving
folders = dir(innerEarLoc);
folders(1:2) = [];

% Set the inner ear model
lateralLeft = [0 0 1];
lateralRight = [0 0 1];
anteriorLeft = [1 0 0];
anteriorRight = [-1 0 0];
posteriorLeft = [0 1 0];
posteriorRight = [0 1 0];

% Loop through subjects and calculate an average vector
% Initiate figure
figHandle = figure();
figHandle.Renderer ='Painters';
for ii = 1:length(folders) 
    % Remove tome 3009 and 3029 as registration didn't work for these
    if ~strcmp(folders(ii).name, 'TOME_3009') || ~strcmp(folders(ii).name, 'TOME_3029')
        
        % Load normals
        [lateralMRILeft, lateralMRIRight, anteriorMRILeft, anteriorMRIRight, ...
         posteriorMRILeft, posteriorMRIRight] = loadMRINormals(fullfile(folders(ii).folder,folders(ii).name), pcaWithAllFids);

        Sub = [lateralMRILeft, lateralMRIRight, anteriorMRILeft, anteriorMRIRight, posteriorMRILeft, posteriorMRIRight];
        Temp = [lateralLeft', lateralRight', anteriorLeft', anteriorRight', posteriorLeft', posteriorRight'];

        % Calculate centroids 
        centroidSub = mean(Sub,2);
        centroidTemp = mean(Temp,2);

        % Calculate familiar covariance 
        H = (Temp - centroidTemp)*(Sub - centroidSub)';

        % SVD to find the rotation 
        [U,S,V] = svd(H);
        R = inv(V*U');  

        % Save name and rotated vectors
        cardinalWarped{ii, 1} = folders(ii).name;
        cardinalWarped{ii, 2} = R*Sub;
        
        % Thos plots normals after cardinal rotation
        plotMRINormals(cardinalWarped{ii, 2}(:,1), cardinalWarped{ii, 2}(:,2), ...
                       cardinalWarped{ii, 2}(:,3), cardinalWarped{ii, 2}(:,4), ...
                       cardinalWarped{ii, 2}(:,5), cardinalWarped{ii, 2}(:,6), false, false)      
        hold on
    end
end
view(-130.8370,20.3106)         
% Now average the cardinal warped normals 
cardinalAveragedVectors = mean(cat(3, cardinalWarped{:,2}), 3);

% This plots average vector after cardinal rotation
plotMRINormals(cardinalAveragedVectors(:,1), cardinalAveragedVectors(:,2), ...
               cardinalAveragedVectors(:,3), cardinalAveragedVectors(:,4), ...
               cardinalAveragedVectors(:,5), cardinalAveragedVectors(:,6), false, true)

% Set a normal cell where the y/p/r results and rotated vectors will be saved
allNormals = {};
allVectors = {};

% % Initiate figure
% figHandle = figure();
% figHandle.Renderer ='Painters';
for ii = 1:length(folders)
    
    % Remove tome 3009 and 3029 as registration didn't work for these
    if ~strcmp(folders(ii).name, 'TOME_3009') || ~strcmp(folders(ii).name, 'TOME_3029')
        
        % Load normals
        [lateralMRILeft, lateralMRIRight, anteriorMRILeft, anteriorMRIRight, ...
         posteriorMRILeft, posteriorMRIRight] = loadMRINormals(fullfile(folders(ii).folder,folders(ii).name), pcaWithAllFids);
        
        % Concatanate normals
        Sub = [lateralMRILeft, lateralMRIRight, anteriorMRILeft, anteriorMRIRight, posteriorMRILeft, posteriorMRIRight];

        % Calculate centroids of Sub and average 
        centroidSub = mean(Sub,2);
        centroidTemp = mean(cardinalAveragedVectors,2);

        % Calculate familiar covariance 
        H = (cardinalAveragedVectors - centroidTemp)*(Sub - centroidSub)';

        % SVD to find the rotation 
        [U,S,V] = svd(H);
        R = inv(V*U');       
        
        % Calculate euler angles from the rotation matrix and save them into
        % the allNormals cell
        euler = rad2deg(rotm2eul(R, 'XYZ')); 
        yaw = euler(3);
        pitch = euler(1); 
        roll = euler(2);

        allNormals{ii, 1} = folders(ii).name;
        allNormals{ii, 2} = yaw;
        allNormals{ii, 3} = pitch;    
        allNormals{ii, 4} = roll;     

        % Rotate the subject matrix
        lateralMRILeftNew = R*lateralMRILeft;
        lateralMRIRightNew = R*lateralMRIRight;
        anteriorMRILeftNew = R*anteriorMRILeft;
        anteriorMRIRightNew = R*anteriorMRIRight;
        posteriorMRILeftNew = R*posteriorMRILeft;
        posteriorMRIRightNew = R*posteriorMRIRight;   
        
        subNew = [lateralMRILeftNew, lateralMRIRightNew, ...
                  anteriorMRILeftNew, anteriorMRIRightNew, ...
                  posteriorMRILeftNew, posteriorMRIRightNew];
        
        % Save these to the all vetors file
        allVectors{ii, 1} = folders(ii).name;
        allVectors{ii, 2} = subNew;                 

%         % This plots the vectors after final rotation
%         plotMRINormals(lateralMRILeftNew, lateralMRIRightNew, ...
%                             anteriorMRILeftNew, anteriorMRIRightNew, ...
%                             posteriorMRILeftNew, posteriorMRIRightNew, false, false)
%         hold on
    end
end
   

% Average the final vectors 
finalMeanVector = mean(cat(3, allVectors{:,2}), 3);

% This plots the average of final warped vectors
% plotMRINormals(finalMeanVector(:,1), finalMeanVector(:,2), ...
%                finalMeanVector(:,3), finalMeanVector(:,4), ...
%                finalMeanVector(:,5), finalMeanVector(:,6), false, true) 

% Convert the normal cell into a table so we keep things similar 
allNormals = cell2table(allNormals);
allNormals = renamevars(allNormals,'allNormals1','Patient');
allNormals = renamevars(allNormals,'allNormals2','YawEar');
allNormals = renamevars(allNormals,'allNormals3','PitchEar');
allNormals = renamevars(allNormals,'allNormals4','RollEar');

% Merge comparison table with the allNormals table
comparisonTable = innerjoin(comparisonTable, allNormals);

% Calculate std weights again with the remaining subjects
weights_x = 1./comparisonTable.StdX;
weights_y = 1./comparisonTable.StdY;

% Calculate the same correlations with the ear rotations this time
x = comparisonTable.PitchEar; y = comparisonTable.MeanX;
fit = fitlm(x, y, 'linear', 'RobustOpts', 'on', 'weights', weights_x);
ci = fit.coefCI;
ci = ci(2,:);
fprintf('Ear pitch and horizontal nystagmus: R-squared = %2.2f slope[95%% CI] = %2.2f [%2.2f to %2.2f], p = %2.3f \n',fit.Rsquared.Adjusted,fit.Coefficients{2,1},ci,fit.coefTest)
% Plot
figHandle = figure();
tiledlayout(1,2,'TileSpacing','Compact','Padding','Compact');
figHandle.Renderer ='Painters';
set(gcf,'units','inches')
old_pos = get(gcf,'position'); 
set(gcf,'Position',[0 0 8.5 7])
subplot(1,2,1)
h = fit.plot;
h(1).Marker = 'o';
h(1).MarkerEdgeColor = 'none';
set(h,'LineWidth',1.5)
h(1).MarkerFaceColor = [0.5, 0.5, 0.5];
xlabel('Vestibular pitch')
ylabel('Horizontal slow phase velocity [deg/seg]')
legend off 
box off
ax = gca;
set(gca,'TickDir','out')
cbHandles = findobj(h,'DisplayName','Confidence bounds');
cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
set(cbHandles, 'LineWidth', 1, 'LineStyle', '--')
title(sprintf('slope [95%% CI] = %2.2f [%2.2f to %2.2f], p = %2.3f',fit.Coefficients{2,1},ci,fit.coefTest))

x = comparisonTable.RollEar; y = comparisonTable.MeanY;
fit = fitlm(x, y, 'linear', 'RobustOpts', 'on', 'weights', weights_y);
ci = fit.coefCI;
ci = ci(2,:);
fprintf('Ear roll and vertical nystagmus: R-squared = %2.2f slope[95%% CI] = %2.2f [%2.2f to %2.2f], p = %2.3f \n',fit.Rsquared.Adjusted,fit.Coefficients{2,1},ci,fit.coefTest)
% Plot
subplot(1,2,2)
h = fit.plot;
h(1).Marker = 'o';
h(1).MarkerEdgeColor = 'none';
set(h,'LineWidth',1.5)
h(1).MarkerFaceColor = [0.5, 0.5, 0.5];
xlabel('Vestibular roll')
ylabel('Vertical slow phase velocity [deg/seg]')
xline(0, '--')
legend off 
box off
ax = gca;
set(gca,'TickDir','out')
cbHandles = findobj(h,'DisplayName','Confidence bounds');
cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
set(cbHandles, 'LineWidth', 1, 'LineStyle', '--')
title(sprintf('slope [95%% CI] = %2.2f [%2.2f to %2.2f], p = %2.3f',fit.Coefficients{2,1},ci,fit.coefTest))
print(gcf,'vestibularAndNystagmus',"-dpdf","-bestfit")

% Find the correlations between head and vestibular rotations
x = comparisonTable.YawEar; y = -comparisonTable.Yaw;
fit = fitlm(x, y, 'RobustOpts', 'on');
figHandle = figure();
figHandle.Renderer ='Painters';
set(gcf,'units','inches')
old_pos = get(gcf,'position'); 
set(gcf,'Position',[0 0 8.5 7])
subplot(2,2,1)
h = fit.plot;
h(1).Marker = 'o';
h(1).MarkerEdgeColor = 'none';
set(h,'LineWidth',1.5)
h(1).MarkerFaceColor = [0.5, 0.5, 0.5];
xlabel('Vestibular yaw')
ylabel('Head yaw')
title('')
xlim([-10 10])
ylim([-10 10])
% refline([1 0])
legend off 
box off
axis square
ax = gca;
ax.TitleFontSizeMultiplier = 1;
ax.FontSize = 8;
set(gca,'TickDir','out')
cbHandles = findobj(h,'DisplayName','Confidence bounds');
cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
set(cbHandles, 'LineWidth', 1, 'LineStyle', '--')
title(sprintf('slope [95%% CI] = %2.2f [%2.2f to %2.2f], p = %2.3f',fit.Coefficients{2,1},ci,fit.coefTest))

x = comparisonTable.PitchEar; y = -comparisonTable.Pitch;
fit = fitlm(x, y, 'RobustOpts', 'on');
% Plot
subplot(2,2,2)
h = fit.plot;
h(1).Marker = 'o';
h(1).MarkerEdgeColor = 'none';
set(h,'LineWidth',1.5)
h(1).MarkerFaceColor = [0.5, 0.5, 0.5];
xlabel('Vestibular pitch')
ylabel('Head pitch')
xlim([-45 -15])
ylim([-20 10])
yticks(-20:10:20)
title('')
legend off
box off
axis square
ax = gca;
ax.TitleFontSizeMultiplier = 1;
ax.FontSize = 8;
set(gca,'TickDir','out')
cbHandles = findobj(h,'DisplayName','Confidence bounds');
cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
set(cbHandles, 'LineWidth', 1, 'LineStyle', '--')
title(sprintf('slope [95%% CI] = %2.2f [%2.2f to %2.2f], p = %2.3f',fit.Coefficients{2,1},ci,fit.coefTest))

x = comparisonTable.RollEar; y = comparisonTable.Roll;
fit = fitlm(x, y, 'RobustOpts', 'on');
subplot(2,2,3)
h = fit.plot;
h(1).Marker = 'o';
h(1).MarkerEdgeColor = 'none';
set(h,'LineWidth',1.5)
h(1).MarkerFaceColor = [0.5, 0.5, 0.5];
xlabel('Vestibular roll')
ylabel('Head roll')
xlim([-10 10])
ylim([-10 10])
% refline([1 0])
title('')
legend off
box off
axis square
ax = gca;
ax.TitleFontSizeMultiplier = 1;
ax.FontSize = 8;
set(gca,'TickDir','out')
cbHandles = findobj(h,'DisplayName','Confidence bounds');
cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
set(cbHandles, 'LineWidth', 1, 'LineStyle', '--')
title(sprintf('slope [95%% CI] = %2.2f [%2.2f to %2.2f], p = %2.3f',fit.Coefficients{2,1},ci,fit.coefTest))

%% Histograms
figHandle = figure();
figHandle.Renderer ='Painters';
subplot(3,1,1)
a = histogram(comparisonTable.PitchEar, 15, 'BinWidth', 1);
a.FaceColor = [0.5, 0.5, 0.5];
a.EdgeColor = [0.5, 0.5, 0.5];
a.EdgeAlpha = 0;
xlabel('Vestibular pitch [deg]')
ylabel('Number of subjects')
xlim([-45 -15])
ylim([0 10])
yticks(0:2:10)
box off
ax = gca;
set(gca,'TickDir','out')
subplot(3,1,2)
b = histogram(comparisonTable.RollEar, 10, 'BinWidth', 1);
b.FaceColor = [0.5, 0.5, 0.5];
b.EdgeColor = [0.5, 0.5, 0.5];
b.EdgeAlpha = 0;
xlabel('Vestibular roll [deg]')
ylabel('Number of subjects')
xlim([-15 15])
ylim([0 10])
yticks(0:2:10)
box off
ax = gca;
set(gca,'TickDir','out')
subplot(3,1,3)
c = histogram(comparisonTable.YawEar, 11, 'BinWidth', 1);
c.FaceColor = [0.5, 0.5, 0.5];
c.EdgeColor = [0.5, 0.5, 0.5];
c.EdgeAlpha = 0;
xlabel('Vestibular yaw [deg]')
ylabel('Number of subjects')
xlim([-15 15])
ylim([0 10])
yticks(0:2:10)
box off
ax = gca;
set(gca,'TickDir','out')