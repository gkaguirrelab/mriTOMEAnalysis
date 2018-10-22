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
freeSurferDir=$1
export SUBJECTS_DIR=freeSurferDir

bbregister --s TOME_3003 --mov ~/Downloads/TOME_3003/T1w/T1w1_gdc.nii.gz --reg ~/Desktop/register_bashTest.dat --t1 --init-fsl

mri_label2vol --label ~/Downloads/TOME_3003/T1w/TOME_3003/label/lh.V1.label --temp ~/Downloads/TOME_3003/T1w/T1w1_gdc.nii.gz --o ~/Desktop/lh_v1_register.nii.gz --reg ~/Desktop/register.dat

mri_vol2vol --mov ~/Desktop/lh_v1_register.nii.gz --targ ~/Downloads/TOME_3003_functional/rfMRI_REST_AP_Run1/rfMRI_REST_AP_Run1_gdc.nii.gz --o ~/Desktop/lh_v1_register_restAsTarg_identity_nearest.nii.gz --regheader --interp nearest