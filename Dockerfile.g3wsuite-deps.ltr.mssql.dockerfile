FROM ubuntu:jammy
# This image is available as g3wsuite/g3w-suite-deps:ltr-mssql
# This image contain MSSql odbc driver.
LABEL maintainer="Gis3w" Description="This image is used to prepare build requirements for g3w-suite docker images" Vendor="Gis3w" Version="dev"

ENV DEBIAN_FRONTEND=noninteractive
RUN chown root:root /tmp && chmod ugo+rwXt /tmp
RUN apt-get update && apt install -y \
    libxml2-dev \
    libxslt-dev \
    postgresql-server-dev-all \
    libgdal-dev \
    python3-dev \
    libgdal30 \
    python3-gdal \
    python3-pip \
    curl \
    gnupg2 \
    wget \
    vim \
    wait-for-it \
    gdal-bin \
    libsqlite3-mod-spatialite \
    dirmngr \
    tdsodbc \
    libqt5sql5-tds \
    xvfb

# PyQGIS 3.22
RUN wget -qO - https://qgis.org/downloads/qgis-2022.gpg.key | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/qgis-archive.gpg --import &&  \
    chmod a+r /etc/apt/trusted.gpg.d/qgis-archive.gpg && \
    echo "deb [arch=amd64] https://qgis.org/ubuntu-ltr jammy main" >> /etc/apt/sources.list && \
    apt update && apt install -y python3-qgis qgis-server

# MSSQL
# ACCEPT_EULA=Y END-USER LICENSE AGREEMENT FOR MICROSOFT SOFTWARE
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add &&  \
    echo "deb https://packages.microsoft.com/ubuntu/22.04/prod jammy main" >> /etc/apt/sources.list &&  \
    apt update && ACCEPT_EULA=Y apt install -y msodbcsql18 mssql-tools

# Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | \
    tee /etc/apt/sources.list.d/yarn.list &&  \
    apt-get update && apt install -y yarn

RUN mkdir /code
WORKDIR /code
