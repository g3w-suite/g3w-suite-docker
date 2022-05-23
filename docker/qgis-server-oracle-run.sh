# Run the QGIS Server with Oracle FCGI container
#
# Arguments:
#  QGIS_TAG: git tag from the QGIS repo, ex: final-3_22_7
#  QGIS_FCGI_PORT: expose port for the FCGI socket, ex: 9333
#
# See also -e in the docker run call below for the environment
# configuration.
#
# To check if the server is listening on the socket:
# cgi-fcgi -bind -connect 127.0.0.1:9333

QGIS_TAG=${QGIS_TAG:-"final-3_22_7"}
QGIS_FCGI_PORT=${QGIS_FCGI_PORT:-"9333"}

docker run -d --init --rm --name qgis-server-oracle \
    -p ${QGIS_FCGI_PORT}:9333 \
    -e QGIS_PREFIX_PATH=/usr \
    -e QGIS_SERVER_LOG_LEVEL=1 \
    -e QGIS_SERVER_LOG_STDERR=1 \
    -e QGIS_SERVER_PARALLEL_RENDERING=1 \
    -e QGIS_SERVER_MAX_THREADS=2 \
    -e QGIS_CUSTOM_CONFIG_PATH=/tmp \
    -e QGIS_AUTH_DB_DIR_PATH=/tmp \
    qgis-server-oracle:${QGIS_TAG}