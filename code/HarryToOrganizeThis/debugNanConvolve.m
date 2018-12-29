close all
%% Set up our packet
responseStruct.timebase = 0:1:25999;

% make delta function response struct
% responseStruct.timebase = 0:1:25999;
% responseStruct.values = zeros(1,length(responseStruct.timebase));
% responseStruct.values(2000) = 1;
% 
% % sine-wave responseStruct
% sinFunc = @sin;
% responseStruct.values = sinFunc(responseStruct.timebase/1000);

% step function responseStruct
responseStruct.values = zeros(1,length(responseStruct.timebase));
responseStruct.values(2000:4000) = 1;

% make kernel
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

%% First verify that the new method does the same thing as the old method for responses without NaNs
[convResponseStruct,resampledKernelStruct] = temporalFit.applyKernel(responseStruct,kernelStruct, 'convolveMethod', 'conv');
[convResponseStruct_nanconv,resampledKernelStruct] = temporalFit.applyKernel(responseStruct,kernelStruct, 'convolveMethod', 'nanconv');


plotFig = figure;
ax1 = subplot(1,2,1);
plot(responseStruct.timebase, responseStruct.values);
xlabel('Time')
ylabel('Response')
title('Original Response')
ylim([0 1.1]);

ax2 = subplot(1,2,2);

hold on;
plot(convResponseStruct.timebase, convResponseStruct.values);
plot(convResponseStruct_nanconv.timebase, convResponseStruct_nanconv.values);
xlabel('Time')
ylabel('Response')
title('Convolved Responses')
legend('conv', 'nanconv');

linkaxes([ax1, ax2]);

fprintf('<strong>Testing if conv and nanconv produce same output for input without NaNs:</strong>\n')
fprintf('DataHash for conv: %s\n', DataHash(convResponseStruct.values));
fprintf('DataHash for nanconv: %s\n', DataHash(convResponseStruct_nanconv.values));


%% with NaNs
% add some NaNs
responseStruct.values(3000:3500) = NaN;
[convResponseStruct_withNaNs,resampledKernelStruct] = temporalFit.applyKernel(responseStruct,kernelStruct, 'convolveMethod', 'nanconv', 'makePlots', true);

plotFig = figure;
ax1 = subplot(1,2,1);
plot(responseStruct.timebase, responseStruct.values);
xlabel('Time')
ylabel('Response')
ylim([0 1.1]);
title('Original Response, now with NaNs')

ax2 = subplot(1,2,2);
hold on;
plot(convResponseStruct.timebase, convResponseStruct.values);
plot(convResponseStruct_withNaNs.timebase, convResponseStruct_withNaNs.values)
xlabel('Time')
ylabel('Response')
title('Convolved Response')
legend('NaN-Free Response Convolved', 'NaN-Containing Response Convolved')
linkaxes([ax1, ax2]);