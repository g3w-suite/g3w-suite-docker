#!/bin/bash

cd /root

##
# Create a .pgpass in root home
##
echo "postgis:5432:*:${POSTGRES_USER}:${POSTGRES_PASS}" > .pgpass

chmod 600 .pgpass

# Skip on missing "/var/lib/postgresql/11" directory
if [ ! -d "/var/lib/postgresql/11" ]; then
  return;
fi

##
# Create backup/restore scripts 
##
IFS=',' read -r -a DB_NAMES <<< "$POSTGRES_DBNAME" # DB_NAMES=("g3wsuite" "data_production" "data_testing")

DB_CONNECTION="--host postgis --port 5432 --username ${POSTGRES_USER}"

echo "#!/bin/bash" > pg_backup.sh
echo "#!/bin/bash" > pg_restore.sh

for DB in "${DB_NAMES[@]}"; do

  cat >> pg_backup.sh << EOF

### ${DB} ###
pg_dump ${DB_CONNECTION} -d ${DB} --file /var/lib/postgresql/11/${DB}.bck --verbose --format=c --create --clean
EOF

  cat >> pg_restore.sh << EOF

### ${DB} ###
psql       ${DB_CONNECTION} -d template1 -c \"CREATE DATABASE ${DB}_1634;\"
pg_restore ${DB_CONNECTION} -d ${DB}_1634 /var/lib/postgresql/11/${DB}.bck
psql       ${DB_CONNECTION} -d ${DB}_1634 -c \"SELECT postgis_extensions_upgrade();\"
psql       ${DB_CONNECTION} -d template1 -c \"SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname='${DB}';\"
psql       ${DB_CONNECTION} -d template1 -c \"DROP DATABASE ${DB};\"
psql       ${DB_CONNECTION} -d template1 -c \"ALTER DATABASE ${DB}_1634 RENAME TO ${DB};\"
EOF
done

chmod +x pg_backup.sh
chmod +x pg_restore.sh
