ifeq ($(ENV),)
	$(error ENV is not set)
endif

##
# Ensure: "Docker Desktop > Resources > WSL Integration"
##
ifeq ($(OS), Windows_NT) 
	$(error make.exe not supported, please try again within a WSL shell: https://docs.docker.com/desktop/wsl/#enabling-docker-support-in-wsl-2-distros)
endif

##
# ENV = { dev | prod | consumer }
##
ifeq ($(ENV), prod)
	DOCKER_COMPOSE:= docker compose -f docker-compose.yml
else
	DOCKER_COMPOSE:= docker compose -f docker-compose-$(ENV).yml
endif

G3W_SUITE:= docker compose exec g3w-suite

##
# Recreate g3w-suite containers
#
# make db-reset ENV=dev
##
db-reset:
	$(DOCKER_COMPOSE) up -d
	$(G3W_SUITE) bash -c 'rm -rf /shared-volume/cache'
	$(G3W_SUITE) bash -c 'rm -rf /shared-volume/__pycache__'
	$(G3W_SUITE) bash -c 'rm -f /shared-volume/build_done'
	$(G3W_SUITE) bash -c 'rm -f /shared-volume/setup_done'
	$(G3W_SUITE) bash -c 'rm -f /shared-volume/.secret_key'
	$(DOCKER_COMPOSE) up -d --force-recreate
	ID=demo	./scripts/makefile/db-restore.sh

##
# Backup databases
#
# make db-backup ID=name ENV=dev 
##
db-backup:
	./scripts/makefile/db-backup.sh

##
# Restore databases
#
# make db-restore ID=name ENV=dev 
##
db-restore:
	$(DOCKER_COMPOSE) up -d --force-recreate
	./scripts/makefile/db-restore.sh

##
# Run certbot
#
# make renew-ssl ENV=dev
##
renew-ssl:
	./scripts/makefile/renew-ssl.sh
	$(DOCKER_COMPOSE) up -d --force-recreate


##
# Rebuild docker image
#
# make docker-image v=v3.8.x
##
docker-image:
	ifeq ($(v),)
		$(error v is not set)
	endif
	docker build -f Dockerfile.g3wsuite.dockerfile -t g3wsuite/g3w-suite:$(v) --no-cache .
