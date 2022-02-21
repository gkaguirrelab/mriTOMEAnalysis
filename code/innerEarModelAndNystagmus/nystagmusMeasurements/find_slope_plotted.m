function find_slope_plotted(nameTag,variable,acquisition)
% Plots results from find_slope
%
% Syntax:
%   find_slope_plotted(nameTag,variable,acquisition)
%
% Description:
%   This function first cleans the data by removing any point with a RMSE
%   above the threshold or with a speed greater than the set max speed
%   threshold. It then uses ischange to separate the time points into
%   chunks based on changes in movement. For chunks larger than the
%   chunkThreshold, it reapplies ischange once again but this time with a
%   smaller threshold. It takes the median slope and removes the 5% of
%   chunks with the highest RMSEs. This cycle is repeated 10 times and
%   final figure is plotted.

% Inputs:
%   nameTag               - String. Must match one of the name tags in the
%                           gazeData nameTags cell.
%   variable              - Integer. Use 1 for assessing movement in the x
%                           direction, otherwise use 2 for y movement
%   acquisition           - Variable. The options are the four paths
%                           (path1, path2, path3, or path4). They are
%                           defined in read_all_runs.
%
% Outputs:
%   none                  - Figure. Returns plot of original data,
%                           segmented data and linear fitting.

% Examples:
%	find_slope_plotted("01_081916",1,path1);


load gazeData.mat;

allData = permute(acquisition.vq,[3 2 1]);
[~, RowNumber] = ismember(nameTag,acquisition.nameTags);
run = allData(:,:,RowNumber);
time_original = gazeData.timebase.';
time_good = time_original;

% Remove threshold with low confidence
rmseThreshold = 2.25;
RMSE = acquisition.RMSE.';
RMSE = RMSE(:,RowNumber);
highRMSE = RMSE > rmseThreshold;
fitAtBound = false(size(highRMSE));
if isfield(run,'fitAtBound')
    fitAtBound = run.fitAtBound;
end
goodIdx = logical(~highRMSE .* ~fitAtBound);

x_original = run(:,variable);
x_good = x_original;

x_good(goodIdx == 0) = NaN;
time_good(isnan(x_good)) = NaN;

% Parameter for max speed
max_deg_per_sec = 100;
max_deg_per_frame = max_deg_per_sec/60;

% Defines speed and removes if speed > max_deg_per_frame
speed=diff(x_good)./diff(time_good);
speed=vertcat(zeros(1,1),speed);
time_good(speed > max_deg_per_frame)= NaN;
time_good(speed < -max_deg_per_frame)= NaN;
x_good(speed > max_deg_per_frame)= NaN;
x_good(speed < -max_deg_per_frame)= NaN;

combine_x = horzcat(time_good,x_good);
combine_x = combine_x(all(~isnan(combine_x),2),:);


for i = 1:10 % Number of iterations
%%%%%%%
% Generating best guess of slope
[TF,S1,~] = ischange(combine_x(:,2),'linear','Threshold',10); %10
smallSlopes = unique(S1(abs(S1) < 2));
%tempSlope = median(smallSlopes)/(max(time_good)/size(time_good,1));
tempSlope = median(smallSlopes)/16;
combine_x = horzcat(combine_x,TF);

% Forms cell by separating into arrays based on TF values
idx = combine_x(:,3);
idr = diff(find([1;diff(idx);1]));
combined_C = mat2cell(combine_x,idr(:),size(combine_x,2));
combined_C(cellfun('length',combined_C)<4) = [];

subset = 1;

% Repeats the same separation process for chunks that are greater than the
% chunkThreshold

% for j = 1:size(combined_C,1)
%         new_C{subset,1} = combined_C{j};
%         subset = subset+1;
% end

chunkThreshold = 100; %50
for j = 1:size(combined_C,1)
    if size(combined_C{j}(:,1),1) < chunkThreshold
        new_C{subset,1} = combined_C{j};
        subset = subset+1;
    else 
        [TFb,~,~] = ischange(combined_C{j}(:,1),'linear','Threshold',5);
        tempC = combined_C{j}(:,1:end-1);
        combine_x = horzcat(tempC,TFb);
        idx = combine_x(:,3);
        idr = diff(find([1;diff(idx);1]));       
        small_temp_C{1} = mat2cell(combine_x,idr(:),size(combine_x,2));
        small_temp_C{1}(cellfun('length',small_temp_C{1})<1) = [];
        for s = 1:size(small_temp_C{1,1},1)
            if size(small_temp_C{1}{s},1) > 2
               new_C{subset,1} = small_temp_C{1}{s};
               subset = subset+1;
            end
        end
    end
end

% Assessing fit of each chunk
RMSE = zeros(size(new_C,1),1);
for j = 1:size(new_C,1)
    tempIntercept = mean(new_C{j}(:,2))-mean(new_C{j}(:,1))*tempSlope; %y-m*time= b
    mov_mean = movmean(new_C{j},3);

%calculating RMSE
    yresidA = zeros(size(new_C{j},1),1);
    for k = 1:size(new_C{j},1) 
        yfit = tempSlope*mov_mean(k,1)+tempIntercept;
        yresid = (mov_mean(k,2)-yfit)^2;
        yresidA(k)= yresid;
    end
    
    chunkRMSE = sum(yresidA)/size(new_C{j},1);
    RMSE(j) = chunkRMSE;  
end

if i == 10
    continue;
%Removing chunks associated with worst RMSE values
else
worstRMSE = maxk(RMSE,floor(size(RMSE,1)/40));
new_C(ismember(RMSE,worstRMSE)) = [];
end

% Prepping for next cycle
C = cat(1,new_C{:});
good_values = ismember(time_good,C);
time_good = time_good(good_values);
x_good = x_good(good_values);
combine_x = horzcat(time_good,x_good);
end

% % Plot showing the original velocity, the points chosen by the algorithm
% % and the slope mapping to each chunk
plot(time_original, x_original,'Color','#C0C0C0'); hold on
newplot = NaN(length(time_original),1);
[~,include] = ismember(time_good,time_original);
newplot(include) = x_good;
plot(time_original, newplot,'Color','b');

for e = 1:size(new_C,1)
    tempIntercept = mean(new_C{e}(:,2))-mean(new_C{e}(:,1))*tempSlope; %x-m*time= b
    a_init = new_C{e}(1,1);
    a_end = new_C{e}(end,1);
    time_plot = a_init:0.025:a_end;
    x = tempSlope*(time_plot)+tempIntercept;
    plot(time_plot,x,'LineStyle','-','Color','r','LineWidth',1.5); hold on
end

set(gca, 'XTick',get(gca, 'XTick'), 'XTickLabel',get(gca, 'XTick')/1000)
end