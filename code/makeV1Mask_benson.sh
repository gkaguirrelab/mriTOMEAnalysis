#!/bin/bash

## set up the environment for FreeSurfer and FSL (which is necessary for registration)
export FREESURFER_HOME=/Applications/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh


# FSL Setup
FSLDIR=/usr/local/fsl
PATH=${FSLDIR}/bin:${PATH}
export FSLDIR PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

# set up the FreeSurfer data lives
freeSurferDir=$3
export SUBJECTS_DIR=$freeSurferDir

subjectID=$1
anatDir=$2
functionalDir=$4
outputDir=$5

runName=$6


runNameLong=${runName}_gdc.nii.gz

#bbregister --s $subjectID --mov $anatDir/T1w1_gdc.nii.gz --reg $outputDir/${subjectID}_register.dat --t1 --init-fsl
flirt -in ~/Downloads/TOME_3040_T1.nii.gz -ref ~/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3040/T1w1_gdc.nii.gz -omat ~/Downloads/flirtRegistration -out ~/Downloads/bensonT1_registerdTo_HCPT1.nii.gz

flirt -in ~/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3040/mask_area_V1_ecc_0_to_20.nii.gz -ref ~/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3040/T1w1_gdc.nii.gz -out ~/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3040/mask_area_V1_ecc_0_to_20_registeredToFunctional.nii.gz -init ~/Downloads/flirtRegistration -applyxfm



#mri_vol2vol --mov $outputDir/mask_area_V1_ecc_0_to_20.nii.gz --targ $functionalDir/${runNameLong} --o $outputDir/${subjectID}_${runName}_benson_registeredToFunctional.nii.gz --reg $outputDir/${subjectID}_register.dat --interp nearest

# fmri prep stuff below
flirt -in ~/Downloads/TOME_3040_T1.nii.gz -ref ~/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3040/sub-TOME3040_T1w_preproc.nii.gz -omat ~/Downloads/flirtRegistration_fmriPrep -out ~/Downloads/bensonT1_registerdTo_fmriPrep.nii.gz

flirt -in ~/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3040/mask_area_V1_ecc_0_to_20.nii.gz -ref ~/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3040/sub-TOME3040_ses-Session2_task-tfMRIFLASHAP_run-1_bold_space-T1w_preproc.nii.gz -out ~/Dropbox-Aguirre-Brainard-Lab/MELA_analysis/mriTOMEAnalysis/flywheelOutput/TOME_3040/mask_area_V1_ecc_0_to_20_registeredToFunctional_fmriPrep.nii.gz -init ~/Downloads/flirtRegistration_fmriPrep -applyxfm
