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

certs_folder="${WEBGIS_DOCKER_SHARED_VOLUME}/certs/letsencrypt"
acme_folder="${WEBGIS_DOCKER_SHARED_VOLUME}/var/www/.well-known"
default_ssl_conf="https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf"
default_ssl_pem="https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem"
domain="$WEBGIS_PUBLIC_HOSTNAME"

# STEP 1
echo "### Downloading recommended TLS parameters ..."
mkdir -p "$certs_folder"
curl -s "$default_ssl_conf" > "${certs_folder}/options-ssl-nginx.conf"
curl -s "$default_ssl_pem"  > "${certs_folder}/ssl-dhparams.pem"

# STEP 2
echo "### Requesting Let's Encrypt certificate for $domain ..."
docker run -it --rm --name certbot --pull=missing \
  -v ${certs_folder}:/etc/letsencrypt \
  -v ${acme_folder}:/var/www/.well-known \
  certbot/certbot -t certonly \
  --agree-tos --renew-by-default \
  --no-eff-email \
  --webroot -w /var/www \
  -d ${domain}
