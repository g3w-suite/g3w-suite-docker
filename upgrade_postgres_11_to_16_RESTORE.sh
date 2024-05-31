#!/bin/bash
source update_postgres_11_to_16_BASE.sh

# Create a script for databases restore
echo "#!/bin/bash" > pg_restore.sh
for DB in "${DBS[@]}"; do

  echo "psql $CONNECTION_DB -d ${DB} -c \"create database ${DB}_${SUFFIX_DB};\"" >> pg_restore.sh
  echo "pg_restore $CONNECTION_DB -d ${DB}_${SUFFIX_DB} ${BACKUP_PATH}${DB}.bck" >> pg_restore.sh
  echo "psql ${CONNECTION_DB} -d ${DB}_${SUFFIX_DB} -c \"${QUERY_UPGRADE_POSTGIS}\"" >> pg_restore.sh

  # Close connection
  echo "psql ${CONNECTION_DB} -d ${DB}_${SUFFIX_DB} -c \"${QUERY_CLOSE_CONNECTIONS}'db_name';\"" >> pg_restore.sh

  # Drop old database adn rename the new with old
  echo "psql ${CONNECTION_DB} -d ${DB}_${SUFFIX_DB} -c \"drop database ${DB};\"" >> pg_restore.sh
  echo "psql ${CONNECTION_DB} -d ${DB}_${SUFFIX_DB} -c \"alter database ${DB}_${SUFFIX_DB} rename to ${DB};\"" >> pg_restore.sh

done

docker compose cp pg_restore.sh postgis:/root/
docker compose exec postgis chmod +x /root/pg_restore.sh
#rm pg_restore.sh

docker compose exec postgis bash /root/pg_restore.sh
docker compose restart g3w-suite





