function [ functionalScan ] = registerFunctionalToAnatomical(subjectID, runName, varargin)
p = inputParser; p.KeepUnmatched = true;

p.addParameter('visualizeAlignment',false, @islogical);
p.addParameter('freeSurferDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID, '/freeSurfer'),  @isstring);
p.addParameter('anatDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);
p.addParameter('functionalDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID),  @isstring);
p.addParameter('outputDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);
p.addParameter('structuralName','T1w_acpc_dc_restore', @ischar);



p.parse(varargin{:});

%% Define the relevant directories
freeSurferDir = p.Results.freeSurferDir;
anatDir = p.Results.anatDir;
functionalDir = p.Results.functionalDir;
outputDir = p.Results.outputDir;
structuralName = p.Results.structuralName;

%% Align functional and structural scan in native space of structural scan
% run bash script to do the alignment
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

end