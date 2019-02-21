function [ maskMatrix ] = makeMaskFromRetinoCIFTI(areaNum, eccenRange, anglesRange, hemisphere, varargin)
%{
% make a V1 mask for the left hemisphere
areaNum = 1;
eccenRange = [0 90];
anglesRange = [0 180];
hemisphere = 'combined';
savePath = definePaths('benson');
saveName = fullfile(savePath.anatDir, 'lh.V1.dscalar.nii');

[ maskMatrix ] = makeMaskFromRetinoCIFTI(areaNum, eccenRange, anglesRange, hemisphere, 'saveName', saveName);

%}

p = inputParser; p.KeepUnmatched = true;
p.addParameter('saveName', [], @ischar)
p.parse(varargin{:});


%% Locate the template files
% describe the different templates we want to produce
mapTypes = {'angle', 'eccen', 'varea'};
hemispheres  = {'lh', 'rh'};
paths = definePaths('benson');

%% Restrict area
areaMap = zeros(91282,1);
if strcmp(hemisphere, 'lh') || strcmp(hemisphere, 'combined')
    [ lhAreaTemplate ] = loadCIFTI(fullfile(paths.anatDir, 'lh.benson14_varea.dscalar.nii'));
    areaMap(lhAreaTemplate == areaNum) = 1;
    
    rhAreaTemplate = zeros(91282,1);
end
if strcmp(hemisphere, 'rh') || strcmp(hemisphere, 'combined')
    lhAreaTemplate = zeros(91282,1);
    
    
    [ rhAreaTemplate ] = loadCIFTI(fullfile(paths.anatDir, 'rh.benson14_varea.dscalar.nii'));
    areaMap(rhAreaTemplate == areaNum) = 1;
end


%% Restrict eccentricity
eccenMap = zeros(91282,1);
if strcmp(hemisphere, 'lh') || strcmp(hemisphere, 'combined')
    [ lhEccenTemplate ] = loadCIFTI(fullfile(paths.anatDir, 'lh.benson14_eccen.dscalar.nii'));
    eccenMap(lhEccenTemplate >= eccenRange(1) & lhEccenTemplate <= eccenRange(2)) = 1;
    
    rhEccenTemplate = zeros(91282,1);
end
if strcmp(hemisphere, 'rh') || strcmp(hemisphere, 'combined')
    lhEccenTemplate = zeros(91282,1);
    
    
    [ rhEccenTemplate ] = loadCIFTI(fullfile(paths.anatDir, 'rh.benson14_eccen.dscalar.nii'));
    eccenMap(rhEccenTemplate >= eccenRange(1) & rhEccenTemplate <= eccenRange(2)) = 1;
end


%% Restrict polar angles
anglesMap = zeros(91282,1);
if strcmp(hemisphere, 'lh') || strcmp(hemisphere, 'combined')
    [ lhAnglesTemplate ] = loadCIFTI(fullfile(paths.anatDir, 'lh.benson14_angle.dscalar.nii'));
    anglesMap(lhAnglesTemplate >= anglesRange(1) & lhAnglesTemplate <= anglesRange(2)) = 1;
    
    rhAnglesTemplate = zeros(91282,1);
end
if strcmp(hemisphere, 'rh') || strcmp(hemisphere, 'combined')
    lhAnglesTemplate = zeros(91282,1);
    
    
    [ rhAnglesTemplate ] = loadCIFTI(fullfile(paths.anatDir, 'rh.benson14_angle.dscalar.nii'));
    anglesMap(rhAnglesTemplate >= anglesRange(1) & rhAnglesTemplate <= anglesRange(2)) = 1;
end


%% Combine maps
combinedMap = zeros(91282,1);
combinedMap(areaMap == 1 & eccenMap == 1 & anglesMap == 1) = 1;
maskMatrix = combinedMap;

% save out mask, if desired
if ~isempty(p.Results.saveName)
    makeWholeBrainMap(combinedMap', [], fullfile(paths.anatDir, 'lh.benson14_varea.dscalar.nii'), p.Results.saveName)
end




end