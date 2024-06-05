# UPGRADE POSTGRESQL

With **g3w-suite-docker v3.8.x** the **PostgreSQL** administrative database of G3W-SUITE it was upgraded from version **11** (with **PostGIS** at version **2.5**) to 
version **16** (with **PostGIS** at version **3.4**).

This upgrade _create a new PostgreSQL cluster_ and is necessary make a dump and restore of databases existing.

The following upgrade procedure make it in 4 step.

### 1. Checkout of new version
Make sure that you current g3w-suite-docker at version v3.7.x is running.
Make a fetch of g3w-suite-docker and checkout of new v3.8.x branch:

```shell
git fetch
git checkout v3.8.x
```

### 2. Make backup of current databases
Run the [upgrade_postgres_11_to_16_BACKUP.sh](upgrade_postgres_11_to_16_BACKUP.sh):
```shell
./upgrade_postgres_11_to_16_BACKUP.sh
```

### 3. Run the new v3.8.x version
```shell
docker compose down
docker compose up -d
```
if you are running the version with consumer container:

```shell
docker compose -f docker-compose-consumer.yml down
docker compose -f docker-compose-consumer.yml up -d
```

This statement will pull the new **g3wsuite/g3w-suite:v3.8.x** from Docker hub, but you can build als in local:
```shell
docker build -f Dockerfile.g3wsuite.dockerfile -t g3wsuite/g3w-suite:v3.8.x --no-cache .
```

### 4. Make databases restore
Run the [upgrade_postgres_11_to_16_RESTORE.sh](upgrade_postgres_11_to_16_RESTORE.sh)
```shell
./upgrade_postgres_11_to_16_RESTORE.sh
```
This script make the databases restore and it will restart the _g3w-suite_ container. If you are running the consumer version
remember to restart also the _consumer_ container: 
```shell
docker compose -f docker-compose-consumer.yml restart g3w-suite-consumer
```

If <u>everything worked</u>, you can delete the old **PostgreSQL 11 cluster** from your _WEBGIS_DOCKER_SHARED_VOLUME_
```shell
source .env
sudo rm -r ${WEBGIS_DOCKER_SHARED_VOLUME}/11
```
