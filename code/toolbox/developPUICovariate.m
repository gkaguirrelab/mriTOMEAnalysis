
close all


% make a time series with obviously varying variation over time
t = 0:1000;
y = sin(t).*sin(t/100);
figure; subplot(2,1,1); plot(t, y);

rollingSTD = movstd(y, 5);
subplot(2,1,2); plot(t, rollingSTD);

subjectID = 'TOME_3003';
runName = 'rfMRI_REST_AP_Run1';
[~, unconvolvedCovariates] = makeEyeSignalCovariates(subjectID, runName);

figure; subplot(3,1,1); plot(covariates.timebase, unconvolvedCovariates.pupilDiameter);
rollingSTD = movstd(unconvolvedCovariates.pupilDiameter, 10000, 'omitnan');
subplot(3,1,2); plot(covariates.timebase, rollingSTD);
subplot(3,1,3); plot(covariates.timebase, unconvolvedCovariates.rectifiedPupilChange);
