ifeq ($(env),)
  $(error ENV is not set)
endif

DOCKER_COMPOSE:=docker compose -f $(env)
POSTGIS:=docker compose exec postgis bash

##
# WIP: Migrate database version
##
upgrade-db: PG_VERSION:=11
upgrade-db: check-postgis
	$(DOCKER_COMPOSE) up -d
	$(MAKE) --no-print-directory backup-dbs
	$(DOCKER_COMPOSE) up -d --force-recreate
	$(MAKE) --no-print-directory restore-dbs
	docker compose $(env) restart

##
# Check PG_VERSION and then create a .pgpass in root home
##
check-postgis:
	$(if \
		$(shell $(POSTGIS) -c "test -d /var/lib/postgresql/${PG_VERSION} && echo '1'),, \
		$(error invalid PG_VERSION: ${PG_VERSION}) \
	)

	$(POSTGIS) -c 'echo "postgis:5432:*:$${POSTGRES_USER}:$${POSTGRES_PASS}" > /root/.pgpass'
	$(POSTGIS) -c 'chmod 600 /root/.pgpass'

##
# Backup databases
#
# make backup-dbs env=docker-compose-dev.yml
##
backup-dbs: PG_VERSION:=15
backup-dbs: DB_NAMES:=$(shell $(POSTGIS) -c "printenv POSTGRES_DBNAME | tr ',' ' '")
backup-dbs:	DB_USER:="$(shell $(POSTGIS) -c "printenv POSTGRES_USER")"
backup-dbs: check-postgis
	$(foreach DB, \
		${DB_NAMES}, \
		$(shell $(POSTGIS) -c "pg_dump --host postgis --port 5432 --username ${DB_USER} -d ${DB} --file "/var/lib/postgresql/${PG_VERSION}/${DB}.bck" --verbose --format=c --create --clean") \
	)

##
# Restore databases
#
# make restore-dbs env=docker-compose-dev.yml 
##
restore-dbs: PG_VERSION:=15
restore-dbs: DB_NAMES:=$(shell $(POSTGIS) -c "printenv POSTGRES_DBNAME | tr ',' ' '")
restore-dbs: check-postgis
	$(foreach DB, \
		${DB_NAMES}, \
		$(MAKE) --no-print-directory restore-db DB=$(DB) bck=/var/lib/postgresql/${PG_VERSION}/${DB}.bck \
	)

##
# Restore database (single)
#
# make restore-db env=docker-compose-dev.yml 
##
restore-db: DB_USER:="$(shell $(POSTGIS) -c "printenv POSTGRES_USER")"
restore-db: check-postgis 
	$(POSTGIS) -c 'psql       --host postgis --port 5432 --username ${DB_USER} -d template1    -c "CREATE DATABASE ${DB}_1634;"'
	$(POSTGIS) -c 'pg_restore --host postgis --port 5432 --username ${DB_USER} -d "${DB}_1634" "${bck}"'
	$(POSTGIS) -c 'psql       --host postgis --port 5432 --username ${DB_USER} -d "${DB}_1634" -c "SELECT postgis_extensions_upgrade();"'
	$(POSTGIS) -c 'psql       --host postgis --port 5432 --username ${DB_USER} -d template1    -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname='${DB}';"'
	$(POSTGIS) -c 'psql       --host postgis --port 5432 --username ${DB_USER} -d template1    -c "DROP DATABASE ${DB};"'
	$(POSTGIS) -c 'psql       --host postgis --port 5432 --username ${DB_USER} -d template1    -c "ALTER DATABASE ${DB}_1634 RENAME TO ${DB};"'
