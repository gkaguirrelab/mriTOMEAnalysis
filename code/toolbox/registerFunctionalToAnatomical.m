function [ functionalScan ] = registerFunctionalToAnatomical(subjectID, runName, varargin)
p = inputParser; p.KeepUnmatched = true;

p.addParameter('visualizeAlignment',false, @islogical);
p.addParameter('structuralName','T1w_acpc_dc_restore', @ischar);



p.parse(varargin{:});

%% Define paths
[ paths ] = definePaths(subjectID);

freeSurferDir = paths.freeSurferDir;
anatDir = paths.anatDir;
pupilDir = paths.pupilDir;
functionalDir = paths.functionalDir;
outputDir = paths.outputDir;

matlabBasePath = mfilename('fullpath');

%% Align functional and structural scan in native space of structural scan
% run bash script to do the alignment
if ~exist(fullfile(functionalDir, [runName, '_native.nii.gz']))
    system(['bash HCPbringFunctionalToStructural.sh ', subjectID, ' "', anatDir, '" "', functionalDir, '" "', outputDir, '" "', runName, '"']);
    
    % save out the first acquisition of the aligned functional scan to make
    % sure it is aligned like we think
    functionalScan = MRIread(fullfile(functionalDir, [runName, '_native.nii.gz']));
    functionalScan_firstAq = functionalScan;
    functionalScan_firstAq.vol = functionalScan.vol(:,:,:,1);
    MRIwrite(functionalScan_firstAq, fullfile(functionalDir, [runName, '_native_firstAq.nii.gz']));
    
    if (p.Results.visualizeAlignment)
        system(['FSLDIR=/usr/local/fsl; PATH=${FSLDIR}/bin:${PATH}; export FSLDIR PATH; . ${FSLDIR}/etc/fslconf/fsl.sh; fsleyes ' '"', anatDir, '/', structuralName, '.nii.gz" "', functionalDir, '/', runName, '_native_firstAq.nii.gz "']);
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