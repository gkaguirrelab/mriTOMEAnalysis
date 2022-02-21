function [sumNaN] = clean(nameTag,variable,acquisition)
% Checks to see if there is less than 65% of bad points as defined by the RMSE threshold
%
% Syntax:
%   [sumNaN] = myFunc(input)
%
% Inputs:
%   nameTag               - String. Must match one of the name tags in the
%                           gazeData nameTags cell.
%   variable              - Integer. Use 1 for assessing movement in the x
%                           direction, otherwise use 2 for y movement
%   acquisition           - Variable. The options are the four paths
%                           (path1, path2, path3, or path4). They are
%                           defined in read_is_change_files.
%
% Outputs:
%   sumNaN                - logical. Returns 1 if the number of "bad"
%                           points is greater than 65%, otherwise a 0.
%
% Examples:
%	sumNaNx = clean(path1.nameTags(1),1,path2);
% This would return 1 if the > 65% of the x movement of patient 1 in their
% second acquisition had a RMSE higher than the threshold

% Loads data
load gazeData.mat;

allData = permute(acquisition.vq,[3 2 1]);
[~, RowNumber] = ismember(nameTag,acquisition.nameTags);
run = allData(:,:,RowNumber);
time_original = gazeData.timebase.';
time_good = time_original;

% Remove points with low confidence (above the rmseThershold)
rmseThreshold = 2.25;
RMSE = acquisition.RMSE.';
RMSE = RMSE(:,RowNumber);
highRMSE = RMSE > rmseThreshold;
fitAtBound = false(size(highRMSE));
if isfield(run,'fitAtBound')
    fitAtBound = run.fitAtBound;
end
goodIdx = logical(~highRMSE .* ~fitAtBound);

position = run(:,variable);

position(goodIdx == 0) = NaN;
time_good(isnan(position)) = NaN;

% Parameter for max speed
max_deg_per_sec = 100;
max_deg_per_frame = max_deg_per_sec/60;

% Defines speed and removes if speed > max_deg_per_frame
speed=diff(position)./diff(time_good);
speed=vertcat(zeros(1,1),speed);
time_good(speed > max_deg_per_frame)= NaN;
time_good(speed < -max_deg_per_frame)= NaN;

sumNaN = sum(isnan(time_good))./20160>0.80;
end
