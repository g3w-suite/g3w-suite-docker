## HOW TO RUN ##
#
# Multi-stage Dockerfile for g3w-suite images:
#
#  make docker-image t=deps-ltr v=dev                                                 → g3wsuite/g3w-suite-deps-ltr:dev    (QGIS LTR)
#  make docker-image t=deps v=dev                                                     → g3wsuite/g3w-suite-deps:dev        (QGIS latest)
#  make docker-image t=deps-mssql v=ltr-mssql                                         → g3wsuite/g3w-suite-deps:ltr-mssql  (QGIS latest + Microsoft SQL Server)
#  make docker-image t=suite v=dev                                                    → g3wsuite/g3w-suite:dev             (G3W-SUITE dev) 
#  make docker-image t=oracle v=dev QGIS_DEPS_TAG=release-3_22 QGIS_TAG=final-3_22_7  → qgis/qgis3-build-deps:release-3_22 (QGIS + Oracle support)
#

# ===========================================================================
# STAGE: deps
# ===========================================================================

# Global ARGs (available in all FROM instructions)
ARG QGIS_CHANNEL=ubuntu-ltr
ARG INSTALL_MSSQL=false
ARG DOCKER_DEPS_TAG=release-3_22

FROM ubuntu:noble AS deps

ARG QGIS_CHANNEL
ARG INSTALL_MSSQL

LABEL maintainer="Gis3w" \
      Description="Image used to prepare build requirements for g3w-suite docker images" \
      Vendor="Gis3w" \
      Version="dev"

ENV DEBIAN_FRONTEND=noninteractive

RUN chown root:root /tmp && chmod ugo+rwXt /tmp

# Base system packages
RUN apt-get update && apt-get install -y \
    libxml2-dev \
    libxslt-dev \
    libgdal-dev \
    python3-dev \
    libgdal34t64 \
    python3-gdal \
    python3-pip \
    curl \
    wait-for-it \
    gdal-bin \
    libsqlite3-mod-spatialite \
    dirmngr \
    xvfb \
    postgresql-client

# PyQGIS – channel is controlled by QGIS_CHANNEL build arg:
#   ubuntu-ltr  → https://qgis.org/ubuntu-ltr  (LTR, default)
#   ubuntu      → https://qgis.org/ubuntu       (latest)
RUN curl -L -sS https://download.qgis.org/downloads/qgis-archive-keyring.gpg \
        > /etc/apt/keyrings/qgis-archive-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/qgis-archive-keyring.gpg] https://qgis.org/${QGIS_CHANNEL} noble main" | \
    tee /etc/apt/sources.list.d/qgis.list && \
    apt-get update && apt-get install -y python3-qgis qgis-server

# MS SQL ODBC driver (optional – only when INSTALL_MSSQL=true)
# ⚠  By enabling this you accept the Microsoft EULA (ACCEPT_EULA=Y)
RUN if [ "${INSTALL_MSSQL}" = "true" ]; then \
      apt-get install -y tdsodbc libqt5sql5-tds && \
      curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add && \
      echo "deb https://packages.microsoft.com/ubuntu/24.04/prod noble main" \
          >> /etc/apt/sources.list && \
      apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18; \
    fi

# Yarn
RUN curl -L -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | \
    tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y yarn && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

##
# uv package manager
##
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

RUN mkdir /code

WORKDIR /code

# ===========================================================================
# STAGE: suite
# ===========================================================================

FROM deps AS suite

# G3W-ADMIN branch to checkout.
ARG G3W_SUITE_BRANCH=dev

COPY requirements_rl.txt /requirements_rl.txt
COPY scripts/ /scripts/

# update system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    figlet \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN chmod +x /scripts/*.sh

RUN git clone https://github.com/g3w-suite/g3w-admin.git --single-branch --depth 1 --branch ${G3W_SUITE_BRANCH} .

RUN git submodule add -f https://github.com/g3w-suite/g3w-admin-frontend.git g3w-admin/frontend 

RUN --mount=type=cache,target=/root/.cache/pip pip install --break-system-packages --root-user-action=ignore -r /requirements_rl.txt

CMD ["sh", "-c", "figlet G3W-SUITE && tail -f /dev/null"]

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]


# ===========================================================================
# STAGE: qgis-oracle
# ===========================================================================
# NOTE: this stage is completely independent from `deps` / `suite`.
#       It compiles QGIS from source with Oracle (OCI) support.
#       QGIS server binary is /usr/bin/qgis_mapserv.fcgi
# ===========================================================================

FROM qgis/qgis3-build-deps:${DOCKER_DEPS_TAG} AS qgis-oracle

LABEL maintainer="Alessandro Pasotti <elpaso@itopen.it>" \
      Description="Docker container with QGIS Server and Oracle support" \
      Vendor="Gis3W" \
      Version="3.4.x"

ARG QGIS_TAG=final-3_22_7

ENV LANG=C.UTF-8

# Clone tagged release
RUN cd / && git clone --depth 1 --branch ${QGIS_TAG} https://github.com/qgis/QGIS.git

# Build server with Oracle support
RUN cd /QGIS && mkdir build && cd build && \
    cmake \
      -GNinja \
      -DUSE_CCACHE=OFF \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DOCI_INCLUDE_DIR=/instantclient_19_9/sdk/include \
      -DOCI_LIBRARY=/instantclient_19_9/libclntsh.so \
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

# Unprivileged user
USER www-data

CMD ["/usr/bin/xvfb-run", \
     "-s", "-ac -screen 0 1280x1024x16 +extension GLX +render -noreset", \
     "/usr/bin/spawn-fcgi", \
       "-u", "www-data", \
       "-g", "www-data", \
       "-d", "/usr/lib/qgis/", \
       "-n", \
       "-p", "9333", \
       "--", \
       "/usr/bin/qgis_mapserv.fcgi"]
