# This makes a container for the gear. Replace the first path next to the second COPY function 
# below with a path to your local compiled matlab function

FROM neurodebian:xenial
MAINTAINER Ozzy(ozenctaskin@hotmail.com)

#Initialize flywheel v0 and move the required files into the container 
ENV FLYWHEEL /flywheel/v0/
RUN mkdir -p ${FLYWHEEL}
COPY manifest.json run ${FLYWHEEL}
COPY ants /ants
COPY data /data
COPY iemap_seg.py /iemap_seg.py
RUN chmod +x /flywheel/v0/run
COPY fslinstaller.py /fslinstaller.py
COPY calculateSSCwrtBZero /tmp/calculateSSCwrtBZero

# Install required packages    
RUN apt-get update \
    && apt-get install -y \
    git \
    wget \
    zip \
    python \
    unzip \
    ants \ 
    libgl1-mesa-glx \
    fsleyes \ 
    xvfb \
    python-vtk

# Install python2 for fslinstallation and install the newest verison of fsl
RUN apt-get install python -y
RUN python2 /fslinstaller.py -d /fsl 

# Install Anaconda
RUN wget https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-x86_64.sh
RUN bash Anaconda3-2020.02-Linux-x86_64.sh -b -p /anaconda3
ENV PATH=$PATH:/anaconda3/bin
RUN conda update --all -y
RUN pip install nipype imageio SimpleITK nibabel matplotlib vtk pandas flywheel-sdk

# Download and install MCR on call
RUN wget https://ssd.mathworks.com/supportfiles/downloads/R2020a/Release/5/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2020a_Update_5_glnxa64.zip
RUN mkdir matlabins
RUN unzip MATLAB_Runtime_R2020a_Update_5_glnxa64.zip -d /matlabins/
RUN /matlabins/install -mode silent -agreeToLicense yes

# Set the entrypoint  
ENTRYPOINT /flywheel/v0/run
