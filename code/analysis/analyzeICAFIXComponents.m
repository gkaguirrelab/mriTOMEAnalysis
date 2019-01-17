function analyzeICAFIXComponents(subjectID, varargin)


%% Input parser
p = inputParser; p.KeepUnmatched = true;

p.addParameter('runType', 'REST', @ischar);
p.addParameter('workbenchPath', '/Applications/workbench/bin_macosx64/', @ischar);


p.parse(varargin{:});

%% Find the ICAFIX output file
runType = upper(p.Results.runType);

paths = definePaths(subjectID);
ICAFIXFileName = fullfile(paths.functionalDir, [runType, '_melodic_mix.sdseries.nii']);

%% Convert cifti to text file
% So we can load it into MATLAB
system(['bash ', p.Results.workbenchPath, 'wb_command -cifti-convert -to-text ', ICAFIXFileName, ' ', fullfile(paths.functionalDir, [runType, '_ICAFIXComponents.txt'])]);

ICAComponents = readtable(fullfile(paths.functionalDir, [runType, '_ICAFIXComponents.txt']));
ICAComponents = table2array(ICAComponents);
end