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

runName=rfMRI_REST_AP_Run1_gdc.nii.gz

bbregister --s $subjectID --mov $anatDir/T1w1_gdc.nii.gz --reg $outputDir/${subjectID}_register.dat --t1 --init-fsl

mri_label2vol --label $freeSurferDir/${subjectID}/label/lh.V1.label --temp $anatDir/T1w1_gdc.nii.gz --o $outputDir/${subjectID}_lh_v1_register.nii.gz --reg $outputDir/${subjectID}_register.dat

mri_vol2vol --mov $outputDir/${subjectID}_lh_v1_register.nii.gz --targ $functionalDir/${runName} --o $outputDir/${subjectID}_lh_v1_register_restAsTarg_identity_nearest.nii.gz --regheader --interp nearest