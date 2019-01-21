function analyzeCorrelationBetweenEyeSignals(subjectID, runNamesInOrder)
% A routine to look at correlations between eye signals
% 
% Syntax:
%  analyzeCorrelationBetweenEyeSignals(subjectID, runNamesInOrder)
% 
% Description:
%  This routine will examine how correlated each eye signal is with each
%  other. We will loop over each convolved eye signal. For each
%  eye signal, we will examine its correlation with all other eye signals.
%  This routine will then display the resulting correlation matrix.
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
% Example:
%{
    subjectID = 'TOME_3003';
    runNames{1} = 'rfMRI_REST_AP_Run1'; runNames{2} = 'rfMRI_REST_PA_Run2'; runNames{3} = 'rfMRI_REST_AP_Run3'; runNames{4} = 'rfMRI_REST_PA_Run4';
    analyzeCorrelationBetweenEyeSignals(subjectID, runNames)
%}

%% Load up the eye signals
[ eyeRegressors ] = concatenateEyeRegressors(subjectID, runNamesInOrder);
eyeRegressorLabels = fieldnames(eyeRegressors);

%% Create correlation matrix
convolvedEyeRegressorLabel = [];
columnCounter = 1;
numberOfConvolvedEyeRegressorLabels = sum(contains(eyeRegressorLabels, 'Convolved'));
correlationMatrix = zeros(numberOfConvolvedEyeRegressorLabels, numberOfConvolvedEyeRegressorLabels);

for cc = 1:length(eyeRegressorLabels)
    
    if contains(eyeRegressorLabels{cc}, 'Convolved')
        rowCounter = 1;

        for rr = 1:length(eyeRegressorLabels)
            if contains(eyeRegressorLabels{rr}, 'Convolved')
                
                pearsonCorrelation = corrcoef(eyeRegressors.(eyeRegressorLabels{rr}), eyeRegressors.(eyeRegressorLabels{cc}));
                convolvedEyeRegressorLabel{end+1} = eyeRegressorLabels{rr};
                correlationMatrix(rowCounter, columnCounter) = pearsonCorrelation(1,2);
                rowCounter = rowCounter + 1;
                
            end
        end
        columnCounter = columnCounter + 1;
    end
    
end

% make the figure;
plotFig = figure;
imagesc(correlationMatrix);
xticklabels(convolvedEyeRegressorLabel);
yticklabels(convolvedEyeRegressorLabel);
xtickangle(45);
colorbar;

end % end function