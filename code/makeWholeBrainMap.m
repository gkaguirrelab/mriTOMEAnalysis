function [] = makeWholeBrainMap(subjectID, runName, regressor, varargin)

p = inputParser; p.KeepUnmatched = true;
p.addParameter('freeSurferDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID, '/freeSurfer'),  @isstring);
p.addParameter('anatDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);
p.addParameter('pupilDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);
p.addParameter('functionalDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID),  @isstring);
p.addParameter('outputDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);


p.parse(varargin{:});

%% Load up the functional scan
% we specifically want the functional scan that has already been brought
% back to native anatomical space.
% using try-catch stuff here in case dropbox needs to download the file
functionalDir = p.Results.functionalDir;
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

%% Loop over voxels, and perform the IAMP fit

% dimensions of our functional data
nXIndices = size(functionalScan.vol, 1);
nYIndices = size(functionalScan.vol, 2);
nZIndices = size(functionalScan.vol, 3);
nTRs = size(functionalScan.vol, 4);

betaVolume = functionalScan;
rSquaredVolume = functionalScan;
betaVolume.vol = [];
rSquaredVolume.vol = [];

for xx = 1:nXIndices
    for yy = 1:nYIndices
        for zz = 1:nZIndices
            voxelTimeSeries = functionalScan.vol(xx,yy,zz,:);
            voxelTimeSeries = reshape(voxelTimeSeries,1,nTRs);
        end
    end
end


end