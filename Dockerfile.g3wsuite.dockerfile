FROM g3wsuite/g3w-suite-deps:latest

LABEL maintainer="Gis3W" Description="This image is used to install python requirements and code for g3w-suite deployment" Vendor="Gis3W" Version="1.0"
# Based on main CI Docker from  g3w-suite, checkout code + caching,
# custom settings file
RUN apt install git -y && \
    git clone https://github.com/g3w-suite/g3w-admin.git --single-branch --branch dev /code && \
    cd /code && \
    git checkout dev

# Override settings
COPY requirements_rl.txt .
RUN pip3 install -r requirements_rl.txt

# Caching
RUN pip3 install -r /code/g3w-admin/caching/requirements.txt

# Filemanager
RUN pip3 install -r /code/g3w-admin/filemanager/requirements.txt

CMD echo "Base image for g3w-suite-dev" && tail -f /dev/null