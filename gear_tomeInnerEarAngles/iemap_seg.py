#!/anaconda3/bin/python3

import sys
print (sys.path)

import os, vtk, time, csv
os.environ["PYTHONPATH"] = '/anaconda3/bin/python3'
from vtk.util.numpy_support import numpy_to_vtk, vtk_to_numpy
from antsRegistration import registerImage, makeDiagnosticPlot
import SimpleITK as sitk
import numpy as np
import pandas as pd

module_dir = os.path.abspath(os.path.dirname(__file__))

def readFidListToLPSCoords(fid_csv_file):
    # read fiducial csv file
    with open(fid_csv_file, "r", encoding="utf-8") as f:
        fids_content = f.read().strip()

    # extract rows
    columns = "id,x,y,z,ow,ox,oy,oz,vis,sel,lock,label,desc,associatedNodeID".split(",")
    pointsList = [dict(zip(columns, l.split(","))) for l in fids_content.splitlines() if not l.startswith("#")]
    # from RAS to LPS
    pointsListLPS = [ { "label":row['label'],"coords":(-float(row["x"]),-float(row["y"]),float(row["z"])) } for row in pointsList]
    return pointsListLPS

def readSlicerAnnotationFiducials(ff,convert_to_lps=False,set_index_to_label=False):
    df_fids = pd.read_csv(ff,
                       comment='#',
                       header=None,
                       names=['id','x','y','z','ow','ox','oy','oz','vis','sel','lock','label','desc','associatedNodeID'],
                       engine='python')
    if convert_to_lps:
        df_fids.loc[:,['x','y']] *= -1.0
    if set_index_to_label:
        df_fids.set_index('label',inplace=True)
    return df_fids

def writeSlicerAnnotationFiducials(df_fids, ff_fids_out, convert_to_ras=False):
    # if index is set to 'label' column, switch to 'id' column
    if df_fids.index.name=='label':
        # break reference
        df_fids = df_fids.copy()
        # re-index
        df_fids.reset_index(level=0, inplace=True)
        # re-order columns to spec
        col_order = ['id','x','y','z','ow','ox','oy','oz','vis','sel','lock','label','desc','associatedNodeID']
        df_fids = df_fids[col_order]
        df_fids.set_index('id', inplace=True)
    # flip x/y to switch from LPS to RAS (or vice versa)
    if convert_to_ras:
        df_fids = df_fids.copy()
        df_fids.loc[:,['x','y']] *= -1.0
    f = open(ff_fids_out, 'w')
    f.write('# Markups fiducial file version = 4.11\n')
    f.write('# CoordinateSystem = 0\n')
    f.write('# columns = id,x,y,z,ow,ox,oy,oz,vis,sel,lock,label,desc,associatedNodeID\n')
    f.close()
    f = open(ff_fids_out, 'a')
    df_fids.to_csv(f, header=False, line_terminator='\n')
    f.close()

def resampleVolumeByTransform(trf,vol,ref_vol,interpolation=sitk.sitkBSpline):
    resampler = sitk.ResampleImageFilter()
    if trf:
        resampler.SetTransform(trf)
    resampler.SetReferenceImage(ref_vol)
    resampler.SetInterpolator(interpolation)
    return resampler.Execute(vol)

def writeFidListFromLPSCoords(fid_csv_file_path, labeledPoints):
    with open(fid_csv_file_path, "w", encoding="utf-8") as f:
        f.write("# Markups fiducial file version = 4.11\n")
        f.write("# CoordinateSystem = 0\n")
        f.write("# columns = id,x,y,z,ow,ox,oy,oz,vis,sel,lock,label,desc,associatedNodeID")
        for i, p in enumerate(labeledPoints):
            x,y,z = p["coords"]
            # convert LPS to RAS
            x,y = -x, -y
            # write line
            f.write("\n{},{},{},{},0,0,0,1,1,1,0,{},,".format(i, x, y, z, p["label"]))

def transformPointListByTransform(trf,fid_csv_input_file,fid_csv_output_file, flipPoints_LR = False):
    flip_LR = sitk.AffineTransform([-1,0,0,0,1,0,0,0,1],[0,0,0],[0,0,0])
    points = readFidListToLPSCoords(fid_csv_input_file)
    if flipPoints_LR:
        points = [{"coords": flip_LR.TransformPoint(p["coords"]), "label": p["label"]} for p in points]
    # transform points
    points = [ {"coords":trf.TransformPoint(p["coords"]),"label":p["label"]} for p in points]
    # write back transformed points
    writeFidListFromLPSCoords(fid_csv_output_file, points)

def transformVTKMeshByTransform(trf, vtkMesh_input_file, vtkMesh_output_file, flipPoints_LR=False):
    flip = sitk.AffineTransform([-1,0,0,0,1,0,0,0,1],[0,0,0],[0,0,0])

    reader = vtk.vtkGenericDataObjectReader()
    reader.SetFileName(vtkMesh_input_file)
    reader.Update()

    obj = reader.GetOutput()
    points = obj.GetPoints()
    data = points.GetData()

    np_data = vtk_to_numpy(data)
    np_data_out = np.empty_like(np_data)
    for i,row in enumerate(np_data):
        px,py,pz = np.asarray(row,dtype=float)
        px,py = -px,-py
        if flipPoints_LR:
            px, py, pz = flip.TransformPoint([px,py,pz])
        px,py,pz = trf.TransformPoint([px, py, pz])
        np_data_out[i,:] = [-px,-py,pz]

    points.SetData(numpy_to_vtk(np_data_out, deep=True))
    points.Modified()
    obj.Modified()

    writer = vtk.vtkGenericDataObjectWriter()
    writer.SetFileName(vtkMesh_output_file)
    writer.SetInputDataObject(obj)
    writer.UpdateDataObject()
    writer.Update()
    writer.Write()

def buildTrfByPath(affine_path,deform_path,deformInverse_path):
    print('buildTrfByPath: Building transforms from:')
    for pn in [affine_path,deform_path,deformInverse_path]:
        print(pn)
    # affine
    trfAffine = sitk.ReadTransform(affine_path)
    # def / def-inverse
    trfDeform = sitk.DisplacementFieldTransform(sitk.ReadImage(deform_path))
    success = trfDeform.SetInverseDisplacementField(sitk.ReadImage(deformInverse_path))
    trfInvDeform = sitk.DisplacementFieldTransform(sitk.ReadImage(deformInverse_path))
    success = trfInvDeform.SetInverseDisplacementField(sitk.ReadImage(deform_path))
    # forward composite
    # Order as follows ---wrong: reverse transform order as follows: [t1, t2] => t1(t2(x))
    trfMain = sitk.CompositeTransform(3)
    trfMain.AddTransform(trfAffine)
    trfMain.AddTransform(sitk.DisplacementFieldTransform(sitk.ReadImage(deform_path)))
    # inverse composite
    trfMainInv = sitk.CompositeTransform(3)
    trfMainInv.AddTransform(sitk.DisplacementFieldTransform(sitk.ReadImage(deformInverse_path)))
    trfMainInv.AddTransform(trfAffine.GetInverse())
    return trfMain, trfMainInv

def moveTemplateItemToOrigin(item,coords,flip=False):
    trfL_flip = sitk.AffineTransform([-1, 0, 0, 0, 1, 0, 0, 0, 1], [0, 0, 0], [0, 0, 0])

    # deep copy image
    item_copy = sitk.GetImageFromArray(sitk.GetArrayFromImage(item))
    item_copy.CopyInformation(item)
    if flip:
        item_copy = resampleVolumeByTransform(trfL_flip,item_copy,item_copy)

    # move origin to coords
    item_copy.SetOrigin(np.asarray(item_copy.GetOrigin()) + coords)
    return item_copy

def registerInnerEar(config):
    # full filepaths of transforms for full-head, and inner ear location fiducials
    #config['trf_fullhead_atl_to_sub']
    #config['trf_fullhead_atl_to_sub_inv']
    # read localized inner ear positionsa
    innerEarPoints = readFidListToLPSCoords(config['fids_innerear_locations'])
    #innerEarPointL = list(filter(lambda p:"left" in p['label'],innerEarPoints))[0]["coords"]
    #innerEarPointR = list(filter(lambda p:"right" in p['label'],innerEarPoints))[0]["coords"]
    
    # read template
    matching_template_filepaths = {
        "T2":   os.path.join(module_dir, "data", "InnerEarAtlas", "vol_InnerEarAtlas_Template_T2.nii.gz"),
        "CISS": os.path.join(module_dir, "data", "InnerEarAtlas", "vol_InnerEarAtlas_Template_CISS.nii.gz"),
        "T1":   os.path.join(module_dir, "data", "InnerEarAtlas", "vol_InnerEarAtlas_Template_T1.nii.gz"),
    }
    
    # NOTE: IEMap has a much smaller FOV than subject vols (center-crop around IE structures)
    # therefore, we have to register the subject onto IEMap (compared to fulle-head registration)
    # we then take the inverse of the computed transformation to transform IEMap annotations into subject space
    moving_files_fh = config['input_ie_volumes']
    fixed_files_fh  = [matching_template_filepaths[k] for k in config['matching_template_modalities_ie']]
    
    df_fids = readSlicerAnnotationFiducials(config['fids_innerear_locations'],
                                            convert_to_lps=True,
                                            set_index_to_label=True)
    
    for idx, side in enumerate(['right','left']):
        # compute the initial transform (from IEMap to subject)
        # - translate from location of inner ear fiducial (computed previously) to origin (IEMap is 0/0/0-centered)
        # - at origin, flip horizontally (only for left inner ear, as IEMap represents a right-inner-ear-orientation)
        # - with SimpleITK, we need to store the inverted transform
        if side == 'left':
            M_flipLR = np.diag([-1.0,1.0,1.0,1.0])
        else:
            M_flipLR = np.diag([1.0,1.0,1.0,1.0])
        M_trans_innerear = np.eye(4)
        M_trans_innerear[0:3,3] = -1.0 * df_fids.loc['fid_innerear_'+side,['x','y','z']].values
        M_init = np.dot(M_flipLR, M_trans_innerear)
        trf_init = sitk.AffineTransform(list(M_init[0:3,0:3].ravel()),
                                        list(M_init[0:3,3].ravel()),
                                        [0,0,0])
        ff_trf_init = os.path.join(config['output_dir'], 
                                   config['output_prefix']+'trf_Subject_to_IEMap_%s_Init.mat'%side)
        sitk.WriteTransform(trf_init.GetInverse(),ff_trf_init)
        print("\nRun inner ear registration: %s side"%side)
        t0 = time.time()
        reg_result = registerImage(moving_files_fh,
                                   fixed_files_fh,
                                   store_to=config['output_dir'],
                                   store_to_prefix=config['output_prefix']+'trf_Subject_to_IEMap_%s_'%side,
                                   trf_type="composite",
                                   metric=['MI','CC'],
                                   speed=config['accuracy_ie'],
                                   initialMovingAffTrf=ff_trf_init,
                                   initialFixedAffTrf=None,
                                   n_cores=config['nr_cores'],
                                   verbose=True)
        
        print('\nFinished inner ear registration: %s side (Elapsed time: %0.2f sec.)'%(side,
               time.time()-t0))
    return reg_result

def localizeInnerEars(config):
    #input_head_volumes
    #matching_template_modalities_head
    #input_ie_volumes
    #matching_template_modalities_ie
    matching_template_filepaths = {
        'T1': os.path.join(module_dir, "data", "FullBrainAtlas", "vol_FullBrainAtlas_Template_T1.nii.gz"),
        'T2': os.path.join(module_dir, "data", "FullBrainAtlas", "vol_FullBrainAtlas_Template_T2.nii.gz")
        }
    
    # we register full-head(fh) atlas (moving) onto subject (fixed)
    moving_files_fh = [matching_template_filepaths[k] for k in config['matching_template_modalities_head']]
    fixed_files_fh  = config['input_head_volumes']
    
    # Run initial registration to full-head atlas
    print("Run full brain registration")
    reg_result, reg = registerImage(moving_files_fh,
                                    fixed_files_fh,
                                    store_to=config['output_dir'],
                                    store_to_prefix=config['output_prefix']+'trf_FullHeadAtlas_to_Subject_',
                                    trf_type="composite",
                                    metric=['MI','CC'],
                                    speed=config['accuracy_head'],
                                    initialMovingAffTrf=None,
                                    initialFixedAffTrf=None,
                                    n_cores=config['nr_cores'],
                                    verbose=True)
    
    # rename resulting transforms
    ff_fh_trf = reg_result["transforms_out"] #os.path.join(config['output_dir'], config['output_prefix']+"trf_FullHeadAtlas_to_Subject_Composite.h5")
    ff_fh_trf_inv = reg_result["transforms_out_inv"] #os.path.join(config['output_dir'], config['output_prefix']+"trf_FullHeadAtlas_to_Subject_InverseComposite.h5")
    # load computed inverse transform
    #trf_itk = sitk.ReadTransform(ff_fh_trf)
    trf_itk_inv = sitk.ReadTransform(ff_fh_trf_inv)
    # localize inner ear by transforming fiducials (NOTE: requires inverse (!) transform)
    fids_in = os.path.join(module_dir, "data", "FullBrainAtlas", "fids_FullBrainAtlas_InnerEarLocations.fcsv")
    fids_out = os.path.join(config['output_dir'], config['output_prefix']+"fids_InnerEarLocationsLR.fcsv")
    transformPointListByTransform(trf_itk_inv,fids_in,fids_out)
    config['trf_fullhead_atl_to_sub'] = ff_fh_trf
    config['trf_fullhead_atl_to_sub_inv'] = ff_fh_trf_inv
    config['fids_innerear_locations'] = fids_out
    return config, reg

def lstsqPlaneEstimation(pts):
    # pts need to be of dimension (Nx3)
    # pts need to be centered before estimation of normal!!
    ptsCentered = pts-np.mean(pts,axis=0)
    # do fit via SVD
    u, s, vh = np.linalg.svd(ptsCentered[:,0:3].T, full_matrices=True)
    #print(u)
    #print(s)
    #print(vh)
    normal = u[:,-1] 
    # the normal's z-direction should point towards the world z-direction
    if normal[-1]<0:
        #normal *= -1.0
        normal[-1] *= -1.0
    # Make R orthonormal
    R = u.copy() # u is already orthonormal
    # previously:
    #R = np.zeros((3,3))
    #for i in range(3):
    #    R[:,i] = u[:,i] / np.linalg.norm(u[:,i])
    #normal = u[:,-1] / np.linalg.norm(u[:,-1])
    offset = np.mean(pts[:,0:3],axis=0)
    return (normal,offset,R)

def calculatePlaneNormals(path_to_seg_output, position, side, output_folder):
    from scipy.io import savemat
    pts = []
    for sheet in os.listdir(path_to_seg_output):
        if os.path.splitext(sheet)[1] == '.fcsv' and position in sheet and side in sheet:
            with open(os.path.join(path_to_seg_output,sheet), newline='') as csvfile:
                reader = csv.reader(csvfile, delimiter=',', quotechar='|')
                for row in reader:
                    if not row[0].startswith('#'):
                        if int(row[0])<5: 
                            point = [float(row[1]), float(row[2]), float(row[3])]
                            pts.append(point)
    point_array = np.array(pts)
    normal,offset,R = lstsqPlaneEstimation(point_array)
    
    values = {'point_array':point_array, 'normal': normal, 'offset': offset, 'R': R}
    savemat(os.path.join(output_folder, side + '_' + position + '.mat'), values)
    np.save(os.path.join(output_folder, side + '_' + position + '.npy'), values)
    return (values)

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('--output_dir', type=str, help="output directory (e.g. '/data/transforms/')")
    parser.add_argument('--output_prefix', type=str, default="", help="output prefix (e.g. 'P01_AtlasToSubject_')")
    
    # input modalities for full-head and inner-ear
    # multi-input arguments (nargs='+') get parsed into a list, see: https://stackoverflow.com/a/15753721
    parser.add_argument('--input_head_volumes', dest='input_head_volumes', nargs='+', type=str,
                        help="Filepath(s) to full-head input volume(s) for inner ear localization. Several filepaths are separated with a single space.")
    parser.add_argument('--matching_template_modalities_head', dest='matching_template_modalities_head', nargs='+', type=str,
                        help="Template modality(ies) to match input volume(s) for full-head registration (from: T1, T2)")
    parser.add_argument('--input_ie_volumes', dest='input_ie_volumes', nargs='+', type=str,
                        help="Filepath(s) to inner-ear input volume(s) for inner ear segmentation. Several filepaths are separated with a single space.")
    parser.add_argument('--matching_template_modalities_ie ', dest='matching_template_modalities_ie', nargs='+', type=str,
                        help="Template modality(ies) to match input volume(s) for inner-ear segmentation (from: T1, T2, CISS)")
    
    parser.add_argument('--write-high-res-volumes',dest="highres_vol", choices=["y","n"], default="y", help="Write resampled volumes at high resolution")
    parser.add_argument('--write-high-res-labels',dest="highres_lm", choices=["y","n"], default="y", help="Write resampled labels at high resolution")
    parser.add_argument('--write-native-res-volumes',dest="nativeres_vol", choices=["y","n"], default="y", help="Write resampled volumes at native/input resolution")
    parser.add_argument('--write-native-res-labels',dest="nativeres_lm", choices=["y","n"], default="y", help="Write resampled labels at native/input resolution")
    
    parser.add_argument('--write-surfacemodels',dest="write_surfacemodels", choices=["y","n"], default="y", help="Write vtk surface models")
    parser.add_argument('--write-innerear-tag',dest="write_localization_fiducials", choices=["y","n"], default="y", help="Write fiducials from inner ear localization")
    parser.add_argument('--write-fiducials',dest="write_innerear_fiducials", choices=["y","n"], default="y", help="Write fiducial lists")
    parser.add_argument('--write-transform-fullbrain',dest="write_trf_fullbrain", choices=["y","n"], default="y", help="Write transforms from full brain registration")
    parser.add_argument('--write-transform-innerears',dest="write_trf_innerears", choices=["y","n"], default="y", help="Write transforms from inner ear registration")
    
    parser.add_argument('--accuracy_head', dest="accuracy_head", nargs='+', 
                        help="Choose accuracy vs speed for full-head registration ('accurate','better','normal','fast','debug').")
    parser.add_argument('--accuracy_ie', dest="accuracy_ie", nargs='+', 
                        help="Choose accuracy vs speed for full-head registration ('accurate','better','normal','fast','debug').")
    parser.add_argument('--nr_cores',dest="nr_cores", type=int, 
                        default=0, help="Number of cores to use for registration (default: 0 = max nr of cores)")
    parser.add_argument('--verbose',dest="verbose", type=bool,
                        default=False, help="Verbose outputs")

    # converting parser arguments to dict
    # (https://stackoverflow.com/a/35824590)
    args, extras = parser.parse_known_args()
    config = vars(args)
    print('\n')
    print(config)
    print('\n')
    
    if len(config['input_head_volumes'])!=len(config['matching_template_modalities_head']):
        print('\nInput volumes for full-head specified incorrectly. The number of --input_head_volumes (currently %d) has to match the number of --matching_template_modalities_head (currently %d).'%(len(config['input_head_volumes']),
                  len(config['matching_template_modalities_head'])))
        print('Exiting.\n')
    if len(config['input_ie_volumes'])!=len(config['matching_template_modalities_ie']):
        print('\nInput volumes for inner-ear segmentation specified incorrectly. The number of --input_head_volumes (currently %d) has to match the number of --matching_template_modalities_head (currently %d).'%(len(config['input_ie_volumes']),
                  len(config['matching_template_modalities_ie'])))
        print('Exiting.\n')
    
    if any([s not in ['T1','T2'] for s in config['matching_template_modalities_head']]):
        print('\nArguments following --matching_template_modalities_head must be either "T1" or "T2".')
        print('Exiting.\n')

    if any([s not in ['T1','T2','CISS']  for s in config['matching_template_modalities_ie']]):
        print('\nArguments following --matching_template_modalities_ie must be either "T1", "T2" or "CISS".')
        print('Exiting.\n')
        
    if len(extras)>0:
        print('Unknown arguments! Please change or remove these arguments:')
        print(extras)
        print('Exiting.')
    else:
        pass
    
    # Set the input image for plotting function and get the input head volume and IEMap patch
    input_config = config
    subjectHead = input_config['input_head_volumes'][0]
    IETemplatePatch = os.path.join(module_dir, 'data', 'InnerEarAtlas', 'vol_InnerEarAtlas_Template_T2.nii.gz')
    
    t0 = time.time()
    config, reg_fullhead = localizeInnerEars(config)
    os.remove(os.path.join(config['output_dir'],'trf_FullHeadAtlas_to_Subject_0DerivedInitialMovingTranslation.mat'))
    config['trf_fullhead_atl_to_sub'] = os.path.join(config['output_dir'],'trf_FullHeadAtlas_to_Subject_Composite.h5')
    config['trf_fullhead_atl_to_sub_inv'] = os.path.join(config['output_dir'],'trf_FullHeadAtlas_to_Subject_InverseComposite.h5')
    config['fids_innerear_locations'] = os.path.join(config['output_dir'],'fids_InnerEarLocationsLR.fcsv')
    print('\n\nreg_fullhead finished (elapsed time: %0.2f):'%(time.time()-t0))
    print('\n\n')
    
    # Save the output dir here for later since the config will be modified
    output_dir_before_reg = os.path.join(config['output_dir'])
    
    # Perform the registration 
    config, reg_innerear = registerInnerEar(config)
    
    # Get the subjectToTemplate warp for left and right
    leftComposite = os.path.join(output_dir_before_reg, 'trf_Subject_to_IEMap_left_Composite.h5')
    rightComposite = os.path.join(output_dir_before_reg, 'trf_Subject_to_IEMap_right_Composite.h5')  

    # Create directories for left and right ears and run diagnostic plot maker function
    leftEarImageOutput = os.path.join(output_dir_before_reg, 'left_ear_images')
    if not os.path.exists(leftEarImageOutput):
        os.system('mkdir {leftEarImageOutput}'.format(leftEarImageOutput=leftEarImageOutput))
    rightEarImageOutput = os.path.join(output_dir_before_reg, 'right_ear_images')
    if not os.path.exists(rightEarImageOutput):
        os.system('mkdir {rightEarImageOutput}'.format(rightEarImageOutput=rightEarImageOutput))
    
    makeDiagnosticPlot(subjectHead, IETemplatePatch, leftComposite, leftEarImageOutput)
    makeDiagnosticPlot(subjectHead, IETemplatePatch, rightComposite, rightEarImageOutput)    
    
    # Move the SSC from IEspace to subject space
    f_ant = os.path.join(module_dir,"data","InnerEarAtlas","fids_InnerEarAtlas_SSC_ant.fcsv")
    f_ccrus = os.path.join(module_dir,"data","InnerEarAtlas","fids_InnerEarAtlas_SSC_ccrus.fcsv")
    f_lat = os.path.join(module_dir,"data","InnerEarAtlas","fids_InnerEarAtlas_SSC_lat.fcsv")
    f_post = os.path.join(module_dir,"data","InnerEarAtlas","fids_InnerEarAtlas_SSC_post.fcsv")   
    output_f_ant_left = os.path.join(output_dir_before_reg, 'fids_InnerEarAtlas_SSC_ant_left.fcsv')
    output_f_ccrus_left = os.path.join(output_dir_before_reg, 'fids_InnerEarAtlas_SSC_ccrus_left.fcsv')
    output_f_lat_left = os.path.join(output_dir_before_reg, 'fids_InnerEarAtlas_SSC_lat_left.fcsv')
    output_f_post_left = os.path.join(output_dir_before_reg, 'fids_InnerEarAtlas_SSC_post_left.fcsv')
    output_f_ant_right = os.path.join(output_dir_before_reg, 'fids_InnerEarAtlas_SSC_ant_right.fcsv')
    output_f_ccrus_right = os.path.join(output_dir_before_reg, 'fids_InnerEarAtlas_SSC_ccrus_right.fcsv')
    output_f_lat_right = os.path.join(output_dir_before_reg, 'fids_InnerEarAtlas_SSC_lat_right.fcsv')
    output_f_post_right = os.path.join(output_dir_before_reg, 'fids_InnerEarAtlas_SSC_post_right.fcsv')
    
    left_trf_loaded = sitk.ReadTransform(leftComposite)
    right_trf_loaded = sitk.ReadTransform(rightComposite)
    
    transformPointListByTransform(left_trf_loaded, f_ant, output_f_ant_left)
    transformPointListByTransform(left_trf_loaded, f_ccrus, output_f_ccrus_left)    
    transformPointListByTransform(left_trf_loaded, f_lat, output_f_lat_left)
    transformPointListByTransform(left_trf_loaded, f_post, output_f_post_left)
    transformPointListByTransform(right_trf_loaded, f_ant, output_f_ant_right)
    transformPointListByTransform(right_trf_loaded, f_ccrus, output_f_ccrus_right)    
    transformPointListByTransform(right_trf_loaded, f_lat, output_f_lat_right)
    transformPointListByTransform(right_trf_loaded, f_post, output_f_post_right)
    
    # Calculate plane normals 
    plane_output = os.path.join(output_dir_before_reg, 'plane_normals')
    if not os.path.exists(plane_output):
        os.system('mkdir  %s' % plane_output)
    calculatePlaneNormals(output_dir_before_reg, 'ant', 'left', plane_output)
    calculatePlaneNormals(output_dir_before_reg, 'ant', 'right', plane_output)
    calculatePlaneNormals(output_dir_before_reg, 'post', 'left', plane_output)
    calculatePlaneNormals(output_dir_before_reg, 'post', 'right', plane_output)
    calculatePlaneNormals(output_dir_before_reg, 'lat', 'left', plane_output)
    calculatePlaneNormals(output_dir_before_reg, 'lat', 'right', plane_output)
    
# desired cmdline call
'''
iemap_seg.py \
    --input_head_modalities T2.nii.gz \
    --matching_template_modalities_head T2 \
    --input_ie_modalities T2.nii.gz CISS.nii.gz T2_space.nii.gz \
    --matching_template_modalities_ie T2 CISS T2 \
    --output_dir ./output \
    --output_prefix iemap_output_
'''