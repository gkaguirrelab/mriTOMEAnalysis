function [ paths ] = definePaths(subjectID)
[~, userID] = system('whoami');

paths.freeSurferDir = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID, '/freeSurfer');
paths.anatDir = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID);
paths.pupilDir = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID);
paths.outputDir = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID);
paths.functionalDir = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID);
paths.restWholeBrainAnalysis = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/wholeBrain/resting', subjectID);
paths.pupilProcessingDir = fullfile(getpref('mriTOMEAnalysis', 'TOME_processingPath'));
paths.dataDownloadDir = ['/Users/', userID, '/Desktop/temp'];


end