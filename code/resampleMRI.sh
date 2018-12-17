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
#freeSurferDir=$4
#export SUBJECTS_DIR=$freeSurferDir

inputFile=$1
targetFile=$2
outputFile=$3


runNameLong=${runName}_native.nii.gz

mri_vol2vol --mov ${inputFile} --targ ${targetFile} --o ${outputFile} --regheader --interp nearest
