#!/bin/bash

##
# ENV = { dev | prod | consumer }
##
if [ -z $ENV ]; then
  echo "ENV is not set"
  exit 1
fi

if [ -z $ID ]; then
  echo "ID is not set"
  exit 1
fi

if [ "$ENV" = "prod" ]; then
  DOCKER_COMPOSE="docker compose -f docker-compose.yml"
else
  DOCKER_COMPOSE="docker compose -f docker-compose-${ENV}.yml"
fi

source .env

PG_VERSION=`${DOCKER_COMPOSE} exec postgis bash -c pg_config --version | awk '{print $2}' | cut -d'.' -f1`
DB_LOGIN="--host ${G3WSUITE_POSTGRES_HOST} --port ${G3WSUITE_POSTGRES_PORT} --username ${G3WSUITE_POSTGRES_USER_LOCAL}"
DB_NAMES="${G3WSUITE_POSTGRES_DBNAME} data_production data_testing"
ID=${ID:-$PG_VERSION}

##
# Check ID:
#
# - /shared-volume/backup/${ID}
# - /tmp/g3w-suite-demo-projects/backup/${ID} 
##
if [ -z `${DOCKER_COMPOSE} exec g3w-suite bash -c "test -d /shared-volume/backup/${ID} && echo '1'"` ]; then

  # Extract backup from remote repository
  if [ ! -d "/tmp/g3w-suite-demo-projects" ]; then
      bash -c "$DOCKER_COMPOSE exec g3w-suite git clone https://github.com/g3w-suite/g3w-suite-demo-projects.git --single-branch --depth 1 --branch master /tmp/g3w-suite-demo-projects"
  else
      bash -c "$DOCKER_COMPOSE exec g3w-suite git config --global --add safe.directory /tmp/g3w-suite-demo-projects"
      bash -c "$DOCKER_COMPOSE exec g3w-suite git -C /tmp/g3w-suite-demo-projects pull https://github.com/g3w-suite/g3w-suite-demo-projects.git"
  fi
  if [ ! -z `${DOCKER_COMPOSE} exec g3w-suite bash -c "test -d /tmp/g3w-suite-demo-projects/backup/${ID} && echo '1'"` ]; then
    bash -c "$DOCKER_COMPOSE exec g3w-suite cp -r /tmp/g3w-suite-demo-projects/backup/${ID} /shared-volume/backup"
  fi

  # check id (same as: /shared-volume/backup/${ID})
  if [ -z `${DOCKER_COMPOSE} exec postgis bash -c "test -d /var/lib/postgresql/backup/${ID} && echo '1'"` ]; then
    echo "invalid ID: $ID"
    exit 1
  fi

fi

##
# Create a .pgpass in root home
##
echo "${G3WSUITE_POSTGRES_HOST}:${G3WSUITE_POSTGRES_PORT}:*:${G3WSUITE_POSTGRES_USER_LOCAL}:${G3WSUITE_POSTGRES_PASS}" > .pgpass
bash -c "$DOCKER_COMPOSE cp .pgpass postgis:/root/"
bash -c "$DOCKER_COMPOSE exec postgis chmod 600 /root/.pgpass"
rm .pgpass

##
# Restore databases 
##
echo "#!/bin/bash" > pg_restore.sh

# Wait until database is ready
cat >> pg_restore.sh << EOF
until pg_isready; do
  echo "wait 30s until is ready"
  sleep 30;
done
EOF

for DB in $DB_NAMES; do
  cat >> pg_restore.sh << EOF
psql ${DB_LOGIN}       -d template1   -c "DROP DATABASE IF EXISTS ${DB}_1634;"
psql ${DB_LOGIN}       -d template1   -c "create database ${DB}_1634;"
pg_restore ${DB_LOGIN} -d ${DB}_1634 /var/lib/postgresql/backup/${ID}/${DB}.bck
psql ${DB_LOGIN}       -d ${DB}_1634  -c "select postgis_extensions_upgrade();"
psql ${DB_LOGIN}       -d template1   -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname='${DB}';"
psql ${DB_LOGIN}       -d template1   -c "drop database ${DB};"
psql ${DB_LOGIN}       -d template1   -c "alter database ${DB}_1634 rename to ${DB};"
EOF
done

bash -c "$DOCKER_COMPOSE cp pg_restore.sh postgis:/root/"
rm pg_restore.sh

bash -c "$DOCKER_COMPOSE exec postgis chmod +x /root/pg_restore.sh"
bash -c "$DOCKER_COMPOSE exec postgis bash /root/pg_restore.sh"
bash -c "$DOCKER_COMPOSE exec postgis rm /root/pg_restore.sh"

##
# Restart g3w-suite container 
##
bash -c "$DOCKER_COMPOSE restart g3w-suite"
