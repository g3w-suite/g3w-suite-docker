# Build the base QGIS Server with Oracle FCGI image
#
# Arguments:
#  QGIS_TAG: git tag from the QGIS repo, ex: final-3_10_12

QGIS_TAG=${QGIS_TAG:-"final-3_10_12"}
DOCKER_DEPS_TAG=${DOCKER_DEPS_TAG:-"release-3_10"}

docker build \
    -f Dockerfile.qgis-server-oracle-3_10.dockerfile \
    --build-arg QGIS_TAG=${QGIS_TAG} \
    -t qgis-server-oracle-3_10:${QGIS_TAG} \
    .
