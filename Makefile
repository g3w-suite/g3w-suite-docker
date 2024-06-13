ifeq ($(ENV),)
  $(error ENV is not set)
endif

##
# Ensure: "Docker Desktop > Resources > WSL Integration"
##
ifeq ($(OS),Windows_NT) 
  $(error make.exe not supported, please try again within a WSL shell: https://docs.docker.com/desktop/wsl/#enabling-docker-support-in-wsl-2-distros)
endif

##
# ENV = { dev | prod | consumer }
##
ifeq ($(ENV), "prod")
	DOCKER_COMPOSE:= docker compose -f docker-compose.yml
else
	DOCKER_COMPOSE:= docker compose -f docker-compose-$(ENV).yml
endif

G3W_SUITE:= docker compose exec g3w-suite

##
# Recreate g3w-suite containers
#
# make reset-db ENV=dev
##
reset-db:
	$(G3W_SUITE) bash -c 'rm -f /shared-volume/build_done'
	$(G3W_SUITE) bash -c 'rm -f /shared-volume/setup_done'
	$(DOCKER_COMPOSE) up -d --force-recreate

##
# Backup databases
#
# make backup-db ENV=dev PG_VERSION=16
##
backup-db:
	./scripts/makefile/db-backup.sh

##
# Restore databases
#
# make restore-dbs ENV=dev PG_VERSION=16
##
restore-db:
	./scripts/makefile/db-restore.sh

##
# Run certbot
#
# make renew-ssl ENV=dev
##
renew-ssl:
	./scripts/makefile/renew-ssl.sh
	$(DOCKER_COMPOSE) up -d --force-recreate
