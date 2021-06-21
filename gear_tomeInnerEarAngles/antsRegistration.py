#!/anaconda3/bin/python3

from nipype.interfaces.ants import Registration
from distutils.spawn import find_executable
import os, shutil, tempfile, platform, imageio
import SimpleITK as sitk
import nibabel as nib
import matplotlib.pyplot as plt

def get_speed_settings(speeds):
    if isinstance(speeds, str):
        speeds = [speeds]
    number_of_iterations = []
    convergence_threshold = []
    convergence_window_size = []
    shrink_factors = []
    sigma_units = []
    smoothing_sigmas = []
    for speed in speeds:
        if speed == "very_accurate":
            number_of_iterations.append([1000, 1000, 100, 100])
            convergence_threshold.append(1.e-6)
            convergence_window_size.append(25)
            shrink_factors.append([8, 4, 2, 1])
            sigma_units.append('vox')
            smoothing_sigmas.append([4, 2, 1, 0])    
        elif speed == "accurate":
            number_of_iterations.append([1000, 100, 50, 20])
            convergence_threshold.append(1.e-6)
            convergence_window_size.append(10)
            shrink_factors.append([8, 4, 2, 1])
            sigma_units.append('vox')
            smoothing_sigmas.append([4, 2, 1, 0])
        elif speed == "better":
            number_of_iterations.append([200, 100, 30, 10])
            convergence_threshold.append(1.e-6)
            convergence_window_size.append(10)
            shrink_factors.append([8, 4, 2, 1])
            sigma_units.append('vox')
            smoothing_sigmas.append([4, 2, 1, 0])
        elif speed == "normal":
            number_of_iterations.append([100, 50, 30])
            convergence_threshold.append(1.e-6)
            convergence_window_size.append(10)
            shrink_factors.append([8, 4, 2])
            sigma_units.append('vox')
            smoothing_sigmas.append([4, 2, 1])
        elif speed == "fast":
            number_of_iterations.append([50, 25])
            convergence_threshold.append(1.e-6)
            convergence_window_size.append(10)
            shrink_factors.append([8, 4])
            sigma_units.append('vox')
            smoothing_sigmas.append([4, 2])
        elif speed == "debug":
            number_of_iterations.append([10])
            convergence_threshold.append(1.e-6)
            convergence_window_size.append(10)
            shrink_factors.append([8])
            sigma_units.append('vox')
            smoothing_sigmas.append([2])
        else:
            raise Exception("Parameter speed must be from the list: accurate, better, normal, fast, debug")
    # return dict
    config_speed = {
        'number_of_iterations': number_of_iterations,
        'convergence_threshold': convergence_threshold,
        'convergence_window_size': convergence_window_size,
        'shrink_factors': shrink_factors,
        'sigma_units': sigma_units,
        'smoothing_sigmas': smoothing_sigmas,
        }
    return config_speed

def get_metric_settings(metrics):
    if isinstance(metrics, str):
        metrics = [metrics]
    metric = []
    metric_weight = []
    radius_or_number_of_bins = []
    sampling_strategy = []
    sampling_percentage = []
    for m in metrics:
        if m == "MI":
            metric.append(m)
            metric_weight.append(1.0)
            radius_or_number_of_bins.append(32)
            sampling_strategy.append('Random')
            sampling_percentage.append(0.05)
        elif m == "CC":
            metric.append(m)
            metric_weight.append(1.0)
            radius_or_number_of_bins.append(3)
            sampling_strategy.append('None')
            sampling_percentage.append(0.1)
        else:
            raise Exception("Registration metrics have to be either 'MI' or 'CC'.")
    config_metric = {'metric': metric,
                     'metric_weight': metric_weight,
                     'radius_or_number_of_bins': radius_or_number_of_bins,
                     'sampling_strategy': sampling_strategy,
                     'sampling_percentage': sampling_percentage
                     }
    print('\nconfig_metric:')
    print(config_metric)
    print('\n')
    return config_metric

def registerImage(moving_vols,
                  fixed_vols,
                  store_to,
                  store_to_prefix='',
                  trf_type="affine",
                  metric="MI",
                  speed="fast",
                  initialMovingAffTrf=None,
                  initialFixedAffTrf=None,
                  n_cores=8,
                  verbose=False):
    """
    Perform a registration using ANTs
    :param moving_vols: moving volumes (single filepath, or list of filepaths)
    :param fixed_vols: fixed volumes (single filepath, or list of filepaths)
    :param store_to: path to directory to store output
    :param type: string, "affine", "rigid", "deformable"
    :param metric: string "CC","MI"
    :param speed: string, "accurate","better","normal","fast","debug"
    :param initialMovingAffTrf: itk Transform, moving
    :param initialFixedAffTrf: itk Transform, fixed
    """
    
    # prepare environment / path
    if False:
        main_dir = os.path.abspath(os.path.dirname(__file__))
        path_dir = os.path.join(main_dir,"bin")
        lib_dir = os.path.join(main_dir,"lib")
        tmp_dir = os.path.join(main_dir,"ants_tmp")
        cwd_old = os.getcwd()
        
        has_ANTs = bool(find_executable("antsRegistration"))
        has_PATH = "PATH" in os.environ
        if has_PATH:
            PATH_old = os.environ["PATH"]
        if not has_ANTs:
            os.environ["PATH"] = (os.environ["PATH"] + os.pathsep if has_PATH else "") + path_dir
            if not find_executable("antsRegistration"):
                raise Exception("No executable file \"antsRegistration\" in PATH.")
                
        has_LD_LIBRARY = "LD_LIBRARY_PATH" in os.environ
        if has_LD_LIBRARY:
            LD_LIBRARY_old = os.environ["LD_LIBRARY_PATH"]
        if not has_ANTs:
            os.environ["LD_LIBRARY_PATH"] = (os.environ["LD_LIBRARY_PATH"] + os.pathsep if has_LD_LIBRARY else "") + lib_dir
            
        has_NUMBERCORES = "ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS" in os.environ
        if has_NUMBERCORES:
            NUMBERCORES_old = os.environ["ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS"]
        os.environ["ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS"] = "{}".format(n_cores)
    
    # create a nipype antsRegistration object
    reg = Registration()
    # setup registration parameters
    if n_cores==0:
        n_cores = os.cpu_count()
    reg.num_threads = n_cores
    reg.inputs.fixed_image = fixed_vols
    reg.inputs.moving_image = moving_vols
    
    # location of outputs
    reg.inputs.output_warped_image = False # output only transforms, no transformed volumes
    reg.inputs.output_transform_prefix = os.path.join(store_to,store_to_prefix)
    
    # initial transforms: if none are given, initialize by aligning the geometric centers of the images
    if initialFixedAffTrf is None and initialMovingAffTrf is None: 
        reg.inputs.initial_moving_transform_com = 0 # (com=center-of-mass)
    else:
        if initialFixedAffTrf:
            reg.inputs.initial_fixed_transform = initialFixedAffTrf
        if initialMovingAffTrf:
            reg.inputs.initial_moving_transform = initialMovingAffTrf
        
    # shared settings
    #reg.inputs.args='--float 0'
    reg.inputs.dimension = 3
    reg.inputs.interpolation = "Linear"
    reg.inputs.winsorize_lower_quantile=0.005
    reg.inputs.winsorize_upper_quantile=0.995
    reg.inputs.use_histogram_matching = False
    reg.inputs.verbose = True
    if trf_type == "composite":
        reg.inputs.write_composite_transform = True
    else:
        reg.inputs.write_composite_transform = False
    
    # transform-type specific settings
    if trf_type == "affine":
        reg.inputs.transforms = ['Affine']
        reg.inputs.transform_parameters = [(0.1,)]
    elif trf_type == "rigid":
        reg.inputs.transforms = ['Rigid']
        reg.inputs.transform_parameters = [(0.1,)]
    elif trf_type == "deformable":
        reg.inputs.transforms = ['SyN']
        reg.inputs.transform_parameters = [(0.25,)]
    elif trf_type == "composite":
        reg.inputs.transforms = ['Affine','SyN']
        reg.inputs.transform_parameters = [(0.1,), (0.25, 3.0, 0.0)]
        reg.inputs.collapse_output_transforms = False
        # expand speed&metric settings if not given as a list, or list has only one entry
        if isinstance(speed, str):
            speed = [speed, speed]
        elif isinstance(speed, list):
            if len(speed)==1:
                speed = speed*2
        if isinstance(metric, str):
            metric = ['MI', 'CC'] # mandatory setting for Aff+SyN!
        elif isinstance(metric, list):
            if len(metric)==1:
                metric = ['MI', 'CC'] # mandatory setting for Aff+SyN!
    else:
        raise Exception("Parameter type must be from the list: affine, rigid, deformable, composite (composite=affine+deformable)")
    
    # convergence
    config_speed = get_speed_settings(speed)
    reg.inputs.number_of_iterations = config_speed['number_of_iterations']
    reg.inputs.convergence_threshold = config_speed['convergence_threshold']
    reg.inputs.convergence_window_size = config_speed['convergence_window_size']
    reg.inputs.shrink_factors = config_speed['shrink_factors']
    reg.inputs.sigma_units = config_speed['sigma_units']
    reg.inputs.smoothing_sigmas = config_speed['smoothing_sigmas']
    
    # metric
    config_metric = get_metric_settings(metric)
    reg.inputs.metric = config_metric['metric']
    reg.inputs.metric_weight = config_metric['metric_weight']
    reg.inputs.radius_or_number_of_bins = config_metric['radius_or_number_of_bins']
    reg.inputs.sampling_strategy = config_metric['sampling_strategy']
    reg.inputs.sampling_percentage = config_metric['sampling_percentage']
       
    if verbose:
       # print("Using antsRegistration from: {}".format(find_executable("antsRegistration")))
        print("Executing: {}".format(reg.cmdline))
    # perform ants call (retrieve by reg.cmdline)
    if platform.system() in ["Linux", "Darwin"]:
        reg.run()
    elif platform.system() == "Windows":
        import subprocess
        subprocess.check_output(reg.cmdline,shell=True)
    else:
        raise Exception("Unknown platform: {}".format(platform.system()))
        
    if False:
        # reset environment
        if not has_ANTs:
            if has_PATH:
                os.environ["PATH"] = PATH_old
            else:
                del os.environ["PATH"]
                
            if has_LD_LIBRARY:
                os.environ["LD_LIBRARY_PATH"] = LD_LIBRARY_old
            else:
                del os.environ["LD_LIBRARY_PATH"]
                
        if has_NUMBERCORES:
            os.environ["ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS"] = NUMBERCORES_old
        else:
            del os.environ["ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS"]
            
        if trf_type == 'affine':
            #output_trf_path = ["output_0Affine.mat"]
            output_trf_path = reg._list_outputs().get('forward_transforms',["output_0Affine.mat"])
        elif trf_type == 'rigid':
            #output_trf_path = ["output_0Rigid.mat"]
            output_trf_path = reg._list_outputs().get('forward_transforms',["output_0Rigid.mat"])
        elif trf_type == 'deformable':
            #output_trf_path = ["output_0Warp.nii.gz","output_0InverseWarp.nii.gz"]
            output_trf_path = reg._list_outputs().get('forward_transforms',["output_0Warp.nii.gz"])+reg._list_outputs().get('reverse_transforms',["output_0InverseWarp.nii.gz"])
            
        output_paths_trf = [ os.path.join(tmp_dir,p) for p in output_trf_path]
        warped_path = os.path.join(tmp_dir,'moving_warped.nii.gz')
        
        # switch back to old cwd
        os.chdir(cwd_old)
        
        if store_to:
            # copy output files
            moved_output_paths_trf = []
            for tf in output_paths_trf:
                moved = os.path.join(store_to,os.path.basename(tf))
                moved_output_paths_trf.append(moved)
                shutil.copy(tf,moved)
                
            moved_warped_path = os.path.join(store_to,os.path.basename(warped_path))
            shutil.copy(warped_path,moved_warped_path)
            
            # clear tmp directory
            shutil.rmtree(tmp_dir)
            
            if verbose:
                print("Store transform(s) to: {}".format(", ".join(moved_output_paths_trf)))
                print("Store warped volume to: {}".format(", ".join(moved_warped_path)))
                
            return {
                "transform_filepath":moved_output_paths_trf,
                "warpedMovingVolume":moved_warped_path,
                }
        else:
            if verbose:
                print("Store transform(s) to: {}".format(", ".join(output_paths_trf)))
                print("Store warped volume to: {}".format(", ".join(warped_path)))
            
    
    if trf_type in ['affine','rigid','deformable']:
        tgt_trf = 'forward_transforms'
        tgt_trf_inv = 'reverse_transforms'
    else:
        tgt_trf = 'composite_transform'
        tgt_trf_inv = 'inverse_composite_transform'
    trf_out = reg._list_outputs()[tgt_trf]
    trf_out_inv = reg._list_outputs()[tgt_trf_inv]
    return {"transforms_out":trf_out,
            "transforms_out_inv":trf_out_inv}, reg

def makeDiagnosticPlot(subjectHead, IETemplate, subjectToTemplateWarp, output_diagnostic_folder):
    
    '''
    This function makes diagnostic plots for the registration using fsleyes
    render modules. Fsleyes needs to be installed and could be called from 
    the terminal
    '''
   
    # Create a temporary intermediate directory     
    temp = os.path.join(output_diagnostic_folder, 'temp')
    if not os.path.exists(temp):
        os.system('mkdir {temp}'.format(temp=temp))
        
    # Warp the subject in template space
    warpedSubject = os.path.join(output_diagnostic_folder, 'subjectToIEWarped.nii.gz')
    os.system('antsApplyTransforms -d 3 -i {subjectHead} -r {IETemplate} -o {warpedSubject} -t {subjectToTemplateWarp}'.format(subjectHead=subjectHead,
                                                                                                                               IETemplate=IETemplate,
                                                                                                                               warpedSubject=warpedSubject,
                                                                                                                               subjectToTemplateWarp=subjectToTemplateWarp))
    # Open the IEmap with nibabel 
    overlay_img = nib.load(IETemplate)
    overlay_img_data = overlay_img.get_fdata()
    
    # Try to find the coordinates roughly where the inner ear structures are located
    overlay_shape = overlay_img_data.shape
    if overlay_shape[0] % 2 == 0:
        x = int(overlay_shape[0] / 2)
    else:
        x = int((overlay_shape[0] / 2) + 0.5)        
    if overlay_shape[1] % 2 == 0:
        y = int(overlay_shape[1] / 2) 
    else:
        y = int((overlay_shape[1] / 2) + 0.5) 
    if overlay_shape[2] % 2 == 0:
        z = int(overlay_shape[2] / 2)
    else:
        z = int((overlay_shape[2] / 2) + 0.5) 
    
    # Specify output names for the initial images
    brain_image = os.path.join(temp, 'brain.png')
    overlay_image = os.path.join(temp, 'overlay.png') 
    
    # Render the brain image and the overlay using fsleyes
    os.system('xvfb-run -a -s "-screen 0 640x480x24" fsleyes render -hc -vl {x} {y} {z} -of {brain_image} {warpedSubject}; pkill Xvfb'.format(x=x,y=y,z=z,
                                                                                                                                           brain_image=brain_image,
                                                                                                                                           warpedSubject=warpedSubject))
    
    os.system('xvfb-run -a -s "-screen 0 640x480x24" fsleyes render -hc -vl {x} {y} {z} -of {overlay_image} {warpedSubject} {IETemplate}'.format(x=x,y=y,z=z,
                                                                                                                                          overlay_image=overlay_image,
                                                                                                                                          warpedSubject=warpedSubject,
                                                                                                                                          IETemplate=IETemplate))    
    
    # Combine the brain and overlay in a gif
    images = []
    for i in os.listdir(temp):
        images.append(imageio.imread(os.path.join(temp, i)))
        imageio.mimsave('/%s/%s.gif' % (output_diagnostic_folder, 'diagnostic'), images, duration=0.7)
        
    # # Remove the temp directory
    # os.system('rm -r {temp}'.format(temp=temp))