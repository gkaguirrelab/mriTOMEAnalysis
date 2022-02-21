function read_all_runs() 
% Finds the median slope for all subjects' acquisitions
%
% Syntax:
%   [meanSpeed,SD] = find_slope(nameTag,variable,acquisition)
%
% Description:
%   This function removes all runs where NaN is greater than 65% of the
%   values or where 65% of the values are above the RMSE threshold. Any
%   patient with 2 or more runs removed is eliminated entirely. It then
%   iterates through the find_slope function for all remaining patients and
%   runs.
%
% Inputs:
%   none
%
% Outputs:
%   resultsMatrix         - String Array. Reports the mean velocity and
%                           RMSE for x and y for each patient and run. The
%                           four columns on the right report the mean of
%                           the mean velocities and the standard deviations
%                           of the mean velocities.

%Load in data and define paths
load gazeData.mat;
path1 = gazeData.rfMRI_REST_AP_run01;
path2 = gazeData.rfMRI_REST_PA_run02;
path3 = gazeData.rfMRI_REST_AP_run03;
path4 = gazeData.rfMRI_REST_PA_run04;

% Find all the rows for each acquisition where NaN is >65% of values
f1 = find(sum(isnan(path1.vq(:,1,:)),3)./20160>0.65);
f2 = find(sum(isnan(path2.vq(:,1,:)),3)./20160>0.65);
f3 = find(sum(isnan(path3.vq(:,1,:)),3)./20160>0.65);
f4 = find(sum(isnan(path4.vq(:,1,:)),3)./20160>0.65);

% Find all rows where each acquisition has >65% bad values as defined by
% RMSE
f1 = [zeros(45,1);f1];
f2 = [zeros(45,1);f2];
f3 = [zeros(45,1);f3];
f4 = [zeros(45,1);f4];

path = [path1 path2 path3 path4];

for j = 1:4
for i = 1:size(path(j).nameTags,2)
    sumNaNx = clean(path(j).nameTags(i),1,path(j));
    sumNaNy = clean(path(j).nameTags(i),2,path(j));
    if (sumNaNx == 1 || sumNaNy == 1) && j ==1
        f1(i) = i;
    elseif (sumNaNx == 1 || sumNaNy == 1) && j ==2
        f2(i) = i;
    elseif (sumNaNx == 1 || sumNaNy == 1) && j ==3
        f3(i) = i;
    elseif (sumNaNx == 1 || sumNaNy == 1) && j ==4
        f4(i) = i;
    end
end
end

f1 = sort(unique(f1));
f2 = sort(unique(f2));
f3 = sort(unique(f3));
f4 = sort(unique(f4));
f1(1) = [];
f2(1) = [];
f3(1) = [];
f4(1) = [];

% This adjustment is because patient 12 does not have a run 4, so it
% temporarily shifts all patients after that by 1.
temp_f4 = zeros(size(f4));
for i = 1:size(f4,1) 
    if f4(i) > 9
        temp_f4(i) = f4(i) + 1;
    else
        temp_f4(i) = f4(i);
    end
end

% Eliminate all patients who have 2 or more acquisitions that are bad
badRows = horzcat(sort(unique(vertcat(f1,f2,f3,temp_f4))), groupcounts(vertcat(f1,f2,f3,temp_f4)));
badRows = badRows(badRows(:,2)>1,1);
f1 = sort(unique(vertcat(f1,badRows)));
f2 = sort(unique(vertcat(f2,badRows)));
f3 = sort(unique(vertcat(f3,badRows)));

% An adjustment made to shift some of the patients for acquistion 4 back to
% normal
temp_badRows = zeros(size(badRows));
for i = 1:size(badRows,1)
    if badRows(i) > 9
        temp_badRows(i) = badRows(i) - 1;
    else
        temp_badRows(i) = badRows(i);
    end
end

f4 = sort(unique([f4;temp_badRows]));

path1.nameTags(f1) = [];
path1.vq(f1,:,:) = [];
path1.RMSE(f1,:) = [];
path2.nameTags(f2) = [];
path2.vq(f2,:,:) = [];
path2.RMSE(f2,:) = [];
path3.nameTags(f3) = [];
path3.vq(f3,:,:) = [];
path3.RMSE(f3,:) = [];
path4.nameTags(f4) = [];
path4.vq(f4,:,:) = [];
path4.RMSE(f4,:) = [];

% Total list of unique runs across all 4 acquisitions
keptRuns = unique(horzcat(path1.nameTags,path2.nameTags,path3.nameTags,path4.nameTags));

% Run 1
resultsMatrix=["Patient","run1_x","run1_x_var","run1_y","run1_y_var","run2_x","run2_x_var","run2_y","run2_y_var",...
    "run3_x","run3_x_var","run3_y","run3_y_var","run4_x","run4_x_var","run4_y","run4_y_var"];
resultsMatrix = [resultsMatrix;NaN(size(keptRuns,2),17)];
resultsMatrix(:,1) = vertcat("Patient", keptRuns');
numPatients = size(path1.nameTags,2);
    for i = 1:numPatients
        [meanSpeed_x,SD_x,eligible_x] = find_slope(path1.nameTags(i),1,path1);
        [meanSpeed_y,SD_y,eligible_y] = find_slope(path1.nameTags(i),2,path1);
        rowToChange = resultsMatrix(:,1) == path1.nameTags(i);
        if eligible_x ==1 && eligible_y == 1
        resultsMatrix(rowToChange,2:5) = [meanSpeed_x,SD_x,meanSpeed_y,SD_y];
        else
        continue
        end
    end
     
% Run 2
numPatients = size(path2.nameTags,2);
    for i = 1:numPatients
        [meanSpeed_x,SD_x,eligible_x] = find_slope(path2.nameTags(i),1,path2);
        [meanSpeed_y,SD_y,eligible_y] = find_slope(path2.nameTags(i),2,path2);
        rowToChange = resultsMatrix(:,1) == path2.nameTags(i);
        if eligible_x ==1 && eligible_y == 1
        resultsMatrix(rowToChange,6:9) = [meanSpeed_x,SD_x,meanSpeed_y,SD_y];
        else
        continue
        end
    end
 
% Run 3
numPatients = size(path3.nameTags,2);
    for i = 1:numPatients
        [meanSpeed_x,SD_x,eligible_x] = find_slope(path3.nameTags(i),1,path3);
        [meanSpeed_y,SD_y,eligible_y] = find_slope(path3.nameTags(i),2,path3);
        rowToChange = resultsMatrix(:,1) == path3.nameTags(i);
        if eligible_x ==1 && eligible_y == 1
        resultsMatrix(rowToChange,10:13) = [meanSpeed_x,SD_x,meanSpeed_y,SD_y];
        else
        continue
        end
    end
 
% Run 4
numPatients = size(path4.nameTags,2);
    for i = 1:numPatients
        [meanSpeed_x,SD_x,eligible_x] = find_slope(path4.nameTags(i),1,path4);
        [meanSpeed_y,SD_y,eligible_y] = find_slope(path4.nameTags(i),2,path4);
        rowToChange = resultsMatrix(:,1) == path4.nameTags(i);
        if eligible_x ==1 && eligible_y == 1
        resultsMatrix(rowToChange,14:17) = [meanSpeed_x,SD_x,meanSpeed_y,SD_y];
        else
        continue
        end
    end

% % Since patient 4 has two name tas, shift patient 4 if included into one
% % patient
% [~,patient] = ismember("04_101416",resultsMatrix(:,1));
% if patient >0
%     resultsMatrix(patient-1,10:17) = resultsMatrix(patient,10:17);
%     resultsMatrix(patient,:) = [];
% end
[~,patient] = ismember("04_101416",resultsMatrix(:,1));
if patient >0
    resultsMatrix(patient-1,:) = [];
    resultsMatrix(patient-1,:) = [];
end

% Calculates the means and standard deviations of the mean velocities for
% each patient
temp = zeros(size(resultsMatrix,1)-1,4);
temp(1,:) = ["Mean X", "Std X", "Mean Y", "Std Y"];
for i = 2:size(resultsMatrix,1)
    tempArray = [str2double(resultsMatrix(i,2)),str2double(resultsMatrix(i,6)),str2double(resultsMatrix(i,10)),str2double(resultsMatrix(i,14))];
    temp_x_mean = mean(nonzeros(tempArray),"omitnan");
    temp_x_SD = std(nonzeros(tempArray),"omitnan");
    tempArray = [str2double(resultsMatrix(i,4)),str2double(resultsMatrix(i,8)),str2double(resultsMatrix(i,12)),str2double(resultsMatrix(i,16))];
    temp_y_mean = mean(nonzeros(tempArray),"omitnan");
    temp_y_SD = std(nonzeros(tempArray),"omitnan");
    temp(i,:) = [temp_x_mean,temp_x_SD,temp_y_mean,temp_y_SD];
end

resultsMatrix = [resultsMatrix,temp];
resultsMatrix(1,18:21) = ["Mean X", "Std X", "Mean Y", "Std Y"];

% Remove dates from nameTags
for i = 2:size(resultsMatrix,1)
    resultsMatrix(1:i) = str2double(strtok(resultsMatrix(1:i),"_"));
end

for i = size(resultsMatrix,1):-1:2
    x = str2double(resultsMatrix(i,2:end));
    if length(x(~isnan(x))) > 12
        continue
    else
        resultsMatrix(i,:) = [];
    end
end

resultsMatrix(1,1) = "Patient";

assignin('base',"resultsMatrix",resultsMatrix);
end
