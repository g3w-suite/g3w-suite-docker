FROM ubuntu:focal
# This image is available as g3wsuite/g3w-suite-deps:ltr-mssql
# This image contain MSSql odbc driver.
LABEL maintainer="Gis3w" Description="This image is used to prepare build requirements for g3w-suite docker images" Vendor="Gis3w" Version="1.2"

ENV DEBIAN_FRONTEND=noninteractive
RUN chown root:root /tmp && chmod ugo+rwXt /tmp
RUN apt-get update && apt install -y \
    libxml2-dev \
    libxslt-dev \
    postgresql-server-dev-all \
    libgdal-dev \
    python3-dev \
    libgdal26 \
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

# PyQGIS 3.10
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-key 46B5721DBBD2996A && \
    echo "deb [arch=amd64] https://qgis.org/ubuntu-ltr bionic main" >> /etc/apt/sources.list && \
    apt update && apt install -y python3-qgis qgis-server

# MSSQL
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add
RUN echo "deb https://packages.microsoft.com/ubuntu/20.04/prod bionic main" >> /etc/apt/sources.list
# ACCEPT_EULA=Y END-USER LICENSE AGREEMENT FOR MICROSOFT SOFTWAR
RUN apt update && ACCEPT_EULA=Y apt install -y msodbcsql17 mssql-tools

# Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | \
    tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt install -y yarn

RUN mkdir /code
WORKDIR /code
