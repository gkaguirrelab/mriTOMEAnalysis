function [ resampledVolume ] = resample(inputFile, targetFile, outputFile, varargin)

p = inputParser; p.KeepUnmatched = true;
%p.addParameter('freeSurferDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID, '/freeSurfer'),  @isstring);
p.parse(varargin{:});

matlabBasePath = mfilename('fullpath');
matlabBasePathSplit = strsplit(matlabBasePath, 'mriTOMEAnalysis');
matlabBasePath = matlabBasePathSplit{1};

system(['bash ', fullfile(matlabBasePath, 'mriTOMEAnalysis', 'code', 'preprocessing', 'resampleMRI.sh'), ' "', inputFile, '" "', targetFile, '" "', outputFile, '"']);

resampledVolume = MRIread(outputFile);

end