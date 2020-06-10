#!/bin/bash
# Run certbot docker container to renew the HTTPS certificate.
# Requires .env file with container configuration variables

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source ${CURRENT_DIR}/.env

if [ "${WEBGIS_PUBLIC_HOSTNAME}" = "" ]; then
    echo "WEBGIS_PUBLIC_HOSTNAME not defined: exiting"
    exit 1
fi

if [ "${WEBGIS_DOCKER_SHARED_VOLUME}" = "" ]; then
    echo "WEBGIS_DOCKER_SHARED_VOLUME not defined: exiting"
    exit 1
fi

mkdir -p "${WEBGIS_DOCKER_SHARED_VOLUME}/certs/letsencrypt/"

curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "${WEBGIS_DOCKER_SHARED_VOLUME}/certs/letsencrypt/options-ssl-nginx.conf"
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "${WEBGIS_DOCKER_SHARED_VOLUME}/certs/letsencrypt/ssl-dhparams.pem"

docker run -it --rm --name certbot \
  -v ${WEBGIS_DOCKER_SHARED_VOLUME}/certs/letsencrypt:/etc/letsencrypt \
  -v ${WEBGIS_DOCKER_SHARED_VOLUME}/var/www/.well-known:/var/www/.well-known \
  certbot/certbot -t certonly \
  --agree-tos --renew-by-default \
  --no-eff-email \
  --webroot -w /var/www \
  -d ${WEBGIS_PUBLIC_HOSTNAME}
