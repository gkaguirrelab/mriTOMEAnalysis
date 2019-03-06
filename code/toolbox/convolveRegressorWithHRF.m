function [convolvedRegressorTimeSeries] = convolveRegressorWithHRF(regressorTimeSeries, regressorTimebase)
% Convolve regressor with hemodynamic response function (HRF)
%
% Syntax:
%  [convolvedRegressor] = convolveRegressorWithHRF(regressorTimeSeries, regressorTimebase)
%
% Description:
%  This routine performs convolution between a regressor time series and
%  the canonical HRF. First, the canonical HRF is created as a difference
%  of gaussians. Next, a convolution is performed between the regressor
%  time series and this HRF kernel. This convolution is performed by the
%  tfe.
%
% Inputs:
%  regressorTimeSeries             - a 1 x n vector, where n refers to the
%                                    number of observations of our
%                                    regressor of interest
%  regressorTimebase               - a 1 x n vector, where each value of n
%                                    refers to the time at which that
%                                    observation of regressorTimeSeries was
%                                    captured
%
% Outputs:
%  convolvedRegressorTimeSeries    - a 1 x n vector, where n refers to the
%                                    number of observations of our regressor
%                                    of interest, following the convolution

%% set up packet
responseStruct.values = regressorTimeSeries;
responseStruct.timebase = regressorTimebase;

%% Create canonical HRF
% convolve with HRF
hrfParams.gamma1 = 6;   % positive gamma parameter (roughly, time-to-peak in secs)
hrfParams.gamma2 = 12;  % negative gamma parameter (roughly, time-to-peak in secs)
hrfParams.gammaScale = 10; % scaling factor between the positive and negative gamma componenets

kernelStruct.timebase=linspace(0,19999,20000);

% The timebase is converted to seconds within the function, as the gamma
% parameters are defined in seconds.
hrf = gampdf(kernelStruct.timebase/1000, hrfParams.gamma1, 1) - ...
    gampdf(kernelStruct.timebase/1000, hrfParams.gamma2, 1)/hrfParams.gammaScale;
kernelStruct.values=hrf;

% Normalize the kernel to have unit amplitude
[ kernelStruct ] = normalizeKernelArea( kernelStruct );


%% Perform convolution between HRF and regressor
% instantiate tfe
temporalFit = tfeIAMP('verbosity','none');

% do convolution
[convResponseStruct,resampledKernelStruct] = temporalFit.applyKernel(responseStruct,kernelStruct);

% adjust back to the original starting value
convolvedRegressorTimeSeries = convResponseStruct.values;

end