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
ifeq ($(ENV), "prod")
	DOCKER_COMPOSE:= docker compose -f docker-compose.yml
else
	DOCKER_COMPOSE:= docker compose -f docker-compose-$(ENV).yml
endif

G3W_SUITE:= docker compose exec g3w-suite

##
# Backup databases
#
# make db-backup ENV=dev PG_VERSION=16
##
db-backup:
	./scripts/makefile/db-backup.sh

##
# Restore databases
#
# make db-restore ENV=dev PG_VERSION=16
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
