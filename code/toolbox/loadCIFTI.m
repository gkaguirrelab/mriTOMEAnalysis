function [ CIFTIMatrix ] = loadCIFTI(CIFTIFile, varargin)
% Load CIFTI file into MATLAB as a matrix
%
% Syntax:
%  [ CIFTIMatrix ] = loadCIFTI(CIFTIFile)
%
% Description:
%  This routine converts the CIFTI into a text file, and then has MATLAB
%  read in that textfile as a matrix. Each row of the matrix corresponds to
%  a different grayordinate. This routine requires the HCP workbench
%  package.
%
% Inputs:
%  CIFTIFile             - a string that specifies the full path to the
%                          CIFTI file to be loaded
%
% Optional key-value pairs:
%  workbenchPath         - a string that defines the full path to where
%                          workbench commands can be found.
%
% Outputs:
%  grayordinates         - an m x n matrix, where m is the number of
%                          grayordinates and n is the number of time points
%                          in the acquisition (or whatever value, such as
%                          R2 stashed for that grayordinate)

%% Input parser
p = inputParser; p.KeepUnmatched = true;
p.addParameter('workbenchPath', '/Applications/workbench/bin_macosx64/', @ischar);
p.parse(varargin{:});


%% Load in smoothed gray-ordinate time series
% So we can load it into MATLAB
system(['bash ', p.Results.workbenchPath, 'wb_command -cifti-convert -to-text ', CIFTIFile, ' ', [CIFTIFile(1:end-9), '.txt']]);

CIFTIMatrix = readtable([CIFTIFile(1:end-9), '.txt'], 'ReadVariableNames', false);
CIFTIMatrix = table2array(CIFTIMatrix);

delete([CIFTIFile(1:end-9), '.txt']);

end
