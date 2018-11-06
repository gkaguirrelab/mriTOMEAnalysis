function [ resampledVolume ] = resample(inputFile, targetFile, outputFile, varargin)

p = inputParser; p.KeepUnmatched = true;
%p.addParameter('freeSurferDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID, '/freeSurfer'),  @isstring);
p.parse(varargin{:});

system(['bash resample.sh "', inputFile, '" "', targetFile, '" "', outputFile, '"']);

resampledVolume = MRIread(outputFile);

end