function [ grayMatterMask ] = makeGrayMatterMask(subjectID, varargin)
p = inputParser; p.KeepUnmatched = true;
p.addParameter('anatDir',fullfile(getpref('mriTOMEAnalysis', 'TOME_analysisPath'), '/mriTOMEAnalysis/flywheelOutput/', subjectID), @isstring);
p.parse(varargin{:});

aparcAsegFile = fullfile(p.Results.anatDir, [subjectID '_aparc+aseg.nii.gz']);
grayMatterMaskFile = fullfile(p.Results.anatDir, [subjectID '_GM.nii.gz']);


system(['export FREESURFER_HOME=/Applications/freesurfer; source $FREESURFER_HOME/SetUpFreeSurfer.sh; mri_binarize --i ' aparcAsegFile ' --gm --o ' grayMatterMaskFile]);
grayMatterMask = MRIread(grayMatterMaskFile);

end