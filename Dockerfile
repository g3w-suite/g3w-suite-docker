FROM python:2.7.15
MAINTAINER Walter Lorenzetti<lorenzetti@gis3w.it>

RUN mkdir -p /usr/src/g3w-suite
RUN mkdir -p /djangoassets/media
RUN mkdir -p /djangoassets/static
RUN mkdir -p /djangoassets/geodata

RUN apt-get update && apt-get install -y apt-transport-https

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update && apt-get install -y \
		gcc\
        python-dev libgdal-dev\
        postgresql-client\
	--no-install-recommends && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_11.x | bash -
RUN wget https://nightly.yarnpkg.com/debian/pool/main/y/yarn/yarn_1.9.0-20180719.1538_all.deb
RUN apt install -y ./yarn_1.9.0-20180719.1538_all.deb

WORKDIR /usr/src/g3w-suite

# Upgrade pip
RUN pip install --upgrade pip

# install shallow clone of geonode master branch
RUN git clone git://github.com/g3w-suite/g3w-admin.git --branch master /usr/src/g3w-suite

RUN alias node=nodejs
RUN yarn --ignore-engines --ignore-scripts --prod
RUN nodejs -e "try { require('fs').symlinkSync(require('path').resolve('node_modules/@bower_components'), 'g3w-admin/core/static/bower_components', 'junction') } catch (e) { }"

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

# add caching module
RUN git submodule add -f https://github.com/g3w-suite/g3w-admin-caching.git g3w-admin/caching
RUN pip install -r g3w-admin/caching/requirements.txt

# copy demo data
RUN mkdir -p /djangoassets/media/projects
COPY projects /djangoassets/media/projects/
RUN mkdir -p /djangoassets/media/logo_img
COPY fixtures/media/logo_img /djangoassets/media/logo_img/

EXPOSE 8000

ENTRYPOINT ["/usr/src/g3w-suite/entrypoint.sh"]

CMD ["uwsgi", "--ini", "uwsgi.ini"]
