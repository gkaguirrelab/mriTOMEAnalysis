function [averageMap] = makeAverageMapWithinSubject(subjectID, eyeRegressor, mapType, runNames, varargin)
% Average across maps for all runs for a single subject
%
% Syntax:
%  makeAverageMapWithinSubject(subjectID, mapType);
%
% Inputs:
%  subjectID                - a string that describes the subject ID (e.g.
%                             'TOME_3003')
%  eyeRegressor             - a string that describes maps of which eye
%                             regressor are to be combined. Options include
%                             'rectifiedPupilChangeBandpassed',
%                             'pupilChangeBandpassed',
%                             'pupilDiameterBandpassed', 'eyeDisplacement',
%                             'rectifiedPupilChange', 'pupilChange', and
%                             'pupilDiameter'
%  mapType                  - a string that describes which map type we
%                             want to combine. Options include 'beta',
%                             'pearsonR', and 'rSquared'
%  runNames                 - a cell array, where the contents of each cell
%                             is a string that defines the runNames to be averaged
%
% Optional key-value pairs:
%  'saveName'              - a string which specifies the full path to which
%                            to save the relevant output of this code. If
%                            empty, no results will be saved out.
%
% Output:
%  averageMap              - a struct that contains the averaged map

%% Input Parser
p = inputParser; p.KeepUnmatched = true;
p.addParameter('saveName', [], @ischar);
p.parse(varargin{:});

%% Find the relevant maps
paths = definePaths(subjectID);
mapsDir = paths.restWholeBrainAnalysis;


potentialMaps = dir(fullfile(mapsDir, ['*', eyeRegressor, '_', mapType, '.nii.gz']));

%% Loop over the maps, pooling as we go
firstMap = MRIread(fullfile(mapsDir, [runNames{1}, '_', eyeRegressor, '_', mapType, '.nii.gz']));
template = zeros(size(firstMap.vol));
for mm = 1:length(runNames)
    map = MRIread(fullfile(mapsDir, [runNames{mm}, '_', eyeRegressor, '_', mapType, '.nii.gz']));
    template = map.vol + template;
    clear map
end

%% Average
averageMap = template ./ length(potentialMaps);
firstMap.vol = averageMap;

%% Save out
if ~isempty(p.Results.saveName)
    MRIwrite(firstMap, p.Results.saveName);
end

end
