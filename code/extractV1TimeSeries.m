function [ meanV1TimeSeries] = extractV1TimeSeries(subjectID, varargin)
p = inputParser; p.KeepUnmatched = true;
p.addParameter('visualizeAlignment',false, @islogical);
p.addParameter('freeSurferDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID, '/freeSurfer'),  @isstring);
p.addParameter('anatDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);
p.addParameter('functionalDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID),  @isstring);
p.addParameter('outputDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);
p.addParameter('runName','rfMRI_REST_AP_Run1', @ischar);
p.addParameter('structuralName','T1w_acpc_dc_restore', @ischar);



p.parse(varargin{:});

%% Get the subject's data
freeSurferDir = p.Results.freeSurferDir;
anatDir = p.Results.anatDir;
functionalDir = p.Results.functionalDir;
outputDir = p.Results.outputDir;
runName = p.Results.runName;
structuralName = p.Results.structuralName;

%% Align functional and structural scan in native space of structural scan
% run bash script to do the alignment
system(['bash HCPbringFunctionalToStructural.sh ', subjectID, ' "', anatDir, '" "', functionalDir, '" "', outputDir, '" "', runName, '"']);

% save out the first acquisition of the aligned functional scan to make
% sure it is aligned like we think
functionalScan = MRIread(fullfile(functionalDir, [runName, '_native.nii.gz']));
functionalScan_firstAq = functionalScan;
functionalScan_firstAq.vol = functionalScan.vol(:,:,:,1);
MRIwrite(functionalScan_firstAq, fullfile(functionalDir, [runName, '_native_firstAq.nii.gz']));
system(['fsleyes "', anatDir, '/', structuralName, '.nii.gz" "', functionalDir, '/', runName, '_native_firstAq.nii.gz "']);


%% Run FreeSurfer bit
system(['bash makeV1Mask.sh ', subjectID, ' "', anatDir, '" "', freeSurferDir, '" "', functionalDir, '" "', outputDir, '" "', runName, '" "', structuralName '"']);

%% Verify alignment
if p.Results.visualizeAlignment
    system(['export FREESURFER_HOME=/Applications/freesurfer; source $FREESURFER_HOME/SetUpFreeSurfer.sh; freeview -v ' anatDir, '/T1w1_gdc.nii.gz ', functionalDir, ['/' runName '_gdc.nii.gz '], outputDir, '/', [subjectID '_' runName '_lh_v1_registeredToFunctional.nii.gz '] outputDir, '/', [subjectID '_' runName '_rh_v1_registeredToFunctional.nii.gz &']])
end

%% MATLAB stuffs
% after we've made the V1 mask, lets start figuring out the timeseries
lhV1Mask = MRIread(fullfile(outputDir, [subjectID '_' runName '_lh_v1_registeredToFunctional.nii.gz']));
rhV1Mask = MRIread(fullfile(outputDir, [subjectID '_' runName '_rh_v1_registeredToFunctional.nii.gz']));

combinedV1Mask = lhV1Mask; % make sure combinedV1Mask has the appropriate header information
combinedV1Mask.vol = [];
combinedV1Mask.vol = rhV1Mask.vol + lhV1Mask.vol;
MRIwrite(combinedV1Mask, fullfile(outputDir, [subjectID '_' runName '_bothHemispheres_v1_registeredToFunctional.nii.gz']));



restScan = MRIread(fullfile(functionalDir, [runName, '_native.nii.gz']));


% confirm that registration happened the way we think we did and that
% freeview isn't misleading us. if we visualize this, such as with imagesec
% in MATLAB, we can see that the zero'ed out voxels are largely where we'd
% want them to be in v1
superImposedMask.vol = (1-combinedV1Mask.vol).*restScan.vol;



v1TimeSeries = combinedV1Mask.vol.*restScan.vol; % still contains voxels with 0s

% convert 4D matrix to 2D matrix, where each row is a separate time series
% corresponding to a different voxel in the mask

% dimensions of our functional data
nXIndices = size(v1TimeSeries, 1);
nYIndices = size(v1TimeSeries, 2);
nZIndices = size(v1TimeSeries, 3);
nTRs = size(v1TimeSeries, 4);

% variable to pool voxels that have not been masked out
v1TimeSeriesCollapsed = [];
nNonZeroVoxel = 1;

for xx = 1:nXIndices
    for yy = 1:nYIndices
        for zz = 1:nZIndices
            if ~isempty(find([v1TimeSeries(xx,yy,zz,:)] ~= 0))
                for tr = 1:nTRs
                    % stash voxels that hvae not been masked out
                    v1TimeSeriesCollapsed(nNonZeroVoxel, tr) = v1TimeSeries(xx,yy,zz,tr);
                end
                nNonZeroVoxel = nNonZeroVoxel + 1;
            end
        end
    end
end

% take the mean
plotFig = figure;
meanV1TimeSeries = mean(v1TimeSeriesCollapsed,1);
tr = restScan.tr/1000;
timebase = 0:tr:(length(meanV1TimeSeries)*tr-tr);
plot(timebase, meanV1TimeSeries)
xlabel('Time (s)')
ylabel('BOLD Signal')

savePath = fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), 'mriTOMEAnalysis', 'meanV1TimeSeries', subjectID);
if ~exist(savePath, 'dir')
    mkdir(savePath);
end

save(fullfile(savePath, [runName '_meanV1TimeSeries']), 'meanV1TimeSeries', '-v7.3');


% load in pupil data

end

