##
# DOCKER IMAGE: https://hub.docker.com/r/g3wsuite/g3w-suite-dev
#
# This image extends G3W-SUITE LTR (UBUNTU + QGIS LTR) for development purposes 
##

FROM g3wsuite/g3w-suite-deps-ltr:v3.6.x

LABEL maintainer="Gis3W" \
      Description="Image used to install python requirements and code for g3w-suite deployment" \
      Vendor="Gis3W" \
      Version="1.0"

##
# Based on main CI Docker from  g3w-suite, checkout code + caching,
# custom settings file
##
RUN apt update && apt install git -y

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