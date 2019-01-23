function [ smoothedVolume ] = smoothVolume(functionalFile, varargin)
% Smooth fMRI volume using Gaussian kernel
%
% Syntax:
%  [ smoothedVolume ] = smoothMRI(functionalFile)
%
% Description:
%  This routine uses FSL to perform spatial smoothing on the inputted fMRI
%  volume. Right now this is very simple smoothing in which we apply a
%  Gaussian kernel to the volumetric time series data and does not take
%  into account what is or is not gray matter, for instance.
%
% Inputs:
%  functionalFile        - a string that specifies the full path to the
%                          functional volume to be smoothed
%
% Optional key-value pairs:
%  kernelFWHMmm          - a number that defines the full width at half
%                          maximum of the Gaussian kernel, in mm, to
%                          perform the smoothing with.
%  savePath              - a string that specifies where to save out the
%                          smoothed volume. If empty, the default, then it
%                          will save in the same location as the inputted
%                          functional volume
%
% Outputs:
%  smoothedVolume        - a struct that represents the smoothed fMRI
%                          volume


%% Input parser
p = inputParser; p.KeepUnmatched = true;
p.addParameter('kernelFWHMmm',5, @isnum);
p.addParameter('savePath',[], @isstring);
p.parse(varargin{:});

%% Determine where to save out results
if isempty(p.Results.savePath)
    [ savePath, fileName ] = fileparts(functionalFile);
else
    savePath = p.Results.savePath;
end

%% Convert the FWHM of the Guassian kernel to its sigma
% FSL takes in the sigma value in its function, so we convert the FWHM into
% sigma
sigma = p.Results.kernelFWHMmm/(2*(2*log(2))^0.5);

%% Perform the smoothing
if ~exist(fullfile(savePath, [fileName, '_smoothed.nii.gz']))
    system(['FSLDIR=/usr/local/fsl; PATH=${FSLDIR}/bin:${PATH}; export FSLDIR PATH; . ${FSLDIR}/etc/fslconf/fsl.sh; fslmaths "' functionalFile, '" -kernel gauss ', num2str(sigma), ' -fmean "', fullfile(savePath, [fileName, '_smoothed.nii.gz']), '"']);
    
    %% Load up the smoothed volume
    smoothedVolume = MRIread(fullfile(savePath, [fileName, '_smoothed.nii.gz']));
else
    
    stillTrying = true; tryAttempt = 0;
    while stillTrying
        try
            system(['touch -a "', fullfile(savePath, [fileName, '_smoothed.nii.gz']), '"']);
            pause(tryAttempt*60);
            smoothedVolume = MRIread(fullfile(savePath, [fileName, '_smoothed.nii.gz']));
            stillTrying = false;
        catch
            tryAttempt = tryAttempt + 1;
            stillTrying = tryAttempt < 6;
        end
    end
end

end
