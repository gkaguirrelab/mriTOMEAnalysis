function analyzeICAFIXComponents(subjectID, runNamesInOrder, varargin)


% Example:
%{
    subjectID = 'TOME_3003';
    runNames{1} = 'rfMRI_REST_AP_Run1'; runNames{2} = 'rfMRI_REST_PA_Run2'; runNames{3} = 'rfMRI_REST_AP_Run3'; runNames{4} = 'rfMRI_REST_PA_Run4';
    analyzeICAFIXComponents(subjectID, runNames)
%}

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

% hack our way to getting the component labels
fileID = fopen(fullfile(paths.functionalDir, [runType, '_melodic_mix.sdseries.nii']), 'r');
text = textscan(fileID,  '%s');
relevantPartsOfText = strfind(text{1}, '<MapName>');
relevantCells = find(~cellfun(@isempty,relevantPartsOfText));
componentsThatAreSignal = [];
signalLabel = [];
for ii = 1:length(relevantCells)
    componentLabel = text{1}(relevantCells(ii)+1);
    splitComponentLabel = strsplit(componentLabel{1}, '<');
    componentLabel = splitComponentLabel{1};
    componentLabels{ii} = componentLabel;
    if strcmp(componentLabel, 'Signal')
        componentsThatAreSignal = [componentsThatAreSignal, ii];
        signalLabel{end+1} = 'Signal';
    end
end
    
%% Load up the eye signals
[ eyeRegressors ] = concatenateEyeRegressors(subjectID, runNamesInOrder);
eyeRegressorLabels = fieldnames(eyeRegressors);
%% Run the correlations
for cc = 1:(size(ICAComponents, 1))
    eyeRegressorCounter = 1;
    convolvedEyeRegressorLabel = [];
    for rr = 1:length(eyeRegressorLabels)
        if contains(eyeRegressorLabels{rr}, 'Convolved')
            pearsonCorrelation = corrcoef(eyeRegressors.(eyeRegressorLabels{rr}), ICAComponents(cc,:));
            pearsonCorrelation = pearsonCorrelation(1,2);
            correlationMatrix(cc,eyeRegressorCounter) = abs(pearsonCorrelation);
            eyeRegressorCounter = eyeRegressorCounter + 1;
            convolvedEyeRegressorLabel{end+1} = eyeRegressorLabels{rr};
        end
    end
    
end

%% Plot the correlation matrix
plotFig = figure;
imagesc(correlationMatrix);
xlabel('Eye Regressor');
ylabel('ICA Component');
xticks(1:length(convolvedEyeRegressorLabel));
xticklabels(convolvedEyeRegressorLabel);
xtickangle(45);
yticks(componentsThatAreSignal);
yticklabels(signalLabel);
colorbar;
end