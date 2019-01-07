function compileForwardModelIAMP(compileArgs)

% Compiles the forward model of the IAMP and saves it to code local bin
%
% Syntax:
%  compileForwardModelIAMP
%
% Description:
%   This routine produces a compiled mex file for IAMP forward model, saves
%   the within a local bin directory, and places the function on the
%   MATLAB path.
%
% Inputs:
%   compileArgs             A cell array that contains examples of the
%                           variables that are used by the forwardModel.
%                           This is needed so that the codegen can define
%                           the type and dimensions of the variables.
%
% Examples:
%{
    % Demonstrate compilation of the IAMP forward model
    temporalFit = tfeIAMP('verbosity','none');
    defaultParamsInfo.nInstances = 21;
    params0 = temporalFit.defaultParams('defaultParamsInfo', defaultParamsInfo);
    stimulusStruct.timebase = 1:3300;
    stimulusStruct.values = zeros(21,3300);
    compileArgs = {params0 stimulusStruct};
    compileForwardModelIAMP(compileArgs)
    % Can now pass this compiled function to IAMP using the key-value pair
    % 'forwardModelHandle'
%}

mexFileName = 'forwardModelIAMPMex';

% Define the location 
functionDirPath = mfilename('fullpath');
functionDirPath = strsplit(functionDirPath,'compileForwardModelIAMP');
functionDirPath = fullfile(functionDirPath{1},'bin',mexFileName);


%% Error if the function dir does not exist
if ~exist(functionDirPath,'dir')
    error('compileForwardModelIAMP:dirDoesNotExist','The specified function directory does not exist.')
end


%% Remove pre-existing functions from the path
% Detect the case in which the current directory itself contains a compiled
% virtualImageFuncMex file, in which case the user needs to change
% directories
if strcmp(pwd(),fileparts(which('forwardModelIAMPMex')))
    error('compileForwardModelIAMP:dirConflict','The current folder itself contains a compiled forwardModelIAMPMex. Change directories to avoid function shadowing.')
end

% Remove any existing versions of the forwardModelIAMPMex from the path.
notDoneFlag = true;
removalsCounter = 0;
tooManyRemovals = 4;
while notDoneFlag
    funcPath = which('forwardModelIAMPMex');
    if isempty(funcPath)
        notDoneFlag = false;
    else
        warning('compileForwardModelIAMP:previousFunc','Removing a previous forwardModelIAMPMex from the path');
        rmpath(fileparts(funcPath));
        removalsCounter = removalsCounter+1;
    end
    if removalsCounter == tooManyRemovals
        error('compileForwardModelIAMP:tooManyRemovals','Potentially stuck in a loop trying to remove previous forwardModelIAMPMex functions from the path.')
    end
end


%% Compile and clean up
% Change to the compile directory
initialDir = cd(functionDirPath);
% Compile the mex file
codeGenCommand = ['codegen -o ' mexFileName ' forwardModelIAMP -args compileArgs'];
eval(codeGenCommand);

% Clean up the compile dir. Turn off warnings regarding the removal of
% these files
warnState = warning();
warning('Off','MATLAB:RMDIR:RemovedFromPath');
rmdir('codegen', 's');
warning(warnState);
% Refresh the path to add the compiled function
addpath(functionDirPath,'-begin');
% Change back to the initial directory
cd(initialDir);


end % compileForwardModelIAMP






