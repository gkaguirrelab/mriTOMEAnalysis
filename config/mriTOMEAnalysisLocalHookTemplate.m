function mrTOMEAnalysisLocalHook
%  LFContrastAnalsysisLocalHook
%
% Configure things for working on the  mrTOMEAnalysis project.
%
% For use with the ToolboxToolbox.
%
% If you 'git clone' ILFContrastAnalsysis into your ToolboxToolbox "projectRoot"
% folder, then run in MATLAB
%   tbUseProject('mrTOMEAnalysis')
% ToolboxToolbox will set up IBIOColorDetect and its dependencies on
% your machine.
%
% As part of the setup process, ToolboxToolbox will copy this file to your
% ToolboxToolbox localToolboxHooks directory (minus the "Template" suffix).
% The defalt location for this would be
%   ~/localToolboxHooks/LFContrastAnalsysisLocalHook.m
%
% Each time you run tbUseProject('mrTOMEAnalysis'), ToolboxToolbox will
% execute your local copy of this file to do setup for LFContrastAnalsysis.
%
% You should edit your local copy with values that are correct for your
% local machine, for example the output directory location.
%


%% Say hello.
fprintf('mriTOMEAnalysis local hook.\n');
projectName = 'mriTOMEAnalysis';

%% Delete any old prefs
if (ispref(projectName))
    rmpref(projectName);
end

%% Specify base paths for materials and data
[~, userID] = system('whoami');
userID = strtrim(userID);
switch userID
    case {'dhb'}
        materialsBasePath = ['/Users1' '/Dropbox (Aguirre-Brainard Lab)/TOME_materials'];
        TOME_dataBasePath = ['/Users1' '/Dropbox (Aguirre-Brainard Lab)/TOME_data/'];     
    case {'mbarnett'}
        materialsBasePath = ['/home/mbarnett/Dropbox (Aguirre-Brainard Lab)/TOME_materials'];
        TOME_dataBasePath = ['/home/mbarnett/Dropbox (Aguirre-Brainard Lab)/TOME_data/'];
    case {'harrisonmcadams'}
        materialsBasePath = ['/Users/' userID '/Dropbox-Aguirre-Brainard-Lab/TOME_materials'];
        TOME_dataBasePath = ['/Users/' userID '/Dropbox-Aguirre-Brainard-Lab/TOME_data/'];
        TOME_analysisBasePath = ['/Users/' userID '/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/'];
    otherwise
        materialsBasePath = ['/Users/' userID '/Dropbox (Aguirre-Brainard Lab)/TOME_materials'];
        TOME_dataBasePath = ['/Users/' userID '/Dropbox (Aguirre-Brainard Lab)/TOME_data/'];
        TOME_analysisBasePath = ['/Users/' userID '/Dropbox (Aguirre-Brainard Lab)/MELA_analysis/'];
end

%% Specify where output goes

if ismac
    % Code to run on Mac plaform
    setpref(projectName,'analysisScratchDir','/tmp/flywheel');
    setpref(projectName,'projectRootDir',fullfile('/Users/',userID,'/Documents/flywheel',projectName));
    setpref(projectName,'TOMEDataPath', TOME_dataBasePath);
    setpref(projectName, 'TOME_analysisPath', TOME_analysisBasePath);
elseif isunix
    % Code to run on Linux plaform
    setpref(projectName,'analysisScratchDir','/tmp/flywheel');
    setpref(projectName,'projectRootDir',fullfile('/home/',userID,'/Documents/flywheel',projectName));
    setpref(projectName,'TOMEDataPath', TOME_dataBasePath);
    setpref(projectName, 'TOME_analysisPath', TOME_analysisBasePath);

elseif ispc
    % Code to run on Windows platform
    warning('No supported for PC')
else
    disp('What are you using?')
end
