%% Cammille correlations 
% Set the code directory after tbUse
currentDirectory = pwd; 

% Set the bootstrapping sample size
bootN = 100;

% Read YPR table, rename the first variable to 'Patient'
ypr = readtable(fullfile(currentDirectory, 'code', 'innerEarModel', 'Cammille_results', 'YPR_values.xls'));
ypr = renamevars(ypr,'Var1','Patient');

% Read the nystagmus table and only retain the meanX and meanY columns 
nystagmus = readtable(fullfile(currentDirectory, 'code', 'innerEarModel', 'Cammille_results', 'ResultsMatrix.xlsx'));
nystagmus(:,2:17) = []; nystagmus(:,3) = []; nystagmus(:,4) = [];

% Create a comparison table by combining two tables by the common rows
comparisonTable = innerjoin(ypr, nystagmus);

% Get the correlation between horizontal vs pitch and vertical vs roll
x = comparisonTable.MeanX; y = comparisonTable.Pitch;
[r,p] = corrcoef(x, y);
modelcorr = @(x,y) corr(x,y);
CI = bootci(bootN,{modelcorr,x,y});
fprintf(['Correlation between pitch and horizontal nystagmus is r:' num2str(r(2)) ', CI(95%%) LB:' num2str(CI(1)) ' UB:' num2str(CI(2)) ', p:' num2str(p(2)) '\n'])

x = comparisonTable.MeanY; y = comparisonTable.Roll;
[r,p] = corrcoef(x, y);
modelcorr = @(x,y) corr(x,y);
CI = bootci(bootN,{modelcorr,x,y});
fprintf(['Correlation between roll and vertical nystagmus is r:' num2str(r(2)) ', CI(95%%) LB:' num2str(CI(1)) ' UB:' num2str(CI(2)) ', p:' num2str(p(2)) '\n\n'])

%% Inner ear correlations 
% Download the inner ear files
innerEarLoc = fullfile(currentDirectory, 'code', 'innerEarModel', 'Cammille_results', 'innerEarNormals');
if ~isfolder(innerEarLoc)
    fprintf('Downloading inner ear normals.') 
    downloadSubjectNormals(innerEarLoc)
end

% Set the inner ear model
anteriorLeft = [1 0 0];
anteriorRight = [-1 0 0];
posteriorLeft = [0 1 0];
posteriorRight = [0 1 0];
lateralLeft = [0 0 1];
lateralRight = [0 0 1];

% Find the normal paths and set an empty cell for saving
folders = dir(innerEarLoc);
folders(1:2) = [];
allNormals = {};

% Set a subject counter for the loop (very roundabout way of counting how
% many subjects we have) and initiate zero matrices for saving.
subjectNum = 0;
avg = zeros(3,6);
avgAfter = zeros(3,6);

% Loop through subjects
figHandle = figure();
figHandle.Renderer ='Painters';
for ii = 1:length(folders)
    
    % Remove tome 3009 and 3029 as registration didn't work for these
    if ~strcmp(folders(ii).name, 'TOME_3009') || ~strcmp(folders(ii).name, 'TOME_3029')
        
        % Load normals
        [lateralMRILeft, lateralMRIRight, anteriorMRILeft, anteriorMRIRight, ...
         posteriorMRILeft, posteriorMRIRight] = loadMRINormals(fullfile(folders(ii).folder,folders(ii).name));

        Sub = [lateralMRILeft, lateralMRIRight, anteriorMRILeft, anteriorMRIRight, posteriorMRILeft, posteriorMRIRight];
        Temp = [lateralLeft', lateralRight', anteriorLeft', anteriorRight', posteriorLeft', posteriorRight'];

        % Add to avg 
        avg = avg + Sub;
        subjectNum = subjectNum + 1;

        % Calculate centroids 
        centroidSub = mean(Sub,2);
        centroidTemp = mean(Temp,2);

        % Calculate familiar covariance 
        H = (Temp - centroidTemp)*(Sub - centroidSub)';

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

        % Sqrt of sum of square angles
        lateralLeftAngle = rad2deg(atan2(norm(cross(lateralMRILeftNew,lateralLeft)), dot(lateralMRILeftNew,lateralLeft)));
        lateralRightAngle = rad2deg(atan2(norm(cross(lateralMRIRightNew,lateralRight)), dot(lateralMRIRightNew,lateralRight)));
        anteriorLeftAngle = rad2deg(atan2(norm(cross(anteriorMRILeftNew,anteriorLeft)), dot(anteriorMRILeftNew,anteriorLeft)));
        anteriorRightAngle = rad2deg(atan2(norm(cross(anteriorMRIRightNew,anteriorRight)), dot(anteriorMRIRightNew,anteriorRight)));
        posteriorLeftAngle = rad2deg(atan2(norm(cross(posteriorMRILeftNew,posteriorLeft)), dot(posteriorMRILeftNew,posteriorLeft)));
        posteriorRightAngle = rad2deg(atan2(norm(cross(posteriorMRIRightNew,posteriorRight)), dot(posteriorMRIRightNew,posteriorRight)));
        errorMetric = sqrt(lateralLeftAngle^2 + lateralRightAngle^2 + anteriorLeftAngle^2 + anteriorRightAngle^2 + posteriorLeftAngle^2 + posteriorRightAngle^2);
        allNormals{ii, 5} = errorMetric; 
        
        subNew = [lateralMRILeftNew, lateralMRIRightNew, ...
                  anteriorMRILeftNew, anteriorMRIRightNew, ...
                  posteriorMRILeftNew, posteriorMRIRightNew];
        avgAfter = avgAfter + subNew;

        plotMRINormals(lateralMRILeftNew, lateralMRIRightNew, ...
                            anteriorMRILeftNew, anteriorMRIRightNew, ...
                            posteriorMRILeftNew, posteriorMRIRightNew, false, false)
        hold on
    end
end
view(-130.8370,20.3106)    


SubAvg = avg / subjectNum;
SubAfterAvg = avgAfter / subjectNum;
plotMRINormals(SubAvg(:,1), SubAvg(:,2), ...
               SubAvg(:,3), SubAvg(:,4), ...
               SubAvg(:,5), SubAvg(:,6), true, false)
hold on
plotMRINormals(SubAfterAvg(:,1), SubAfterAvg(:,2), ...
               SubAfterAvg(:,3), SubAfterAvg(:,4), ...
               SubAfterAvg(:,5), SubAfterAvg(:,6), false, true)  

% Convert the normal cell into a table so we keep things similar 
allNormals = cell2table(allNormals);
allNormals = renamevars(allNormals,'allNormals1','Patient');
allNormals = renamevars(allNormals,'allNormals2','YawEar');
allNormals = renamevars(allNormals,'allNormals3','PitchEar');
allNormals = renamevars(allNormals,'allNormals4','RollEar');
allNormals = renamevars(allNormals,'allNormals5','fitError');

% Merge comparison table with the allNormals table
comparisonTable = innerjoin(comparisonTable, allNormals);

% Calculate the same correlations with the ear rotations this time
x = comparisonTable.MeanX; y = comparisonTable.PitchEar;
[r,p] = corrcoef(x, y);
modelcorr = @(x,y) corr(x,y);
CI = bootci(bootN,{modelcorr,x,y});
fprintf(['Correlation between ear pitch and horizontal nystagmus is r:' num2str(r(2)) ', CI(95%%) LB:' num2str(CI(1)) ' UB:' num2str(CI(2)) ', p:' num2str(p(2)) '\n'])
% combined = [x y];
% fitError = comparisonTable.fitError;
% r = weightedcorrs(combined, fitError);
% modelcorr = @(combined,fitError) weightedcorrs(combined,fitError);
% CI = bootci(bootN,{modelcorr,combined,fitError});
% fprintf(['Correlation between ear pitch and horizontal nystagmus with errorWeighting is r:' num2str(r(2)) ', CI(95%%) LB:' num2str(CI(1,1,2)) ' UB:' num2str(CI(2,1,2)) '\n'])
% Plot
fit = fitlm(y, x);
figHandle = figure();
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
title('')
legend off 
box off
ax = gca;
set(gca,'TickDir','out')
cbHandles = findobj(h,'DisplayName','Confidence bounds');
cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
set(cbHandles, 'LineWidth', 1, 'LineStyle', '--')

x = comparisonTable.MeanY; y = comparisonTable.RollEar;
[r,p] = corrcoef(x, y);
modelcorr = @(x,y) corr(x,y);
CI = bootci(bootN,{modelcorr,x,y});
fprintf(['Correlation between ear roll and vertical nystagmus is r:' num2str(r(2)) ', CI(95%%) LB:' num2str(CI(1)) ' UB:' num2str(CI(2)) ', p:' num2str(p(2)) '\n\n']) 
% combined = [x y];
% fitError = comparisonTable.fitError;
% r = weightedcorrs(combined, fitError);
% modelcorr = @(combined,fitError) weightedcorrs(combined,fitError);
% CI = bootci(bootN,{modelcorr,combined,fitError});
% fprintf(['Correlation between ear roll and vertical nystagmus with errorWeighting is r:' num2str(r(2)) ', CI(95%%) LB:' num2str(CI(1,1,2)) ' UB:' num2str(CI(2,1,2)) '\n'])
% Plot
fit = fitlm(y, x);
subplot(1,2,2)
h = fit.plot;
h(1).Marker = 'o';
h(1).MarkerEdgeColor = 'none';
set(h,'LineWidth',1.5)
h(1).MarkerFaceColor = [0.5, 0.5, 0.5];
xlabel('Vestibular roll')
ylabel('Vertical slow phase velocity [deg/seg]')
title('')
xline(0, '--')
legend off 
box off
ax = gca;
set(gca,'TickDir','out')
cbHandles = findobj(h,'DisplayName','Confidence bounds');
cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
set(cbHandles, 'LineWidth', 1, 'LineStyle', '--')

% Find the correlations between head and vestibular rotations
x = -comparisonTable.Yaw; y = comparisonTable.YawEar;
[r,p] = corrcoef(x, y);
modelcorr = @(x,y) corr(x,y);
CI = bootci(bootN,{modelcorr,x,y});
fprintf(['Correlation between ear yaw and head yaw is r:' num2str(r(2)) ', CI(95%%) LB:' num2str(CI(1)) ' UB:' num2str(CI(2)) ', p:' num2str(p(2)) '\n']) 
fit = fitlm(y, x);
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
set(gca,'TickDir','out')
cbHandles = findobj(h,'DisplayName','Confidence bounds');
cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
set(cbHandles, 'LineWidth', 1, 'LineStyle', '--')

x = -comparisonTable.Pitch; y = comparisonTable.PitchEar;
[r,p] = corrcoef(x, y);
modelcorr = @(x,y) corr(x,y);
CI = bootci(bootN,{modelcorr,x,y});
fprintf(['Correlation between ear pitch and head pitch is r:' num2str(r(2)) ', CI(95%%) LB:' num2str(CI(1)) ' UB:' num2str(CI(2)) ', p:' num2str(p(2)) '\n']) 
fit = fitlm(y, x);
% Plot
subplot(2,2,2)
h = fit.plot;
h(1).Marker = 'o';
h(1).MarkerEdgeColor = 'none';
set(h,'LineWidth',1.5)
h(1).MarkerFaceColor = [0.5, 0.5, 0.5];
xlabel('Vestibular pitch')
ylabel('Head pitch')
xlim([-55 -15])
ylim([-20 20])
% yticks(-30:10:10)
title('')
legend off
box off
axis square
ax = gca;
set(gca,'TickDir','out')
cbHandles = findobj(h,'DisplayName','Confidence bounds');
cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
set(cbHandles, 'LineWidth', 1, 'LineStyle', '--')

x = comparisonTable.Roll; y = comparisonTable.RollEar;
[r,p] = corrcoef(x, y);
modelcorr = @(x,y) corr(x,y);
CI = bootci(bootN,{modelcorr,x,y});
fprintf(['Correlation between ear roll and head roll is r:' num2str(r(2)) ', CI(95%%) LB:' num2str(CI(1)) ' UB:' num2str(CI(2)) ', p:' num2str(p(2)) '\n']) 
fit = fitlm(y, x);
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
set(gca,'TickDir','out')
cbHandles = findobj(h,'DisplayName','Confidence bounds');
cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
set(cbHandles, 'LineWidth', 1, 'LineStyle', '--')

% Histograms
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