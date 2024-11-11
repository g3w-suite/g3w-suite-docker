##
# DOCKER IMAGE: https://hub.docker.com/r/g3wsuite/g3w-suite-deps:ltr-mssql
#
# This image extends UBUNTU and ships the MSSQL ODBC driver,
# by using this you agree to the additional END USER LICENSE
# AGREEMENT FOR THE MICROSOFT SOFTWARE (see: ACCEPT_EULA=Y)
##

FROM ubuntu:jammy

LABEL maintainer="Gis3w" \
      Description="Image used to prepare build requirements for g3w-suite docker images" \
      Vendor="Gis3w" \
      Version="dev"

ENV DEBIAN_FRONTEND=noninteractive

RUN chown root:root /tmp && chmod ugo+rwXt /tmp

RUN apt-get update && apt install -y \
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
    tdsodbc \
    libqt5sql5-tds \
    xvfb

# PyQGIS LTR
RUN curl -sS https://download.qgis.org/downloads/qgis-archive-keyring.gpg > /etc/apt/keyrings/qgis-archive-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/qgis-archive-keyring.gpg] https://qgis.org/ubuntu-ltr noble main" | \
    tee /etc/apt/sources.list.d/qgis.list && \
    apt-get update && apt-get install -y python3-qgis qgis-server

# MSSQL
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add && \
    echo "deb https://packages.microsoft.com/ubuntu/24.04/prod jammy main" >> /etc/apt/sources.list && \
    apt update && ACCEPT_EULA=Y apt install -y msodbcsql18 mssql-tools

# Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | \
    tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt install -y yarn

RUN mkdir /code
WORKDIR /code
