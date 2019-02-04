function [ bandpassedStruct ] = bandpassFilterTimeseries(inputStruct, filterRange)
% Bandpass filter time series data
%
% Syntax: 
%  [ bandpassedStruct ] = bandpassFilterTimeseries(inputStruct, filterRange)
%
% Description:
%  This function will bandpass filter the inputted time series struct
%  according to the inputted filter range. That is signals oscillating
%  outside of the filterRange will be removed from the inputStruct to yield
%  the bandpassedStruct.
%
% Inputs:
%   inputStruct           - Structure with the fields timebase and values.
%                           Note that the timebase is required to be in
%                           units of msec.
%   filterRange           - a 1x2 vector containing numbers, where each
%                           number specifies the lower and upper limit of
%                           the desired bandpassed filter, in Hz. To be
%                           clear, only signals that oscillate at
%                           frequencies within this range will make it
%                           through to the bandpassedStruct.
% 
% Outputs:
%   bandpassedStruct      - Structure with the fields timebase and values.
%                           his represents the filtered time series.
%
% Example: 
% Let's create a signal that consists of two oscillations: 10 Hz, and 20 Hz. We
% will out filter out the 20 Hz oscillation, passing through only the 10 Hz
% signal.
%{
    % creating the signal
    tenHertzOscillation = sin(timebase*10/1000*2*pi);
    twentyHertzOscillation = sin(timebase*20/1000*2*pi);
    
    % stashing it in a struct
    inputStruct.timebase = timebase;
    inputStruct.values = tenHertzOscillation + twentyHertzOscillation;

    % filter out anything outside the range of 0-15 Hz
    [ bandpassedStruct ] = bandpassFilterTimeseries(inputStruct, [0 15]);

    % create power spectrum distribution to demonstrate efficacy of routine
    psdStructPreFilter = calcOneSidedPSD(inputStruct,'meanCenter',true);
    psdStructPostFilter = calcOneSidedPSD(bandpassedStruct,'meanCenter',true);

    % plot the results to show how we've done
    figure;
    subplot(2,2,1);
    plot(inputStruct.timebase, inputStruct.values)
    xlabel('Time (ms)');
    ylabel('Response');
    title('Original Signal');
    xlim([0 1000])

    subplot(2,2,2);
    semilogx(psdStructPreFilter.timebase,psdStructPreFilter.values);
    xlabel('Frequency (Hz)')
    ylabel('Power')
    title('Original PSD')

    subplot(2,2,3);
    plot(bandpassedStruct.timebase, bandpassedStruct.values);
    xlabel('Time (ms)');
    ylabel('Response');
    title('Filtered Signal');
    xlim([0 1000])

    subplot(2,2,4);
    semilogx(psdStructPostFilter.timebase,psdStructPostFilter.values);
    xlabel('Frequency (Hz)')
    ylabel('Power')
    title('Filtered PSD, with 20Hz component removed')
%}

%% need to interpolate the inputStruct over NaN values, 
% otherwise some functions are unhappy (I think calcOneSidedPSD is one function that
% doesn't like NaNs, but there might be others). We'll use piecewise linear
% interpolation to perform this.

% identify NaN values
notNaN = ~isnan(inputStruct.values);
% perform interpolation
myFit = fit(inputStruct.timebase(notNaN)', inputStruct.values(notNaN)', 'linearinterp');
% update inputStruct with interpolated values
inputStruct.values = myFit(inputStruct.timebase);

%% perform the filtering
% create time series object
ts = timeseries(inputStruct.values,inputStruct.timebase);
% perform the filter on that time series object, with desired filter range
tsOut = idealfilter(ts,[filterRange(1)/1000 filterRange(2)/1000],'pass');
% reshape the output
k=permute(tsOut.Data,[1 3 2]);
% stash it in a new packet
bandpassedStruct.timebase = tsOut.Time';
bandpassedStruct.values = k'+nanmean(inputStruct.values);

end