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
structuralName=$7


runNameLong=${runName}_native.nii.gz

bbregister --s $subjectID --mov $anatDir/${structuralName}.nii.gz --reg $outputDir/${subjectID}_register.dat --t1 --init-fsl

mri_label2vol --label $freeSurferDir/${subjectID}/label/lh.V1.label --temp $anatDir/${structuralName}.nii.gz --o $outputDir/${subjectID}_${runName}_lh_v1_registeredToAnatomical.nii.gz --reg $outputDir/${subjectID}_register.dat
mri_label2vol --label $freeSurferDir/${subjectID}/label/rh.V1.label --temp $anatDir/${structuralName}.nii.gz --o $outputDir/${subjectID}_${runName}_rh_v1_registeredToAnatomical.nii.gz --reg $outputDir/${subjectID}_register.dat



mri_vol2vol --mov $outputDir/${subjectID}_${runName}_lh_v1_registeredToAnatomical.nii.gz --targ $functionalDir/${runNameLong} --o $outputDir/${subjectID}_${runName}_lh_v1_registeredToFunctional.nii.gz --regheader --interp nearest
mri_vol2vol --mov $outputDir/${subjectID}_${runName}_rh_v1_registeredToAnatomical.nii.gz --targ $functionalDir/${runNameLong} --o $outputDir/${subjectID}_${runName}_rh_v1_registeredToFunctional.nii.gz --regheader --interp nearest