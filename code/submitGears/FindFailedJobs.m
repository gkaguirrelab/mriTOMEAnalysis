% Find failed jobs, perhaps so they can be retried

gearName = 'forwardModel';
modelClass = 'eventGain';

%% Instantiate the flywheel object
fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));

% Get a list of all failed gears that meet criteria

if ~isempty(modelClass)
    jobList = fw.jobs.find(...
        'state=failed',...
        ['gear_info.name=' lower(gearName)],...
        ['config.config.modelClass="' modelClass '"']);
else
    jobList = fw.jobs.find(...
        'state=failed',...
        ['gear_info.name=' gearName]);
end