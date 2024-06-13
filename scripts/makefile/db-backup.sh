#!/bin/bash

##
# ENV = { dev | prod | consumer }
##
if [ -z $ENV ]; then
  echo "ENV is not set"
  exit 1
fi

if [ -z $PG_VERSION ]; then
  echo "PG_VERSION is not set"
  exit 1
fi

if [ "$ENV" = "prod" ]; then
  DOCKER_COMPOSE="docker compose -f docker-compose.yml"
else
  DOCKER_COMPOSE="docker compose -f docker-compose-${ENV}.yml"
fi

source .env

PG_VERSION=${PG_VERSION:-16}
DB_LOGIN="--host ${G3WSUITE_POSTGRES_HOST} --port ${G3WSUITE_POSTGRES_PORT} --username ${G3WSUITE_POSTGRES_USER_LOCAL}"
DB_NAMES="${G3WSUITE_POSTGRES_DBNAME} data_production data_testing"

##
# Check PG_VERSION
##
if [ -z `${DOCKER_COMPOSE} exec postgis bash -c "test -d /var/lib/postgresql/${PG_VERSION} && echo '1'"` ]; then
  echo "invalid PG_VERSION: $PG_VERSION"
  exit 1
fi

##
# Create a .pgpass in root home
##
echo "${G3WSUITE_POSTGRES_HOST}:${G3WSUITE_POSTGRES_PORT}:*:${G3WSUITE_POSTGRES_USER_LOCAL}:${G3WSUITE_POSTGRES_PASS}" > .pgpass
bash -c "$DOCKER_COMPOSE cp .pgpass postgis:/root/"
bash -c "$DOCKER_COMPOSE exec postgis chmod 600 /root/.pgpass"
rm .pgpass

##
# Backup databases 
##
echo "#!/bin/bash" > pg_backup.sh
for DB in $DB_NAMES; do
  cat >> pg_backup.sh << EOF
pg_dump ${DB_LOGIN} -d ${DB} --file /var/lib/postgresql/${PG_VERSION}/${DB}.bck --verbose --format=c --create --clean
EOF
done

bash -c "$DOCKER_COMPOSE cp pg_backup.sh postgis:/root/"
rm pg_backup.sh

bash -c "$DOCKER_COMPOSE exec postgis chmod +x /root/pg_backup.sh"
bash -c "$DOCKER_COMPOSE exec postgis bash /root/pg_backup.sh"
bash -c "$DOCKER_COMPOSE exec postgis rm pg_backup.sh"