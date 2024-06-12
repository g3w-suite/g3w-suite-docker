ifeq ($(ENV),)
  $(error ENV is not set)
endif

##
# ENV = { dev | prod | consumer }
##
ifeq ($(ENV), "prod")
	DOCKER_COMPOSE:= docker compose -f docker-compose.yml
else
	DOCKER_COMPOSE:= docker compose -f docker-compose-$(ENV).yml
endif

POSTGIS:=        docker compose exec postgis bash
G3W_SUITE:=      docker compose exec g3w-suite bash
DB_LOGIN:=       --host postgis --port 5432 --username "$(shell $(POSTGIS) -c "printenv POSTGRES_USER")"
DB_NAMES:=       $(shell $(POSTGIS) -c "printenv POSTGRES_DBNAME | tr ',' ' '")

##
# Recreate g3w-suite containers
#
# make reset-db ENV=dev
##
reset-db:
	$(G3W_SUITE) -c 'rm -f /shared-volume/build_done'
	$(G3W_SUITE) -c 'rm -f /shared-volume/setup_done'
	$(DOCKER_COMPOSE) up -d --force-recreate

##
# Backup databases
#
# make backup-dbs ENV=dev
##
backup-dbs: PG_VERSION:=15
backup-dbs: check-postgis
	$(foreach DB, \
		${DB_NAMES}, \
		$(shell $(POSTGIS) -c "pg_dump ${DB_LOGIN} -d ${DB} --file "/var/lib/postgresql/${PG_VERSION}/${DB}.bck" --verbose --format=c --create --clean") \
	)

##
# Restore databases
#
# make restore-dbs ENV=dev 
##
restore-dbs: PG_VERSION:=15
restore-dbs: check-postgis
	$(foreach DB, \
		${DB_NAMES}, \
		$(MAKE) --no-print-directory restore-db DB=$(DB) bck=/var/lib/postgresql/${PG_VERSION}/${DB}.bck \
	)

##
# Restore database (single)
#
# make restore-db ENV=dev 
##
restore-db: check-postgis 
	$(POSTGIS) -c "psql       ${DB_LOGIN} -d template1    -c \"DROP DATABASE IF EXISTS ${DB}_1634;\""
	$(POSTGIS) -c "psql       ${DB_LOGIN} -d template1    -c \"CREATE DATABASE ${DB}_1634;\""
	$(POSTGIS) -c "pg_restore ${DB_LOGIN} -d "${DB}_1634" ${bck}"
	$(POSTGIS) -c "psql       ${DB_LOGIN} -d "${DB}_1634" -c \"SELECT postgis_extensions_upgrade();\""
	$(POSTGIS) -c "psql       ${DB_LOGIN} -d template1    -c \"SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname='${DB}';\""
	$(POSTGIS) -c "psql       ${DB_LOGIN} -d template1    -c \"DROP DATABASE ${DB};\""
	$(POSTGIS) -c "psql       ${DB_LOGIN} -d template1    -c \"ALTER DATABASE ${DB}_1634 RENAME TO ${DB};\""

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
