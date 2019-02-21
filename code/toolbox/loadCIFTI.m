function [ CIFTIMatrix ] = loadCIFTI(CIFTIFile, varargin)

%% Input parser
p = inputParser; p.KeepUnmatched = true;
p.addParameter('workbenchPath', '/Applications/workbench/bin_macosx64/', @ischar);
p.parse(varargin{:});


% load in smoothed gray-ordinate time series
% So we can load it into MATLAB
system(['bash ', p.Results.workbenchPath, 'wb_command -cifti-convert -to-text ', CIFTIFile, ' ', [CIFTIFile(1:end-9), '.txt']]);

CIFTIMatrix = readtable([CIFTIFile(1:end-9), '.txt'], 'ReadVariableNames', false);
CIFTIMatrix = table2array(CIFTIMatrix);

delete([CIFTIFile(1:end-9), '.txt']);

end
