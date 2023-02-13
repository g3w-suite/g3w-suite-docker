##
# DOCKER IMAGE: https://hub.docker.com/r/g3wsuite/g3w-suite-dev
#
# This image extends G3W-SUITE LTR (UBUNTU + QGIS LTR) for development purposes 
##
ARG DISTRO=ubuntu
ARG IMAGE_VERSION=jammy
ARG QGIS_LTR='-ltr'
ARG INSTALL_MSSQL=false
FROM ${DISTRO}:${IMAGE_VERSION} AS g3w-suite-base

# Reset ARG for version
ARG IMAGE_VERSION
ARG QGIS_LTR
ARG DISTRO

LABEL maintainer="Gis3w" \
      Description="Image used to prepare build requirements for g3w-suite docker images" \
      Vendor="Gis3w" \
      Version="dev"

ENV DEBIAN_FRONTEND=noninteractive

# Is this needed, chmod always bloats docker images
RUN chown root:root /tmp && chmod ugo+rwXt /tmp

RUN apt-get update && apt-get -y  install \
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
    git \
    lsb-release \
    xvfb; \
    # PyQGIS 3.22
    wget -qO - https://qgis.org/downloads/qgis-2022.gpg.key | \
    gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/qgis-archive.gpg --import && \
    chmod a+r /etc/apt/trusted.gpg.d/qgis-archive.gpg && \
    echo "deb [arch=amd64] https://qgis.org/ubuntu${QGIS_LTR} ${IMAGE_VERSION} main" >> /etc/apt/sources.list && \
    apt update && apt-get -y  install python3-qgis qgis-server

# MSSQL
RUN if [ "${INSTALL_MSSQL}" = "true" ]; then \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add && \
    echo "deb https://packages.microsoft.com/${DISTRO}/$(lsb_release -rs)/prod ${IMAGE_VERSION} main" >> /etc/apt/sources.list && \
    apt update && ACCEPT_EULA=Y apt-get -y  install msodbcsql18 mssql-tools;\
    fi;

# Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | \
    tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt install -y yarn; \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /code

WORKDIR /code

##############################################################################
# Production Stage                                                           #
##############################################################################
FROM g3w-suite-base AS g3w-suite-prod

LABEL maintainer="Gis3W" \
      Description="Image used to install python requirements and code for g3w-suite deployment" \
      Vendor="Gis3W" \
      Version="1.0"

##
# G3W-ADMIN git branch to checkout.
# Defaults to `dev` but can be set to another branch name to build
# a particular suite version
##
ARG G3W_SUITE_BRANCH

# Override settings
ADD requirements_rl.txt /requirements_rl.txt

ADD scripts /scripts

RUN chmod +x /scripts/*.sh

RUN /scripts/setup.sh \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD echo "Base image for g3w-suite-dev" && tail -f /dev/null

ENTRYPOINT /scripts/docker-entrypoint.sh