
source .env

CONNECTION_DB="--host ${G3WSUITE_POSTGRES_HOST}  --port ${G3WSUITE_POSTGRES_PORT} --username ${G3WSUITE_POSTGRES_USER_LOCAL}"
RESTORE_CONNECTION_DBNAME='template1'
PGPASS="${G3WSUITE_POSTGRES_HOST}:${G3WSUITE_POSTGRES_PORT}:*:${G3WSUITE_POSTGRES_USER_LOCAL}:${G3WSUITE_POSTGRES_PASS}"
BACKUP_PATH="/var/lib/postgresql/11/"
SUFFIX_DB="1634"
QUERY_UPGRADE_POSTGIS="select postgis_extensions_upgrade();"
QUERY_CLOSE_CONNECTIONS="SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname="
DBS="${G3WSUITE_POSTGRES_DBNAME} data_production data_testing"
DBS=($DBS)

# Create a .pgpass in root home
echo ${PGPASS} > .pgpass
docker compose cp .pgpass postgis:/root/
docker compose exec postgis chmod 600 /root/.pgpass
rm .pgpass