# Build the base QGIS Server with Oracle FCGI image
#
# Arguments:
#  DOCKER_DEPS_TAG: tag for the dependencies base image, ex: release-3_22
#  QGIS_TAG: git tag from the QGIS repo, ex: final-3_22_7

QGIS_TAG=${QGIS_TAG:-"final-3_22_7"}
DOCKER_DEPS_TAG=${DOCKER_DEPS_TAG:-"release-3_22"}

docker build \
    -f Dockerfile.qgis-server-oracle.dockerfile \
    --build-arg DOCKER_DEPS_TAG=${DOCKER_DEPS_TAG} \
    --build-arg QGIS_TAG=${QGIS_TAG} \
    -t qgis-server-oracle:${QGIS_TAG} \
    .
