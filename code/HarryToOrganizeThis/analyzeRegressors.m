function analyzeRegressors(timeSeries, regressors)

confoundRegressors = regressors;
confoundRegressors = confoundRegressors - nanmean(confoundRegressors);
confoundRegressors = confoundRegressors ./ nanstd(confoundRegressors);

temporalFit = tfeIAMP('verbosity','none');

TR = 0.800;

% make stimulus timebase
deltaT = 800;
totalTime = 420*deltaT;
stimulusStruct.timebase = linspace(0,totalTime-deltaT,totalTime/deltaT);
responseStruct.timebase = stimulusStruct.timebase;
thePacket.kernel = [];
thePacket.metaData = [];

thePacket.stimulus.values = confoundRegressors';

defaultParamsInfo.nInstances = size(thePacket.stimulus.values,1);

% get the data for all masked voxel in a run
runData = timeSeries;

% convert to percent signal change relative to the mean
voxelMeanVec = mean(runData,2);
PSC = 100*((runData - voxelMeanVec)./voxelMeanVec);

% timebase will be the same for every voxel
thePacket.response.timebase = stimulusStruct.timebase;
thePacket.stimulus.timebase = stimulusStruct.timebase;

thePacket.response.values = PSC;

% TFE linear regression here
%         disp(jj);
%         disp(vxl);
[paramsFit,fVal,modelResponseStruct] = temporalFit.fitResponse(thePacket,...
    'defaultParamsInfo', defaultParamsInfo, 'searchMethod','linearRegression','errorType','1-r2');

confoundBetas = paramsFit.paramMainMatrix;
cleanRunData = thePacket.response.values - modelResponseStruct.values;
IAMPfval = 1-fVal;

end