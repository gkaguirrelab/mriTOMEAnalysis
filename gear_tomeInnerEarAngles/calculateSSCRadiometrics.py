import os
import pandas as pd

def calculateSSCRadiometrics(subject_struct, template, left_ear_warp, right_ear_warp, inner_ear_L, inner_ear_A, inner_ear_P, workdir, outputdir, ants_path='', fsl_path=''):
    
    # Create workdir and outputdir if it doesn't exist
    if os.path.isdir(workdir):
        os.system('mkdir {workdir}')
    if os.path.isdir(outputdir):
        os.system('mkdir {outputdir}')
                
    # Move masks back to subject left ear
    transform_command = os.path.join(ants_path, 'antsApplyTransforms')
    inner_ear_L_warped_left = os.path.join(workdir, 'inner_ear_L_warped_left.nii.gz')
    inner_ear_A_warped_left = os.path.join(workdir, 'inner_ear_A_warped_left.nii.gz')
    inner_ear_P_warped_left = os.path.join(workdir, 'inner_ear_P_warped_left.nii.gz')  
    warped_full = os.path.join(workdir, 'fullearwarp.nii.gz')
    os.system(f'{transform_command} -d 3 -i {inner_ear_L} -r {subject_struct} -n NearestNeighbor -t {left_ear_warp} -o {inner_ear_L_warped_left}')
    os.system(f'{transform_command} -d 3 -i {inner_ear_A} -r {subject_struct} -n NearestNeighbor -t {left_ear_warp} -o {inner_ear_A_warped_left}')    
    os.system(f'{transform_command} -d 3 -i {inner_ear_P} -r {subject_struct} -n NearestNeighbor -t {left_ear_warp} -o {inner_ear_P_warped_left}')    
    os.system(f'{transform_command} -d 3 -i {template} -r {subject_struct} -t {left_ear_warp} -o {warped_full}')
    
    # Move masks back to subject right ear    
    inner_ear_L_warped_right = os.path.join(workdir, 'inner_ear_L_warped_right.nii.gz')
    inner_ear_A_warped_right = os.path.join(workdir, 'inner_ear_A_warped_right.nii.gz')
    inner_ear_P_warped_right = os.path.join(workdir, 'inner_ear_P_warped_right.nii.gz') 
    os.system(f'{transform_command} -d 3 -i {inner_ear_L} -r {subject_struct} -n NearestNeighbor -t {right_ear_warp} -o {inner_ear_L_warped_right}')
    os.system(f'{transform_command} -d 3 -i {inner_ear_A} -r {subject_struct} -n NearestNeighbor -t {right_ear_warp} -o {inner_ear_A_warped_right}')    
    os.system(f'{transform_command} -d 3 -i {inner_ear_P} -r {subject_struct} -n NearestNeighbor -t {right_ear_warp} -o {inner_ear_P_warped_right}')       
    
    # Crop these masks from the T2 image left ear
    fsl_crop_images = os.path.join(fsl_path, 'fslmaths')
    inner_ear_L_cropped_left = os.path.join(outputdir, 'inner_ear_L_cropped_left.nii.gz')
    inner_ear_A_cropped_left = os.path.join(outputdir, 'inner_ear_A_cropped_left.nii.gz')
    inner_ear_P_cropped_left = os.path.join(outputdir, 'inner_ear_P_cropped_left.nii.gz')  
    os.system(f'{fsl_crop_images} {subject_struct} -mas {inner_ear_L_warped_left} {inner_ear_L_cropped_left}')
    os.system(f'{fsl_crop_images} {subject_struct} -mas {inner_ear_A_warped_left} {inner_ear_A_cropped_left}')
    os.system(f'{fsl_crop_images} {subject_struct} -mas {inner_ear_P_warped_left} {inner_ear_P_cropped_left}')
    
    # Crop these masks from the T2 image right ear 
    inner_ear_L_cropped_right = os.path.join(outputdir, 'inner_ear_L_cropped_right.nii.gz')
    inner_ear_A_cropped_right = os.path.join(outputdir, 'inner_ear_A_cropped_right.nii.gz')
    inner_ear_P_cropped_right = os.path.join(outputdir, 'inner_ear_P_cropped_right.nii.gz')  
    os.system(f'{fsl_crop_images} {subject_struct} -mas {inner_ear_L_warped_right} {inner_ear_L_cropped_right}')
    os.system(f'{fsl_crop_images} {subject_struct} -mas {inner_ear_A_warped_right} {inner_ear_A_cropped_right}')
    os.system(f'{fsl_crop_images} {subject_struct} -mas {inner_ear_P_warped_right} {inner_ear_P_cropped_right}')    
    
    # Extract values 
    val_ra_L_right = os.popen('%s %s -M' % (os.path.join(fsl_path, 'fslstats'), inner_ear_L_cropped_right)).read()
    val_ra_A_right = os.popen('%s %s -M' % (os.path.join(fsl_path, 'fslstats'), inner_ear_A_cropped_right)).read()
    val_ra_P_right = os.popen('%s %s -M' % (os.path.join(fsl_path, 'fslstats'), inner_ear_P_cropped_right)).read()
    val_ra_L_right = float(val_ra_L_right)
    val_ra_A_right = float(val_ra_A_right)
    val_ra_P_right = float(val_ra_P_right)
    val_ra_L_left = os.popen('%s %s -M' % (os.path.join(fsl_path, 'fslstats'), inner_ear_L_cropped_left)).read()
    val_ra_A_left = os.popen('%s %s -M' % (os.path.join(fsl_path, 'fslstats'), inner_ear_A_cropped_left)).read()
    val_ra_P_left = os.popen('%s %s -M' % (os.path.join(fsl_path, 'fslstats'), inner_ear_P_cropped_left)).read()
    val_ra_L_left = float(val_ra_L_left)
    val_ra_A_left = float(val_ra_A_left)
    val_ra_P_left = float(val_ra_P_left)
    data = [['L_right', val_ra_L_right], ['A_right', val_ra_A_right], ['P_right', val_ra_P_right], ['L_left', val_ra_L_left], ['A_left', val_ra_A_left], ['P_left', val_ra_P_left]]
    df = pd.DataFrame(data, columns = ['Position', 'Value'])
    df.set_index('Position', inplace=True)
    df.to_csv(os.path.join(outputdir, 'SSC_mean_intensity.csv'))
