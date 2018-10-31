#!/bin/bash

# FSL Setup
FSLDIR=/usr/local/fsl
PATH=${FSLDIR}/bin:${PATH}
export FSLDIR PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

subjectID=$1
anatDir=$2
functionalDir=$3
outputDir=$4
runName=$5

flirt -interp spline -in ${anatDir}/T1w_acpc_dc_restore.nii.gz -ref ${anatDir}/T1w_acpc_dc_restore.nii.gz -applyisoxfm 2 -o ${outputDir}/T1w_acpc_dc_restore.2.nii.gz

applywarp --interp=spline -i ${functionalDir}/${runName}_mni.nii.gz -r ${outputDir}/T1w_acpc_dc_restore.2.nii.gz -w ${anatDir}/standard2acpc_dc.nii.gz -o ${outputDir}/${runName}_native.nii.gz