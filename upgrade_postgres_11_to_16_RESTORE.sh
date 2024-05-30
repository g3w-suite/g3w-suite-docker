#!/bin/bash
source .env

# Create a .pgpass in root home
echo "${G3WSUITE_POSTGRES_HOST}:${G3WSUITE_POSTGRES_PORT}:*:${G3WSUITE_POSTGRES_USER_LOCAL}:${G3WSUITE_POSTGRES_PASS}" > .pgpass
docker compose cp .pgpass postgis:/root/
docker compose exec postgis chmod 600 /root/.pgpass
rm .pgpass

# Create a script fro backup
echo "psql --host ${G3WSUITE_POSTGRES_HOST}  --port ${G3WSUITE_POSTGRES_PORT} --username ${G3WSUITE_POSTGRES_USER_LOCAL} -d g3wsuite -f /var/lib/postgresql/11/g3wsuite.sql" > pg_restore.sh
echo "psql --host ${G3WSUITE_POSTGRES_HOST}  --port ${G3WSUITE_POSTGRES_PORT} --username ${G3WSUITE_POSTGRES_USER_LOCAL} -d g3wsuite -c \"select postgis_extensions_upgrade();\"" >> pg_restore.sh
echo "psql --host ${G3WSUITE_POSTGRES_HOST}  --port ${G3WSUITE_POSTGRES_PORT} --username ${G3WSUITE_POSTGRES_USER_LOCAL} -d data_production -f /var/lib/postgresql/11/data_production.sql" >> pg_restore.sh
echo "psql --host ${G3WSUITE_POSTGRES_HOST}  --port ${G3WSUITE_POSTGRES_PORT} --username ${G3WSUITE_POSTGRES_USER_LOCAL} -d data_production -c \"select postgis_extensions_upgrade();\"" >> pg_restore.sh
echo "psql --host ${G3WSUITE_POSTGRES_HOST}  --port ${G3WSUITE_POSTGRES_PORT} --username ${G3WSUITE_POSTGRES_USER_LOCAL} -d data_testing -f /var/lib/postgresql/11/data_testing.sql" >> pg_restore.sh
echo "psql --host ${G3WSUITE_POSTGRES_HOST}  --port ${G3WSUITE_POSTGRES_PORT} --username ${G3WSUITE_POSTGRES_USER_LOCAL} -d data_testing -c \"select postgis_extensions_upgrade();\"" >> pg_restore.sh

docker compose cp pg_restore.sh postgis:/root/
docker compose exec postgis chmod +x /root/pg_restore.sh
#rm pg_restore.sh

docker compose exec postgis bash /root/pg_restore.sh
docker compose restart g3w-suite





