close all; clear all
t = 0:420;
y1 = sin(t/20);
y2 = 1/4*cos(t/40);

signal = y1+y2+rand(1,421);
plot(signal)

tfe = tfeIAMP('verbosity', 'none');

thePacket.kernel = [];
thePacket.metaData = [];
thePacket.stimulus.timebase = t;
thePacket.stimulus.values(1,:) = y1;
thePacket.stimulus.values(2,:) = 4*y2;
thePacket.response.timebase = t;
thePacket.response.values = signal;

defaultParamsInfo.nInstances = size(thePacket.stimulus.values,1);

[paramsFit,~,modelResponseStruct] = tfe.fitResponse(thePacket,...
    'defaultParamsInfo', defaultParamsInfo, 'searchMethod','linearRegression','errorType','1-r2');

correlationMatrix = corrcoef(modelResponseStruct.values, thePacket.response.values, 'Rows', 'complete');
rSquaredY1Y2 = correlationMatrix(1,2)^2;

thePacket = [];
thePacket.kernel = [];
thePacket.metaData = [];
thePacket.stimulus.timebase = t;
thePacket.stimulus.values(1,:) = y1;
thePacket.response.timebase = t;
thePacket.response.values = signal;
defaultParamsInfo.nInstances = size(thePacket.stimulus.values,1);


paramsFit = []; modelResponseStruct = [];
[paramsFit,~,modelResponseStruct] = tfe.fitResponse(thePacket,...
    'defaultParamsInfo', defaultParamsInfo, 'searchMethod','linearRegression','errorType','1-r2');
correlationMatrix = corrcoef(modelResponseStruct.values, thePacket.response.values, 'Rows', 'complete');
rSquaredY1Only = correlationMatrix(1,2)^2;



thePacket = [];
thePacket.kernel = [];
thePacket.metaData = [];
thePacket.stimulus.timebase = t;
thePacket.stimulus.values(1,:) = 4*y2;
thePacket.response.timebase = t;
thePacket.response.values = signal;
defaultParamsInfo.nInstances = size(thePacket.stimulus.values,1);


paramsFit = []; modelResponseStruct = [];
[paramsFit,~,modelResponseStruct] = tfe.fitResponse(thePacket,...
    'defaultParamsInfo', defaultParamsInfo, 'searchMethod','linearRegression','errorType','1-r2');
correlationMatrix = corrcoef(modelResponseStruct.values, thePacket.response.values, 'Rows', 'complete');
rSquaredY2Only = correlationMatrix(1,2)^2;