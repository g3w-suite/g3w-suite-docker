#!/bin/bash
source .env

# Create a .pgpass in root home
echo "${G3WSUITE_POSTGRES_HOST}:${G3WSUITE_POSTGRES_PORT}:*:${G3WSUITE_POSTGRES_USER_LOCAL}:${G3WSUITE_POSTGRES_PASS}" > .pgpass
docker compose cp .pgpass postgis:/root/
docker compose exec postgis chmod 600 /root/.pgpass
rm .pgpass

# Create a script fro backup
echo "pg_dump --file /var/lib/postgresql/11/g3wsuite.sql --host ${G3WSUITE_POSTGRES_HOST}  --port ${G3WSUITE_POSTGRES_PORT} --username ${G3WSUITE_POSTGRES_USER_LOCAL} --verbose --format=p --inserts -d g3wsuite" > pg_backup.sh
echo "pg_dump --file /var/lib/postgresql/11/data_production.sql --host ${G3WSUITE_POSTGRES_HOST}  --port ${G3WSUITE_POSTGRES_PORT} --username ${G3WSUITE_POSTGRES_USER_LOCAL} --verbose --format=p --inserts -d data_production" >> pg_backup.sh
echo "pg_dump --file /var/lib/postgresql/11/data_testing.sql --host ${G3WSUITE_POSTGRES_HOST}  --port ${G3WSUITE_POSTGRES_PORT} --username ${G3WSUITE_POSTGRES_USER_LOCAL} --verbose --format=p --inserts -d data_testing" >> pg_backup.sh

docker compose cp pg_backup.sh postgis:/root/
docker compose exec postgis chmod +x /root/pg_backup.sh
rm pg_backup.sh

docker compose exec postgis bash /root/pg_backup.sh





