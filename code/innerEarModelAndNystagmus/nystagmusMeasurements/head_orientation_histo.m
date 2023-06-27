function head_orientation_histo(inputMatrix)
% Generates histogram of head pitch, roll, and yaw
%
% Syntax:
%   head_orientation_histo(inputMatrix)
%
% Inputs:
%   inputMatrix         - String Array. Generated by the function
%                         read_all_runs
%
% Outputs:
%   none                - PDF. Generates histogram for head orientation
%
% Example:  
%   head_orientation_histo(resultsMatrix)

% Pulls mean for horizontal and vertical SPV
mean_run_x = str2double(inputMatrix(2:size(inputMatrix,1),18));
mean_run_y = str2double(inputMatrix(2:size(inputMatrix,1),20));
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

results = [pitch roll yaw];
labels = ["Head pitch [deg]" "Head roll [deg]" "Head yaw [deg]"];

% Creates layout of figure
figure;
tiledlayout(3,1,'TileSpacing','Compact','Padding','Compact');

% Generates figure
for i = 1:3 % pitch, roll, yaw
fig(i) = nexttile;
histogram(results(:,i),'binmethod','integers',"facecolor",[0.3 0.3 0.3],"edgecolor","none");
maxOrient = ceil(max([yaw;pitch;roll])/5)*5; % Round to 5 the max value among pitch, roll, yaw
xlim([-maxOrient maxOrient]) %Sets prior value to the x limit
xlabel(labels(i))
set(gca, 'TickDir', 'out'); box off
end

linkaxes([fig(1) fig(2) fig(3)]) % Forces same y axes

% Saves figure as pdf
print(gcf,'Figure 3a',"-dpdf","-fillpage")
end