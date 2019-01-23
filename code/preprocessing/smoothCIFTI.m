function [grayordinates] = smoothCIFTI(functionalFile, varargin)
% Smooth fMRI grayordinates using Gaussian kernel
%
% Syntax:
%  smoothVolume(functionalFile)
%
% Description:
%  This routine uses HCP's workbench to perform spatial smoothing on the inputted fMRI
%  CIFTI file. Right now this is very simple smoothing in which we apply a
%  Gaussian kernel over both the cortical surface and subcortical volume.
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
%
% Outputs:
%  grayordinates         - an m x n matrix, where m is the number of
%                          grayordinates and n is the number of time points
%                          in the acquisition


%% Input parser
p = inputParser; p.KeepUnmatched = true;
p.addParameter('surfaceKernelFWHMmm',5, @isnum);
p.addParameter('volumeKernelFWHMmm',5, @isnum);
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

%% Perform the smoothing
if ~exist(fullfile(savePath, [fileName(1:end-9), '_smoothed.dtseries.nii']))
    system([p.Results.workbenchPath, 'wb_command -cifti-smoothing "' functionalFile, '" 5 5 COLUMN "' smoothedFile, '" -left-surface "', fullfile(savePath, 'L.midthickness.32k_fs_LR.surf.gii'), '" -right-surface "', fullfile(savePath, 'R.midthickness.32k_fs_LR.surf.gii'), '"']);
    
    % load in smoothed gray-ordinate time series
    % So we can load it into MATLAB
    system(['bash ', p.Results.workbenchPath, 'wb_command -cifti-convert -to-text ', smoothedFile, ' ', fullfile(savePath, [fileName(1:end-9), '_smoothed.txt'])]);
    
    grayordinates = readtable(fullfile(savePath, [fileName(1:end-9), '_smoothed.txt']));
    grayordinates = table2array(grayordinates);
else
    
    stillTrying = true; tryAttempt = 0;
    while stillTrying
        try
            % load in smoothed gray-ordinate time series
            % So we can load it into MATLAB
            system(['bash ', p.Results.workbenchPath, 'wb_command -cifti-convert -to-text ', smoothedFile, ' ', fullfile(savePath, [fileName(1:end-9), '_smoothed.txt'])]);
            
            grayordinates = readtable(fullfile(savePath, [fileName(1:end-9), '_smoothed.txt']));
            grayordinates = table2array(grayordinates);
            stillTrying = false;
        catch
            tryAttempt = tryAttempt + 1;
            stillTrying = tryAttempt < 6;
        end
    end
end

end
