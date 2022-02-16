import flywheel
import datetime

# Enter flywheel key here
flywheelKey = ''

# Initialize gear stuff
now = datetime.datetime.now().strftime("%y/%m/%d_%H:%M")
fw = flywheel.Client(flywheelKey)
proj = fw.projects.find_first('label=tome')
subjects = proj.subjects()
qp = fw.lookup('gears/tome-calculate-inner-ear-angles')
analysis_label = 'tome-calculate-inner-ear-angles %s %s' % (qp.gear.version, now)

config = {'n_threads': '7', 'registration_quality': 'accurate'}
inputs = {}

for sub in subjects:
    subjID = sub.label
    sessions = sub.sessions()
    for ses in sessions:
        if ses.label == 'Session 1':
            acquisitions = ses.acquisitions()
            for acq in acquisitions:
                if 'T2w' in acq.label:
                    if sub.label == 'TOME_3039' and ses.label == 'Session 1':
                        print('skipping TOME_3039 session 1 as T2 is discarded')
                    elif sub.label == 'TOME_3030' and ses.label == 'Session 2':
                        print('skipping TOME_3030 session 2 as T2 is discarded')                
                    elif sub.label == 'TOME_3044' and ses.label == 'Session 2':
                        print('skipping TOME_3044 session 2 as T2 is discarded')  
                    elif sub.label == 'TOME_3029' and ses.label == 'Session 1':
                        print('skipping TOME_3029 session 1 as T2 is discarded')       
                    elif sub.label == 'TOME_3046' and ses.label == 'Session 1':
                        print('skipping TOME_3046 session 1 as T2 is discarded') 
                    else:    
                        image_container = acq
                        for ni in image_container.files:
                            if 'nii.gz' in ni.name:
                                nifti_image = ni
                                config['subject_id'] = subjID
                                inputs['T1_or_T2_image'] = nifti_image
                                _id = qp.run(analysis_label=analysis_label, config=config, 
                                              inputs=inputs, destination=ses, tags=['vm-n1-highmem-8_disk-1500G_swap-60G'])
                                print('submitting inner ear gear for %s' % (subjID))