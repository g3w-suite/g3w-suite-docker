## HOW TO RUN ##
#
# # https://docs.docker.com/build/bake/
#

# Global ARGs (available in all FROM instructions)
ARG QGIS_CHANNEL=ubuntu-ltr
ARG INSTALL_MSSQL=false
ARG INSTALL_ORACLE=false

# ===========================================================================
# STAGE: qgis-deb
# ===========================================================================
# clone and build QGIS from source (with Qt6 + Oracle support)
#
# based on:
# - https://github.com/qgis/QGIS/blob/final-4_2_1/INSTALL.md
# - https://github.com/qgis/QGIS/blob/final-4_2_1/CMakeLists.txt
# - https://github.com/qgis/QGIS/blob/final-4_2_1/.docker/docker-qgis-build.sh
# - https://github.com/qgis/QGIS/blob/final-4_2_1/.docker/qgis3-ubuntu-qt6-build-deps.dockerfile
# ===========================================================================
FROM ubuntu:resolute AS qgis-deb

LABEL maintainer="Gis3w" \
      Description="Build QGIS+Oracle runtime package (.deb)" \
      Vendor="Gis3w" \
      Version="dev"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# 📦 [Oracle DB](https://www.oracle.com/database/technologies/instant-client/downloads.html)
ENV LD_LIBRARY_PATH=/instantclient_21_16

RUN chown root:root /tmp && chmod ugo+rwXt /tmp

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/99_norecommends && \
    apt-get update && apt-get install -y \
        bison \
        build-essential \
        ca-certificates \
        ccache \
        clang \
        cmake \
        curl \
        dh-python \
        dpkg-dev \
        flex \
        libaio1t64 \
        libarchive-tools \
        libdraco-dev \
        libexiv2-dev \
        libexpat1-dev \
        libfcgi-dev \
        libgdal-dev \
        libgeos-dev \
        libgsl-dev \
        libpq-dev \
        libproj-dev \
        libprotobuf-dev \
        libqca-qt6-dev \
        libqscintilla2-qt6-dev \
        libqt6opengl6-dev \
        libqt6svg6-dev \
        libspatialindex-dev \
        libspatialite-dev \
        libsqlite3-dev \
        libxml2-dev \
        libxslt-dev \
        libzip-dev \
        libzstd-dev \
        mold \
        ninja-build \
        ocl-icd-opencl-dev \
        opencl-headers \
        protobuf-compiler \
        pyqt6.qsci-dev \
        python3-all-dev \
        python3-pyproj \
        python3-pyqt6 \
        python3-pyqt6.qsci \
        python3-pyqt6.qtsvg \
        python3-pyqt6.qtpositioning \
        python3-pyqt6.qtmultimedia \
        python3-pyqt6.qtserialport \
        python3-pyqt6.qtwebengine \
        python3-pyqt6.sip \
        python3-pyqtbuild \
        python3-sipbuild \
        qt6-3d-dev \
        qt6-5compat-dev \
        qt6-base-dev \
        qt6-base-private-dev \
        qt6-declarative-dev-tools \
        qt6-multimedia-dev \
        qt6-pdf-dev \
        qt6-positioning-dev \
        qt6-serialport-dev \
        qt6-tools-dev \
        qt6-tools-dev-tools \
        qt6-webengine-dev \
        qtkeychain-qt6-dev \
        qmake6 \
        sip-tools \
        spawn-fcgi \
        txt2tags

RUN curl -sSL https://download.oracle.com/otn_software/linux/instantclient/2116000/instantclient-basic-linux.x64-21.16.0.0.0dbru.zip | bsdtar -xf - instantclient_21_16 && \
    curl -sSL https://download.oracle.com/otn_software/linux/instantclient/2116000/instantclient-sdk-linux.x64-21.16.0.0.0dbru.zip | bsdtar -xf - instantclient_21_16 && \
    ln -sf /instantclient_21_16/libclntsh.so.21.1 /instantclient_21_16/libclntsh.so;

RUN --mount=type=cache,target=/root/.cache/ccache \
    mkdir -p /QGIS && \
    cd /QGIS && \
    curl -sSL https://github.com/qgis/QGIS/archive/refs/tags/final-4_2_1.tar.gz | tar -xz --strip-components=1

RUN --mount=type=cache,target=/root/.cache/ccache \
    cmake \
        -G Ninja \
        -S /QGIS \
        -B /QGIS/build \
        -D AGGRESSIVE_SAFE_MODE=OFF \
        -D BINDINGS_GLOBAL_INSTALL=ON \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_C_COMPILER=clang \
        -D CMAKE_CXX_COMPILER=clang++ \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D DISABLE_DEPRECATED=ON \
        -D USE_CCACHE=ON \
        -D ENABLE_TESTS=OFF \
        -D ENABLE_UNITY_BUILDS=OFF \
        -D ORACLE_INCLUDEDIR=/instantclient_21_16/sdk/include \
        -D ORACLE_LIBDIR=/instantclient_21_16/ \
        -D WERROR=FALSE \
        -D WITH_3D=OFF \
        -D WITH_ANALYSIS=OFF \
        -D WITH_APIDOC=OFF \
        -D WITH_BINDINGS=ON \
        -D WITH_CUSTOM_WIDGETS=OFF \
        -D WITH_DESKTOP=OFF \
        -D WITH_GRASS=OFF \
        -D WITH_GEOGRAPHICLIB=OFF \
        -D WITH_GUI=ON \
        -D WITH_HANA=OFF \
        -D WITH_INTERNAL_SPATIALINDEX=ON \
        -D WITH_CLAZY=OFF \
        -D WITH_ORACLE=ON \
        -D WITH_PDAL=OFF \
        -D WITH_PDF4QT=OFF \
        -D WITH_QGIS_PROCESS=OFF \
        -D WITH_QSPATIALITE=ON \
        -D WITH_QUICK=OFF \
        -D WITH_QTSERIALPORT=OFF \
        -D WITH_SERVER=ON \
        -D WITH_SERVER_LANDINGPAGE_WEBAPP=OFF \
        -D WITH_SFCGAL=OFF \
        -D SERVER_SKIP_ECW=ON \
        -D WITH_STAGED_PLUGINS=ON

RUN --mount=type=cache,target=/root/.cache/ccache \
    DESTDIR=/tmp/qgis-oracle ninja -C /QGIS/build install

RUN mkdir -p /tmp/qgis-oracle/instantclient_21_16 && \
    cp -a /instantclient_21_16/. /tmp/qgis-oracle/instantclient_21_16/ && \
    ln -sf /instantclient_21_16/libclntsh.so.21.1 /tmp/qgis-oracle/instantclient_21_16/libclntsh.so && \
    mkdir -p /tmp/qgis-oracle/etc/ld.so.conf.d && \
    echo "/instantclient_21_16" > /tmp/qgis-oracle/etc/ld.so.conf.d/oracle-instantclient.conf && \
    mkdir -p /tmp/qgis-oracle/usr/lib/x86_64-linux-gnu && \
    ln -sf /usr/lib/x86_64-linux-gnu/libaio.so.1t64 /tmp/qgis-oracle/usr/lib/x86_64-linux-gnu/libaio.so.1 && \
    mkdir -p /tmp/qgis-oracle/DEBIAN && \
    mkdir -p /tmp/qgis-oracle/debian && touch /tmp/qgis-oracle/debian/control && \
    AUTO_DEPS=$(dpkg-shlibdeps -O /tmp/qgis-oracle/usr/bin/* /tmp/qgis-oracle/usr/lib/qgis/*.so* /tmp/qgis-oracle/instantclient_21_16/*.so* 2>/dev/null | sed -n 's/^shlibs:Depends=//p') && \
    dh_python3 --package=qgis-oracle /tmp/qgis-oracle && \
    PYTHON_DEPS=$(sed -n 's/^python3:Depends=//p' /tmp/qgis-oracle/debian/qgis-oracle.substvars 2>/dev/null) && \
    rm -rf /tmp/qgis-oracle/debian && \
    printf '%s\n' \
        'Package: qgis-oracle' \
        'Version: 4.2.1-1' \
        'Section: misc' \
        'Priority: optional' \
        'Architecture: amd64' \
        'Maintainer: Gis3w' \
        "Depends: $AUTO_DEPS, $PYTHON_DEPS" \
        'Description: Prebuilt QGIS Server runtime with Oracle support for G3W Suite' \
        > /tmp/qgis-oracle/DEBIAN/control && \
    printf '%s\n' '#!/bin/sh' 'set -e' 'ldconfig' > /tmp/qgis-oracle/DEBIAN/postinst && \
    chmod 0755 /tmp/qgis-oracle/DEBIAN/postinst && \
    dpkg-deb --build /tmp/qgis-oracle /tmp/qgis-oracle.deb && \
    rm -rf /QGIS /tmp/qgis-oracle


# Final configuration & runtime setup
# RUN pip3 install --break-system-packages jinja2 pygments;

# ENV PYTHONPATH=/usr/share/qgis/python/:/usr/share/qgis/python/plugins:/usr/lib/python3/dist-packages/qgis:/usr/share/qgis/python/qgis

# Fix www-data permissions for runtime requirements
# RUN mkdir -p /var/www/.local /var/www/.config && chown -R www-data:www-data /var/www

# USER www-data

# CMD ["/usr/bin/xvfb-run", \
#      "-s", "-ac -screen 0 1280x1024x16 +extension GLX +render -noreset", \
#      "/usr/bin/spawn-fcgi", \
#        "-d", "/usr/lib/qgis/", \
#        "-n", \
#        "-p", "9333", \
#        "--", \
#        "/usr/bin/qgis_mapserv.fcgi"]

FROM ubuntu:resolute AS qgis-deb-true
COPY --from=qgis-deb /tmp/qgis-oracle.deb /tmp/qgis-oracle.deb

FROM ubuntu:resolute AS qgis-deb-false
RUN touch /tmp/qgis-oracle.deb 

# ===========================================================================
# STAGE: deps
# ===========================================================================

FROM qgis-deb-${INSTALL_ORACLE} AS deps

ARG QGIS_CHANNEL
ARG INSTALL_MSSQL
ARG INSTALL_ORACLE

LABEL maintainer="Gis3w" \
      Description="Image used to prepare build requirements for g3w-suite docker images" \
      Vendor="Gis3w" \
      Version="dev"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# hotfix for Python 11: https://stackoverflow.com/a/76469774
ENV UV_BREAK_SYSTEM_PACKAGES=1
ENV UV_SYSTEM_PYTHON=1
ENV UV_OVERRIDE=/requirements_uv.txt
ENV UV_NO_BUILD_ISOLATION=1
ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV PIP_ROOT_USER_ACTION=ignore
ENV DEB_PYTHON_INSTALL_LAYOUT=deb_system

ENV GIT_CONFIG_PARAMETERS="'safe.directory=/code' 'safe.directory=/code/plugins/*'"

# 🗺️ [QGIS Server](https://docs.qgis.org/3.40/en/docs/server_manual/config.html#environment-variables)
ENV QGIS_OPTIONS_PATH=/shared-volume/
ENV QGIS_SERVER_LOG_FILE=/shared-volume/QGIS/error.log
ENV QGIS_SERVER_LOG_LEVEL=2
ENV QGIS_SERVER_PARALLEL_RENDERING=1

# 📦 [Oracle DB](https://www.oracle.com/database/technologies/instant-client/downloads.html)
# ENV LD_LIBRARY_PATH=/instantclient_21_16

ENV DISPLAY=:99

# expose PyQGIS to Python interpreter
ENV PYTHONPATH=/usr/share/qgis/python

RUN chown root:root /tmp && chmod ugo+rwXt /tmp

# update system packages
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/99_norecommends && \
    apt-get update && apt-get install -y \
        curl \
        dirmngr \
        gdal-bin \
        figlet \
        git \
        libaio1t64 \
        libgdal-dev \
        libgdal38 \
        libmagic1 \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libsqlite3-mod-spatialite \
        libxml2-dev \
        libxslt-dev \
        nodejs \
        npm \
        postgresql-client \
        python3-dev \
        python3-gdal \
        python3-pip \
        python3-pkg-resources \
        wait-for-it \
        xvfb

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    if [ "${INSTALL_ORACLE}" = "true" ]; then \
        apt-get update && apt-get install -y /tmp/qgis-oracle.deb && rm -f /tmp/qgis-oracle.deb; \
    fi

# PyQGIS – channel is controlled by QGIS_CHANNEL build arg:
#   ubuntu-ltr  → https://qgis.org/ubuntu-ltr  (LTR, default)
#   ubuntu      → https://qgis.org/ubuntu       (latest)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    if [ "${INSTALL_ORACLE}" = "false" ]; then \
        curl -sSL https://download.qgis.org/downloads/qgis-archive-keyring.gpg > /etc/apt/keyrings/qgis-archive-keyring.gpg && \
        echo "deb [signed-by=/etc/apt/keyrings/qgis-archive-keyring.gpg] https://qgis.org/${QGIS_CHANNEL} resolute main" > /etc/apt/sources.list.d/qgis.list && \
        apt-get update && apt-get install -y python3-qgis qgis-server; \
    fi

# MS SQL ODBC driver (optional – only when INSTALL_MSSQL=true)
# ⚠  By enabling this you accept the Microsoft EULA (ACCEPT_EULA=Y)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    if [ "${INSTALL_MSSQL}" = "true" ]; then \
      apt-get install -y tdsodbc libqt5sql5-tds && \
      curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg && \
      echo "deb [signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/24.04/prod noble main" >> /etc/apt/sources.list.d/mssql.list && \
      apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18; \
    fi

# yarn (package manager)
RUN corepack enable

# uv (package manager)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# DEBUG: keep container running in background
CMD ["tail", "-f", "/dev/null"]

RUN mkdir /code && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /code

# ===========================================================================
# STAGE: suite
# ===========================================================================

FROM deps AS suite

# G3W-ADMIN branch to checkout.
ARG G3W_SUITE_BRANCH=dev

# update system packages
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# import g3w-admin
RUN git clone https://github.com/g3w-suite/g3w-admin.git --single-branch --depth 1 --branch ${G3W_SUITE_BRANCH} .
RUN git submodule add -f https://github.com/g3w-suite/g3w-admin-frontend.git g3w-admin/frontend

# compile static assets (g3w-admin)
RUN yarn --ignore-engines --ignore-scripts --prod && \
    mkdir -p /code/g3w-admin/core/static && \
    rm -rf /code/g3w-admin/core/static/bower_components && \
    ln -s "../../../node_modules/@bower_components" /code/g3w-admin/core/static/bower_components

# update python packages
COPY requirements_rl.txt /requirements_rl.txt
COPY requirements_uv.txt /requirements_uv.txt
RUN --mount=type=cache,target=/root/.cache/uv,sharing=locked uv pip install setuptools poetry        # for legacy packages ("tilestache" and "django-huey-monitor")
RUN --mount=type=cache,target=/root/.cache/uv,sharing=locked uv pip install -r /requirements_rl.txt

# import scripts
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

CMD ["sh", "-c", "figlet G3W-SUITE && tail -f /dev/null"]

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]