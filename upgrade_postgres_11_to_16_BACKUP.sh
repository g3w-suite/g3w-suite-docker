#!/bin/bash

source update_postgres_11_to_16_BASE.sh

# Create a script fro backup
echo "#!/bin/bash" > pg_backup.sh
for DB in "${DBS[@]}"; do

  echo "pg_dump --file ${BACKUP_PATH}${DB}.bck ${CONNECTION_DB} --verbose --format=c --create --clean -d ${DB}" >> pg_backup.sh

done

docker compose cp pg_backup.sh postgis:/root/
docker compose exec postgis chmod +x /root/pg_backup.sh
rm pg_backup.sh

docker compose exec postgis bash /root/pg_backup.sh





