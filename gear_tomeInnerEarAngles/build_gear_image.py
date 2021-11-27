import os

# Specify version that will be appended to the Docker image name
version = '0.3.2'

# Get the current directory 
current_folder = os.getcwd()

# Download supplements
os.system(f'wget https://www.dropbox.com/s/e65quftc74bijsh/innerEarSupplements_v_0_1_3.zip?dl=0 -P {current_folder}')

# Get the zip file 
zip_file = os.path.join(current_folder, 'innerEarSupplements_v_0_1_3.zip?dl=0')

# Unzip it and delete the zip file
os.system(f'unzip {zip_file} -d {current_folder}')
os.system(f'rm {zip_file}')

# Docker build 
docker_file = os.path.join(current_folder, 'Dockerfile')
os.system(f'docker build -t gkaguirrelab/tome-calculate-inner-ear-angles:{version} {current_folder}/.')
