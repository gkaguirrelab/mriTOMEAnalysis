function [ functionalScan ] = registerFunctionalToAnatomical(subjectID, runName, varargin)
% Registers the functional scan onto the anatomical scan.
%
% Syntax:
%  registerFunctionalToAnatomical(subjectID, runName)
%
% Description:
%  This routine registers the functional volume onto the structural volume
%  in subject native space. This code calls a bash script
%  (HCPbringFunctionalToStructural), which itself performs this
%  registration using FSL. 
%
% Inputs:
%  subjectID:           - a string that identifies the relevant subject (i.e.
%                         'TOME_3040'
%  runName:             - a string that identifies the relevant run (i.e.
%                         'rfMRI_REST_AP_Run3')
%
% Optional key-value pairs:
%  visualizeAlignment   - a logical that determines whether to visualize
%                         the alignment between functional volume and
%                         structural volume after registration has taken
%                         place.
%  structuralN
%
% Outputs:
%  functionalScan       - a structure that represents the
%                         anatomically-aligned functional volume


p = inputParser; p.KeepUnmatched = true;

p.addParameter('visualizeAlignment',false, @islogical);

p.parse(varargin{:});

%% Define paths
[ paths ] = definePaths(subjectID);

freeSurferDir = paths.freeSurferDir;
anatDir = paths.anatDir;
pupilDir = paths.pupilDir;
functionalDir = paths.functionalDir;
outputDir = paths.outputDir;

matlabBasePath = mfilename('fullpath');
matlabBasePathSplit = strsplit(matlabBasePath, 'mriTOMEAnalysis');
matlabBasePath = matlabBasePathSplit{1};

%% Align functional and structural scan in native space of structural scan
% run bash script to do the alignment
if ~exist(fullfile(functionalDir, [runName, '_native.nii.gz']))
    system(['bash ', fullfile(matlabBasePath, 'mriTOMEAnalysis', 'code', 'preprocessing', 'HCPbringFunctionalToStructural.sh'), ' ', subjectID, ' "', anatDir, '" "', functionalDir, '" "', outputDir, '" "', runName, '"']);
    
    % save out the first acquisition of the aligned functional scan to make
    % sure it is aligned like we think
    functionalScan = MRIread(fullfile(functionalDir, [runName, '_native.nii.gz']));
    functionalScan_firstAq = functionalScan;
    functionalScan_firstAq.vol = functionalScan.vol(:,:,:,1);
    MRIwrite(functionalScan_firstAq, fullfile(functionalDir, [runName, '_native_firstAq.nii.gz']));
    
    if (p.Results.visualizeAlignment)
        system(['FSLDIR=/usr/local/fsl; PATH=${FSLDIR}/bin:${PATH}; export FSLDIR PATH; . ${FSLDIR}/etc/fslconf/fsl.sh; fsleyes ' '"', anatDir, '/T1w_acpc_dc_restore.nii.gz" "', functionalDir, '/', runName, '_native_firstAq.nii.gz "']);
    end
else
    stillTrying = true; tryAttempt = 0;
    while stillTrying
        try
            system(['touch -a "', fullfile(functionalDir, [runName, '_native.nii.gz']), '"']);
            pause(tryAttempt*60);
            functionalScan = MRIread(fullfile(functionalDir, [runName, '_native.nii.gz']));
            stillTrying = false;
        catch
            tryAttempt = tryAttempt + 1;
            stillTrying = tryAttempt < 6;
        end
    end
end

end