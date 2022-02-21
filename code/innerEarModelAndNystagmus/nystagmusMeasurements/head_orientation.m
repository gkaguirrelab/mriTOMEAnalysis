function head_orientation(inputMatrix)
% Generates figure comparing head pitch and roll with horizontal and vertical SPV respectively
%
% Syntax:
%   head_orientation(inputMatrix)
%
% Inputs:
%   inputMatrix         - String Array. Generated by the function
%                         read_all_runs
%
% Outputs:
%   none                - PDF. Generates scatterplot of data for head
%                         orientation and SPV magnitude with linear fitting
%                         and 95% CI
%
% Example:  
%   head_orientation(resultsMatrix)

% Pulls mean for horizontal and vertical SPV
mean_run_x = str2double(inputMatrix(2:size(inputMatrix,1),18));
mean_run_y = str2double(inputMatrix(2:size(inputMatrix,1),20));
std_run_x = str2double(inputMatrix(2:size(inputMatrix,1),19));
std_run_y = str2double(inputMatrix(2:size(inputMatrix,1),21));
weights_x = 1./std_run_x;
weights_y = 1./std_run_y;
% Determine patients in inputMatrix
included_patients = str2double(inputMatrix(2:size(inputMatrix,1),1));

% Pulling head orientation data from file
orient = readtable("YPR_values.xls"); 
names = table2array(orient(:,1));
yaw = table2array(orient(:,2));
pitch = table2array(orient(:,3));
roll = table2array(orient(:,4));

% Cleaning up patient names
for i = 1:size(orient,1)
names(i) = extractAfter(names(i),"TOME_30");
end

% Determines which patients to include in the histogram
names = str2double(names);
included = ismember(names,included_patients);
% Identifies patient with missing head angle measurements
missingOrient = ismember(included_patients,names); 

% Deletes patients that are either missing head angle measurements or were
% excluded in read_all_runs
yaw(included == 0) = [];
pitch(included == 0) = [];
roll(included == 0) = [];
mean_run_x(missingOrient == 0) = [];
mean_run_y(missingOrient == 0) = [];
weights_x(missingOrient == 0) = [];
weights_y(missingOrient == 0) = [];

% Setting up figure 
means = [mean_run_x mean_run_y];
results = [pitch roll];
labelsOrient = ["Head pitch [deg]" "Head roll [deg]"];
labelsDir = ["Horizontal slow phase velocity [deg/sec]" "Vertical slow phase velocity [deg/sec]"];
weights = [weights_x weights_y];

figure;
tiledlayout(1,2,'TileSpacing','Compact','Padding','Compact');

for i = 1:2 % pitch, roll
tile = nexttile;
mdl = fitlm(results(:,i),means(:,i),'linear','RobustOpts','on');
% This creates the plot, and returns the plot handle, fit
fit = mdl.plot; 
% The commands below alter the appearance of the plot elements
fit(1).Marker = 'o';
fit(1).MarkerEdgeColor = 'none';
fit(1).MarkerFaceColor = [0.4 0.4 0.4];
fit(2).LineWidth = 2;
fit(3).LineStyle = '--';
fit(4).LineStyle = '--';

% Sets a line going through 0
xline(0,'--k');

% Formatting and labelling figure
set(gca, 'TickDir', 'out'); box off
ylabel(labelsDir(i))
xlabel(labelsOrient(i))
%title("")
legend(["Data" "Fit" "Confidence Bounds"],'Location','northeast')

%%% Code below for adding annotation of fit and confidence interval
ci = mdl.coefCI;
ci = ci(2,:);
str = sprintf('slope [95%% CI] = %2.2f [%2.2f to %2.2f], p = %2.3f',mdl.Coefficients{2,1},ci,mdl.coefTest);
title(str)
%position = get(tile,"Position");
%annotation("textbox","String",str,"EdgeColor","white","Position",[position(1)+0.15 position(2)-position(4)+0.65 position(3) position(4)],'FitBoxToText','on');
end

% Save figure as pdf
print(gcf,'Figure 3b',"-dpdf","-bestfit")
end
