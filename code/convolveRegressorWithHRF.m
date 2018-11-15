function [convolvedRegressor] = convolveRegressorWithHRF(regressorTimeSeries, regressorTimebase)

startingRegressorValue = regressorTimeSeries(1);
responseStruct.values = regressorTimeSeries' - startingRegressorValue;
responseStruct.timebase = regressorTimebase;

% convolve with HRF
hrfParams.gamma1 = 6;   % positive gamma parameter (roughly, time-to-peak in secs)
hrfParams.gamma2 = 12;  % negative gamma parameter (roughly, time-to-peak in secs)
hrfParams.gammaScale = 10; % scaling factor between the positive and negative gamma componenets

kernelStruct.timebase=linspace(0,15999,16000);

% The timebase is converted to seconds within the function, as the gamma
% parameters are defined in seconds.
hrf = gampdf(kernelStruct.timebase/1000, hrfParams.gamma1, 1) - ...
    gampdf(kernelStruct.timebase/1000, hrfParams.gamma2, 1)/hrfParams.gammaScale;
kernelStruct.values=hrf;

% Normalize the kernel to have unit amplitude
[ kernelStruct ] = normalizeKernelArea( kernelStruct );
temporalFit = tfeIAMP('verbosity','none');

[convResponseStruct,resampledKernelStruct] = temporalFit.applyKernel(responseStruct,kernelStruct);

convolvedRegressor = convResponseStruct.values + startingRegressorValue;

end