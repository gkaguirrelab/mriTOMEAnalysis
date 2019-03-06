function [grayordinates] = smoothCIFTI(functionalFile, varargin)
% Smooth fMRI grayordinates using Gaussian kernel
%
% Syntax:
%  smoothVolume(functionalFile)
%
% Description:
%  This routine uses HCP's workbench to perform spatial smoothing on the
%  inputted fMRI CIFTI file. Right now this is very simple smoothing in
%  which we apply a Gaussian kernel over both the cortical surface and
%  subcortical volume.
%
% Inputs:
%  functionalFile        - a string that specifies the full path to the
%                          functional cifti file to be smoothed
%
% Optional key-value pairs:
%  surfaceKernelFWHMmm   - a number that defines the full width at half
%                          maximum of the Gaussian kernel, in mm, to
%                          perform the smoothing with on the cortical
%                          surface
%  volumeKernelFWHMmm    - same as above, bot for the subcortical volume
%  savePath              - a string that specifies where to save out the
%                          smoothed volume. If empty, the default, then it
%                          will save in the same location as the inputted
%                          functional volume
%  workbenchPath         - a string that defines the full path to where
%                          workbench commands can be found.
%
% Outputs:
%  grayordinates         - an m x n matrix, where m is the number of
%                          grayordinates and n is the number of time points
%                          in the acquisition


%% Input parser
p = inputParser; p.KeepUnmatched = true;
p.addParameter('surfaceKernelFWHMmm',5, @isnum);
p.addParameter('volumeKernelFWHMmm',2.5, @isnum);
p.addParameter('workbenchPath', '/Applications/workbench/bin_macosx64/', @ischar);
p.addParameter('savePath',[], @isstring);
p.parse(varargin{:});

%% Determine where to save out results
if isempty(p.Results.savePath)
    [ savePath, fileName ] = fileparts(functionalFile);
else
    savePath = p.Results.savePath;
end

smoothedFile = fullfile(savePath, [fileName(1:end-9), '_smoothed.dtseries.nii']);

%% Convert the FWHM of the Guassian kernel to its sigma
% workbench takes in the sigma value in its function, so we convert the FWHM into
% sigma
sigmaSurface = p.Results.surfaceKernelFWHMmm/(2*(2*log(2))^0.5);
sigmaVolume = p.Results.volumeKernelFWHMmm/(2*(2*log(2))^0.5);


%% Perform the smoothing
system([p.Results.workbenchPath, 'wb_command -cifti-smoothing "' functionalFile, '" ', num2str(sigmaSurface), ' ', num2str(sigmaVolume), ' COLUMN "' smoothedFile, '" -left-surface "', fullfile(savePath, 'L.midthickness.32k_fs_LR.surf.gii'), '" -right-surface "', fullfile(savePath, 'R.midthickness.32k_fs_LR.surf.gii'), '"']);

% load in smoothed gray-ordinate time series
[ grayordinates ] = loadCIFTI(smoothedFile);

end
