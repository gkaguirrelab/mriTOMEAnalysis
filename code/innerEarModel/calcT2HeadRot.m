clear all 

% Load Camille's measurement
ypr = readtable('C:\Users\ozenc\Desktop\YPR_values.xls');
workdir = 'C:\Users\ozenc\Desktop\workdir';
qformRots = {};

% Find tome
fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));
projects = fw.projects();
for ii = 1:length(projects)
    if strcmp('tome', projects{ii}.label)
        project = projects{ii};
    end
end

counter = 1;
for ii = 1:height(ypr)
    % Get subject name from folder names and construct plane folder path
    subjectName = ypr.Var1{ii};
 
    % Get subjects
    subjects = project.subjects();
    
    % Loop through subjects
    for sub = 1:length(subjects)
        % Get sessions if the subject ID is in the plane normal folder
        if strcmp(subjects{sub}.label, subjectName)
            sessions = subjects{sub}.sessions();
            % Loop through sessions and get acquisitions 
            for ss = 1:length(sessions)
                acquisitions = sessions{ss}.acquisitions();
                % Go through acquisitions in the sessions and get task and
                % rest fmri files.
                for aa = 1:length(acquisitions)
                    if contains(acquisitions{aa}.label, 'T2w_SPC')
                           acquisition = acquisitions{aa};    
                           files = acquisition.files();
                           % Loop through files get niftis
                           for mm = 1:length(files)
                               if strcmp(files{mm}.type, 'nifti')
                                   niftiFile = files{mm};
                                   % Download the nifti and read qform                                 
                                   downloadPath = fullfile(workdir, [subjectName '.nii.gz']);
                                   if ~isfile(downloadPath)
                                        niftiFile.download(downloadPath);
                                   end
                                   header = load_untouch_header_only(downloadPath); 
                                   qform = [header.hist.srow_x 0;
                                            header.hist.srow_y 0;
                                            header.hist.srow_z 1];
                                   scaleX = norm(qform(1:3, 1));
                                   scaleY = norm(qform(1:3, 2));
                                   scaleZ = norm(qform(1:3, 3));
                                   rotation = [qform(1,1)/scaleX  qform(1,2)/scaleY  qform(1,3)/scaleZ 0;...
                                               qform(2,1)/scaleX  qform(2,2)/scaleY  qform(2,3)/scaleZ 0;...
                                               qform(3,1)/scaleX  qform(3,2)/scaleY  qform(3,3)/scaleZ 0;...
                                                        0                 0                   0        1];
                                   eulAngles = rad2deg(rotm2eul(rotation(1:3, 1:3), 'XYZ'));
                                   if ~any(any(strcmp(qformRots, subjectName)))
                                       qformRots{counter, 1} = subjectName;
                                       qformRots{counter, 2} = eulAngles(3);
                                       qformRots{counter, 3} = eulAngles(1);
                                       qformRots{counter, 4} = eulAngles(2);
                                       counter = counter + 1;
                                   end
                               end
                           end         
                    end
                end
            end
        end
    end
end

qformRots = cell2table(qformRots);
[rYaw, pYaw] = corrcoef(ypr.Yaw, qformRots.qformRots2);
[rPitch, pPitch] = corrcoef(ypr.Pitch, qformRots.qformRots3);
[rRoll, pRoll] = corrcoef(ypr.Roll, qformRots.qformRots4);
fprintf(['Yaw correlation: r: ' num2str(rYaw(2)) ' p: ' num2str(pYaw(2)) '\n']) 
fprintf(['Pitch correlation: r: ' num2str(rPitch(2)) ' p: ' num2str(pPitch(2)) '\n'])
fprintf(['Roll correlation: r: ' num2str(rRoll(2)) ' p: ' num2str(pRoll(2)) '\n'])

%% Calculate the pitch and angle correlation
% Load data
load('C:\Users\ozenc\Desktop\normalWrtB0.mat');
ypr = readtable('C:\Users\ozenc\Desktop\YPR_values.xls');
Patient = fieldnames(normalWrtB0);
table = cell2table(Patient);
leftEarAngle = [];
rightEarAngle = []; 
for ii = 1:height(table)
    sub = table.Patient{ii};
    leftEarAngle = [leftEarAngle; normalWrtB0.(sub).rfMRI_REST_AP_Run1.leftAngle];
    rightEarAngle = [rightEarAngle; normalWrtB0.(sub).rfMRI_REST_AP_Run1.rightAngle];
end

table.('leftAngle') = leftEarAngle;
table.('rightAngle') = rightEarAngle;

% Correlation with nystagmus values
nystagmus = readtable('C:\Users\ozenc\Desktop\Ozzy.xlsx');

% Remove some rows from tables that are not part of nystagmus subjects and
% ear table
table([33, 24, 14, 6, 4, 3, 1],:) = [];
ypr([33, 24, 14, 6, 4, 3, 1],:) = [];
nystagmus([21, 4], :) = [];
comparisonTable = join(nystagmus, table);

[rPitchLeft, pPitchLeft] = corrcoef(ypr.Pitch, table.leftAngle);
[rPitchRight, pPitchRight] = corrcoef(ypr.Pitch, table.rightAngle);
[rPitchAll, pPitchAll] = corrcoef(ypr.Pitch, (table.rightAngle + table.leftAngle)/2);
fprintf(['Pitch correlation with leftEar: r: ' num2str(rPitchLeft(2)) ' p: ' num2str(pPitchLeft(2)) '\n']) 
fprintf(['Pitch correlation with rightEar: r: ' num2str(rPitchRight(2)) ' p: ' num2str(pPitchRight(2)) '\n'])
fprintf(['Pitch correlation with bothEars: r: ' num2str(rPitchAll(2)) ' p: ' num2str(pPitchAll(2)) '\n\n'])

% Left ear correlations
[r, p] = corrcoef(comparisonTable.leftAngle, comparisonTable.run1_x, 'rows', 'pairwise');
fprintf(['left ear vs. run_1: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n'])
[r, p] = corrcoef(comparisonTable.leftAngle, comparisonTable.run2_x, 'rows', 'pairwise');
fprintf(['left ear vs. run_2: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n'])    
[r, p] = corrcoef(comparisonTable.leftAngle, comparisonTable.run3_x, 'rows', 'pairwise');
fprintf(['left ear vs. run_3: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n'])
[r, p] = corrcoef(comparisonTable.leftAngle, comparisonTable.run4_x, 'rows', 'pairwise');
fprintf(['left ear vs. run_4: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n\n'])

% Right ear correlations
[r, p] = corrcoef(comparisonTable.rightAngle, comparisonTable.run1_x, 'rows', 'pairwise');
fprintf(['right ear vs. run_1: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n'])
[r, p] = corrcoef(comparisonTable.rightAngle, comparisonTable.run2_x, 'rows', 'pairwise');
fprintf(['right ear vs. run_2: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n'])    
[r, p] = corrcoef(comparisonTable.rightAngle, comparisonTable.run3_x, 'rows', 'pairwise');
fprintf(['right ear vs. run_3: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n'])
[r, p] = corrcoef(comparisonTable.rightAngle, comparisonTable.run4_x, 'rows', 'pairwise');
fprintf(['right ear vs. run_4: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n\n'])

% Average runs and average ears. 
[r,p] = corrcoef((comparisonTable.run1_x + comparisonTable.run2_x + comparisonTable.run3_x + comparisonTable.run4_x)/4, ...
                 (comparisonTable.leftAngle + comparisonTable.rightAngle)/2, 'rows', 'pairwise');
fprintf(['Both ears vs. averaged runs: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n']) 

% Average runs and average ears. Set negative sign to left ear
[r,p] = corrcoef((comparisonTable.run1_x + comparisonTable.run2_x + comparisonTable.run3_x + comparisonTable.run4_x)/4, ...
                 (-comparisonTable.leftAngle + comparisonTable.rightAngle)/2, 'rows', 'pairwise');
fprintf(['Both ears (left set to minus) vs. averaged runs: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n\n'])           


% Anterior calculations 
% Loop through files and get left and right anterior normals 
folderPath = 'C:\Users\ozenc\Desktop\ForOzzy\ForOzzy\tome';
verticalNystagmus = readtable('C:\Users\ozenc\Desktop\OzzyVertical.xlsx');
verticalNystagmus([21, 4], :) = [];
anteriorTable = {};
xAxis = [1 0 0];
for ii = 1:height(table)
    normalPath = fullfile(folderPath, table.Patient{ii});
    [lateralMRILeft, lateralMRIRight, ...
    anteriorMRILeft, anteriorMRIRight, ...
    posteriorMRILeft, posteriorMRIRight] = loadMRINormals(normalPath);
    
    anteriorTable{ii,1} = table.Patient{ii};
    anteriorTable{ii,2} = atan2(norm(cross(anteriorMRILeft,xAxis)), dot(anteriorMRILeft,xAxis));    
    anteriorTable{ii,3} = atan2(norm(cross(anteriorMRIRight,xAxis)), dot(anteriorMRIRight,xAxis));
    
end

anteriorTable = cell2table(anteriorTable);
anteriorTable = renamevars(anteriorTable,["anteriorTable1","anteriorTable2","anteriorTable3"], ...
                                         ["Patient","leftAnterior","rightAnterior"]);
                                     
% Left ear correlations
[r, p] = corrcoef(anteriorTable.leftAnterior, verticalNystagmus.run1_y, 'rows', 'pairwise');
fprintf(['left anterior vs. run_1 vertical: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n'])
[r, p] = corrcoef(anteriorTable.leftAnterior, verticalNystagmus.run2_y, 'rows', 'pairwise');
fprintf(['left anterior vs. run_2 vertical: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n'])    
[r, p] = corrcoef(anteriorTable.leftAnterior, verticalNystagmus.run3_y, 'rows', 'pairwise');
fprintf(['left anterior vs. run_3 vertical: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n'])
[r, p] = corrcoef(anteriorTable.leftAnterior, verticalNystagmus.run4_y, 'rows', 'pairwise');
fprintf(['left anterior vs. run_4 vertical: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n\n'])

% Right ear correlations
[r, p] = corrcoef(anteriorTable.rightAnterior, verticalNystagmus.run1_y, 'rows', 'pairwise');
fprintf(['right anterior vs. run_1 vertical: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n'])
[r, p] = corrcoef(anteriorTable.rightAnterior, verticalNystagmus.run2_y, 'rows', 'pairwise');
fprintf(['right anterior vs. run_2 vertical: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n'])    
[r, p] = corrcoef(anteriorTable.rightAnterior, verticalNystagmus.run3_y, 'rows', 'pairwise');
fprintf(['right anterior vs. run_3 vertical: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n'])
[r, p] = corrcoef(anteriorTable.rightAnterior, verticalNystagmus.run4_y, 'rows', 'pairwise');
fprintf(['right anterior vs. run_4 vertical: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n\n'])

% Average runs and average ears. 
[r,p] = corrcoef((verticalNystagmus.run1_y + verticalNystagmus.run2_y + verticalNystagmus.run3_y + verticalNystagmus.run4_y)/4, ...
                 (anteriorTable.leftAnterior + anteriorTable.rightAnterior)/2, 'rows', 'pairwise');
fprintf(['Both ear anterior vs. averaged vertical runs: r: ' num2str(r(2)) ' p: ' num2str(p(2)) '\n\n'])        

[rRollLeft, pRollLeft] = corrcoef(ypr.Roll, anteriorTable.leftAnterior);
[rRollRight, pRollRight] = corrcoef(ypr.Roll, anteriorTable.rightAnterior);
[rRollAll, pRollAll] = corrcoef(ypr.Roll, (anteriorTable.leftAnterior + anteriorTable.rightAnterior)/2);
fprintf(['Roll correlation with anterior leftEar: r: ' num2str(rRollLeft(2)) ' p: ' num2str(pRollLeft(2)) '\n']) 
fprintf(['Roll correlation with anterior rightEar: r: ' num2str(rRollRight(2)) ' p: ' num2str(pRollRight(2)) '\n'])
fprintf(['Roll correlation with anterior bothEars: r: ' num2str(rRollAll(2)) ' p: ' num2str(pRollAll(2)) '\n\n'])

[rRollLeft, pRollLeft] = corrcoef(ypr.Yaw, anteriorTable.leftAnterior);
[rRollRight, pRollRight] = corrcoef(ypr.Yaw, anteriorTable.rightAnterior);
[rRollAll, pRollAll] = corrcoef(ypr.Yaw, (anteriorTable.leftAnterior + anteriorTable.rightAnterior)/2);
fprintf(['Yaw correlation with anterior leftEar: r: ' num2str(rRollLeft(2)) ' p: ' num2str(pRollLeft(2)) '\n']) 
fprintf(['Yaw correlation with anterior rightEar: r: ' num2str(rRollRight(2)) ' p: ' num2str(pRollRight(2)) '\n'])
fprintf(['Yaw correlation with anterior bothEars: r: ' num2str(rRollAll(2)) ' p: ' num2str(pRollAll(2)) '\n\n'])