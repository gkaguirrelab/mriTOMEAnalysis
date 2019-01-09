clear all; close all;

% load pupil data
load('/Users/harrisonmcadams/Dropbox (Aguirre-Brainard Lab)/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3003/rfMRI_REST_AP_Run1_pupil.mat');
load('/Users/harrisonmcadams/Dropbox (Aguirre-Brainard Lab)/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3003/rfMRI_REST_AP_Run1_timebase.mat');

% interpolate the NaN values
notNan = ~isnan(pupilData.radiusSmoothed.eyePoses.values(:,4));
myFit = fit(timebase.values(notNan),pupilData.radiusSmoothed.eyePoses.values(notNan,4),'linearinterp');

% assemble packet
dataStruct.timebase = timebase.values';
dataStruct.values = myFit(dataStruct.timebase)';
psdStructPreFilter = calcOneSidedPSD(dataStruct,'meanCenter',true);

% plot PSD
plotFig = figure;
semilogx(psdStructPreFilter.timebase,psdStructPreFilter.values);
xlabel('Frequency (Hz)')
ylabel('Power')

% do the filtering
ts = timeseries(dataStruct.values,dataStruct.timebase);
tsOut = idealfilter(ts,[0.001/1000 0.01/1000],'notch');
k=permute(tsOut.Data,[1 3 2]);
filtData.timebase = tsOut.Time';
filtData.values = k;

% plot psd after filtering
psdStructPostFilter = calcOneSidedPSD(filtData,'meanCenter',true);
hold on
semilogx(psdStructPostFilter.timebase,psdStructPostFilter.values)
legend('Pre-Filtering', 'Post-Filtering')