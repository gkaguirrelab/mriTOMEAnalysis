function [ componentNumberRankedByAverageCorrelation ] = analyzeICAFIXComponents(subjectID, runNamesInOrder, varargin)
% A routine to understand how outputs of the ICAFIX gear relate to our eye
% signals
%
% Syntax:
%  [ componentNumberRankedByAverageCorrelation ] = analyzeICAFIXComponents(subjectID, runNamesInOrder)
%
% Description:
%  ICAFIX outputs numerous different components, some of which are labeled
%  as signal with the rest labeled as noise. We have noticed that
%  preprocessing which produces just the signal components shows less of a
%  correlation with our eye signal components than our standard
%  preprocessing alone. To understand why this is, we're looking to see if
%  any of our components labeled as 'noise' are correlated with our eye
%  signals, and then determine if we agree if these components are in fact
%  'noise'.
%  This routine first extracts the time series of each component from the
%  CIFTI files generated from the ICAFIX routine. The commmand to extract
%  the time series of each component is done using one of the standard
%  workbench commands, but note that the code to extract component labels
%  is a total hack-job. Once the time series have been extracted, we
%  correlate each with each eye signal, and ultimatley produce a
%  correlation matrix.
%
%
% Inputs:
%  subjectID                - a string that that describes the example
%                             subject to be investigated (e.g.
%                             'TOME_3003').
%  runNamesInOrder          - a cell array, where the contents of each cell
%                             is a string that defines the name of the fMRI
%                             run. Note that these must be in order so that
%                             the concatenated eye signals match the order
%                             of the concatenated fMRI runs.
%
% Optional key-value pairs:
%  runType                  - a string that describes the prefix to the
%                             ICAFIX output. The default is 'REST'.
%  workbenchPath            - a string that defines the full path to where
%                             workbench commands can be found.
%  covariatesOfInterest     - a cell array, where the contents of each cell
%                             is a string that defines an eye signal
%                             covariate to be used in this analysis
%
% Outputs:
%  componentNumberRankedByAverageCorrelation  - a 1 x n vector, where n
%                             corresponds to the the number of ICA
%                             components. The value of each element in the
%                             vector corresponds to the ID of an ICA
%                             component. These are ranked in the order of
%                             greatest average correlation across all eye
%                             signal covariates to smallest average
%                             correlation.
%
% Example:
%{
    subjectID = 'TOME_3003';
    runNames{1} = 'rfMRI_REST_AP_Run1'; runNames{2} = 'rfMRI_REST_PA_Run2'; runNames{3} = 'rfMRI_REST_AP_Run3'; runNames{4} = 'rfMRI_REST_PA_Run4';
    [ componentNumberRankedByAverageCorrelation ] = analyzeICAFIXComponents(subjectID, runNames)
%}

%% Input parser
p = inputParser; p.KeepUnmatched = true;

p.addParameter('runType', 'REST', @ischar);
p.addParameter('workbenchPath', '/Applications/workbench/bin_macosx64/', @ischar);
p.addParameter('covariatesOfInterest', [], @iscell);

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
    if isempty(p.Results.covariatesOfInterest)
        
        for rr = 1:length(eyeRegressorLabels)
            if contains(eyeRegressorLabels{rr}, 'Convolved')
                pearsonCorrelation = corrcoef(eyeRegressors.(eyeRegressorLabels{rr}), ICAComponents(cc,:));
                pearsonCorrelation = pearsonCorrelation(1,2);
                correlationMatrix(cc,eyeRegressorCounter) = abs(pearsonCorrelation);
                eyeRegressorCounter = eyeRegressorCounter + 1;
                convolvedEyeRegressorLabel{end+1} = eyeRegressorLabels{rr};
            end
            
        end
    else
        for rr = 1:length(p.Results.covariatesOfInterest)
                pearsonCorrelation = corrcoef(eyeRegressors.(p.Results.covariatesOfInterest{rr}), ICAComponents(cc,:));
                pearsonCorrelation = pearsonCorrelation(1,2);
                correlationMatrix(cc,eyeRegressorCounter) = abs(pearsonCorrelation);
                eyeRegressorCounter = eyeRegressorCounter + 1;
                convolvedEyeRegressorLabel{end+1} = eyeRegressorLabels{rr};            
        end
    end
    
end

%% Compute the average correlation across all eye signals for each ICA component
averageCorrelation = mean(correlationMatrix, 2);
correlationMatrix = [correlationMatrix, averageCorrelation];
convolvedEyeRegressorLabel{end+1} = 'Average Correlation';

% and rank the average correlation
[sortedCorrelations, componentNumberRankedByAverageCorrelation] = sort(averageCorrelation, 'descend');

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