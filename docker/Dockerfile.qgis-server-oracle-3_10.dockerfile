# Docker container with QGIS Server 3.10 and Oracle support
#
# The Server FCGI socket will be started on port 9333
#
# See qgis-server-oracle-build-3_10.sh for building instructions
#
# Arguments:
#  QGIS_TAG: git tag from the QGIS repo, ex: final-3_10_12
#
# QGIS server binary is /usr/bin/qgis_mapserv.fcgi

FROM      ubuntu:18.04
MAINTAINER Alessandro Pasotti <elpaso@itopen.it

ARG QGIS_TAG=final-3_10_12

LABEL Description="Docker container with QGIS Server 3.10" Vendor="Gis3W" Version="1.0"

RUN  apt-get update \
  && apt-get install -y software-properties-common \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive \
  apt-get install --no-install-recommends -y \
    apt-transport-https \
    bison \
    ca-certificates \
    clang \
    cmake \
    curl \
    dh-python \
    flex \
    gdal-bin \
    git \
    libaio1 \
    libexiv2-dev \
    libexpat1-dev \
    libfcgi-dev \
    libgdal-dev \
    libgeos-dev \
    libgsl-dev \
    libpq-dev \
    libproj-dev \
    libqca-qt5-2-dev \
    libqca-qt5-2-plugins \
    libqt53drender5 \
    libqt5concurrent5 \
    libqt5opengl5-dev \
    libqt5positioning5 \
    libqt5qml5 \
    libqt5quick5 \
    libqt5quickcontrols2-5 \
    libqt5scintilla2-dev \
    libqt5sql5-odbc \
    libqt5sql5-sqlite \
    libqt5svg5-dev \
    libqt5webkit5-dev \
    libqt5xml5 \
    libqt5serialport5-dev \
    libqwt-qt5-dev \
    libspatialindex-dev \
    libspatialite-dev \
    libsqlite3-dev \
    libsqlite3-mod-spatialite \
    libzip-dev \
    locales \
    ninja-build \
    pkg-config \
    poppler-utils \
    postgresql-client \
    pyqt5-dev \
    pyqt5-dev-tools \
    pyqt5.qsci-dev \
    python3-all-dev \
    python3-dev \
    python3-future \
    python3-gdal \
    python3-mock \
    python3-nose2 \
    python3-owslib \
    python3-pip \
    python3-psycopg2 \
    python3-pyproj \
    python3-pyqt5 \
    python3-pyqt5.qsci \
    python3-pyqt5.qtsql \
    python3-pyqt5.qtsvg \
    python3-pyqt5.qtwebkit \
    python3-sip \
    python3-sip-dev \
    python3-termcolor \
    python3-yaml \
    qt3d5-dev \
    qt3d-assimpsceneimport-plugin \
    qt3d-defaultgeometryloader-plugin \
    qt3d-gltfsceneio-plugin \
    qt3d-scene2d-plugin \
    qt5keychain-dev \
    qtbase5-dev \
    qtdeclarative5-dev-tools \
    qtdeclarative5-qtquick2-plugin \
    qtpositioning5-dev \
    qttools5-dev \
    qttools5-dev-tools \
    qtbase5-private-dev \
    spawn-fcgi \
    txt2tags \
    unzip \
    xauth \
    xfonts-100dpi \
    xfonts-75dpi \
    xfonts-base \
    xfonts-scalable \
    xvfb \
  && pip3 install \
    pyyaml \
    mock \
    future \
    termcolor \
    oauthlib \
    pyopenssl \
    capturer \
    requests \
    six \
  && apt-get clean

# Oracle : client side
RUN curl https://download.oracle.com/otn_software/linux/instantclient/193000/instantclient-basic-linux.x64-19.3.0.0.0dbru.zip > instantclient-basic-linux.x64-19.3.0.0.0dbru.zip \
  && curl https://download.oracle.com/otn_software/linux/instantclient/193000/instantclient-sdk-linux.x64-19.3.0.0.0dbru.zip > instantclient-sdk-linux.x64-19.3.0.0.0dbru.zip \
  && curl https://download.oracle.com/otn_software/linux/instantclient/193000/instantclient-sqlplus-linux.x64-19.3.0.0.0dbru.zip > instantclient-sqlplus-linux.x64-19.3.0.0.0dbru.zip

RUN unzip instantclient-basic-linux.x64-19.3.0.0.0dbru.zip \
    && unzip instantclient-sdk-linux.x64-19.3.0.0.0dbru.zip \
    && unzip instantclient-sqlplus-linux.x64-19.3.0.0.0dbru.zip \
    && rm -f *.zip

ENV PATH="/instantclient_19_3:${PATH}"
ENV LD_LIBRARY_PATH="/instantclient_19_3:${LD_LIBRARY_PATH}"

# MSSQL: client side
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | tee /etc/apt/sources.list.d/msprod.list \
    && apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql17 mssql-tools

# Avoid sqlcmd termination due to locale -- see https://github.com/Microsoft/mssql-docker/issues/163
RUN echo "nb_NO.UTF-8 UTF-8" > /etc/locale.gen \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen

RUN echo "alias python=python3" >> ~/.bash_aliases

ENV QT_SELECT=5
ENV LANG=C.UTF-8
ENV PATH="/usr/local/bin:${PATH}"

# Clone tagged release
RUN cd / && git clone --depth 1 --branch ${QGIS_TAG} https://github.com/qgis/QGIS.git

# Build server
RUN cd /QGIS && mkdir build && cd build && \
  cmake \
  -GNinja \
  -DUSE_CCACHE=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DOCI_INCLUDE_DIR=/instantclient_19_3/sdk/include \
  -DOCI_LIBRARY=/instantclient_19_3/libclntsh.so \
  -DWITH_DESKTOP=OFF \
  -DWITH_ANALYSIS=ON \
  -DWITH_SERVER=ON \
  -DWITH_3D=OFF \
  -DWITH_BINDINGS=ON \
  -DWITH_CUSTOM_WIDGETS=OFF \
  -DBINDINGS_GLOBAL_INSTALL=ON \
  -DWITH_STAGED_PLUGINS=ON \
  -DWITH_GRASS=OFF \
  -DWITH_ORACLE=ON \
  -DSUPPRESS_QT_WARNINGS=ON \
  -DDISABLE_DEPRECATED=ON \
  -DENABLE_TESTS=OFF \
  -DWITH_QSPATIALITE=ON \
  -DWITH_APIDOC=OFF \
  -DWITH_ASTYLE=OFF \
  -DCMAKE_PREFIX_PATH=.. \
  .. \
  && ninja install \
  && cd \
  && rm -rf /QGIS

# Additional run-time dependencies
RUN pip3 install jinja2 pygments

# Python paths
ENV PYTHONPATH=/usr/share/qgis/python/:/usr/share/qgis/python/plugins:/usr/lib/python3/dist-packages/qgis:/usr/share/qgis/python/qgis

# Startup script
COPY qgis-server-oracle-command.sh /qgis-server-oracle-command.sh

# Clean
RUN apt-get remove -y *-dev git clang cmake flex ninja-build \
    && rm -rf /var/lib/apt/lists/*

# Unprivileged user
USER www-data

CMD ["/qgis-server-oracle-command.sh"]