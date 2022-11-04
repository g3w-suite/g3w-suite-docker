##
# DOCKER IMAGE: https://hub.docker.com/r/g3wsuite/postgis
# 
# This image extends KARTOZA POSTGISS (DEBIAN + POSTGIS LTR) for development purposes 
##

FROM kartoza/postgis:11.0-2.5

LABEL maintainer="Gis3W" \
      Description="Fix DB restart"

ADD setup-database.sh /