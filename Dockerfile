FROM python:2.7.15
MAINTAINER Walter Lorenzetti<lorenzetti@gis3w.it>

RUN mkdir -p /usr/src/g3w-suite

WORKDIR /usr/src/g3w-suite

RUN apt-get update && apt-get install -y \
		gcc \
        python-dev libgdal-dev \
        postgresql-client\
	--no-install-recommends && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --upgrade pip

# install shallow clone of geonode master branch
RUN git clone git://github.com/g3w-suite/g3w-admin.git --branch master /usr/src/g3w-suite

#RUN cp g3w-admin/base/settings/local_settings_example.py g3w-admin/base/settings/local_settings.py
RUN cd /usr/src/g3w-suite/; pip install -r requirements.txt
RUN pip install uwsgi
RUN pip install invoke
RUN pip install docker
RUN pip install GDAL==2.1.0 --global-option=build_ext --global-option="-I/usr/include/gdal"
COPY . /usr/src/g3w-suite
COPY wait-for-databases.sh /usr/bin/wait-for-databases
RUN chmod +x /usr/bin/wait-for-databases
RUN mv local_settings.py g3w-admin/base/settings/
RUN chmod +x /usr/src/g3w-suite/tasks.py && chmod +x /usr/src/g3w-suite/entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/usr/src/g3w-suite/entrypoint.sh"]

#CMD ["uwsgi", "--ini", "/usr/src/g3w-suite/uwsgi.ini"]
CMD ["python", "g3w-admin/manage.py", "runserver", "0.0.0.0:8000"]
#CMD ["python", "-m", "SimpleHTTPServer", "8000"]
