function find_slope_example
% Plots data from patient 8, acquisition 1 as an example of the find_slope
% program
%
% Syntax:
%   find_slope_example
%
% Inputs:
%   none
%
% Outputs:
%   none                  - Figure. Returns plot of original data,
%                           segmented data and linear fitting.
%
% Examples:
%	find_slope_example

load gazeData.mat;
path1 = gazeData.rfMRI_REST_AP_run01;
fig1 = figure;
tiledlayout(2,1,'TileSpacing','Compact','Padding','Compact')
labels = (["Horizontal position [deg]" "Vertical position [deg]"]);

for i = 1:2 % x, y
nexttile;
find_slope_plotted('08_102116',i,path1)
ylabel(labels(i))
xlabel("Time [s]")
xlim([1e5 2e5])
legend(["Original Data" "Segmentation" "Linear Fit"],"location","northwest")
set(gca, 'TickDir', 'out'); box off
pbaspect([1.5 1 1])
end

fig1.Renderer='Painters';
print(gcf,'Figure 1',"-dpdf","-fillpage")
end