# Docker container with QGIS Server and Oracle support
#
# The Server FCGI socket will be started on port 9333
#
# See qgis-server-oracle-build.sh for building instructions
# See qgis-server-oracle-run.sh for running instructions
#
# Arguments:
#  DOCKER_DEPS_TAG: tag for the dependencies base image, ex: release-3_10
#  QGIS_TAG: git tag from the QGIS repo, ex: final-3_10_12
#
# QGIS server binary is /usr/bin/qgis_mapserv.fcgi


ARG DOCKER_DEPS_TAG=release-3_10

FROM  qgis/qgis3-build-deps:${DOCKER_DEPS_TAG} AS BUILDER
MAINTAINER Alessandro Pasotti <elpaso@itopen.it>

ARG QGIS_TAG=final-3_10_12

LABEL Description="Docker container with QGIS Server and Oracle support" Vendor="Gis3W" Version="1.0"

ENV LANG=C.UTF-8

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

# Unprvileged user
USER www-data

# Startup script
COPY qgis-server-oracle-command.sh /qgis-server-oracle-command.sh

CMD ["/qgis-server-oracle-command.sh"]