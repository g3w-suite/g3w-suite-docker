.DEFAULT_GOAL := help

##
# Ensure: "Docker Desktop > Resources > WSL Integration"
##
ifeq ($(OS), Windows_NT)
  $(error make.exe not supported, please try again within a WSL shell: https://docs.docker.com/desktop/wsl/#enabling-docker-support-in-wsl-2-distros)
endif

##
# Force ENV to lowercase
##
override ENV := $(shell echo $(ENV) | tr '[:upper:]' '[:lower:]')

##
# Check ENV (skipped for targets: "", "help", "docker-image") 
##
ifeq ($(and $(MAKECMDGOALS),$(filter-out help docker-image,$(MAKECMDGOALS)),$(if $(ENV),,1)),1)
  $(error ENV is not set.)
endif

##
# ENV = { dev | prod }
##
DOCKER_COMPOSE := docker compose --env-file .env $(if $(wildcard .env.$(ENV)),--env-file .env.$(ENV)) -f docker-compose.yml

G3W_SUITE:= docker compose exec g3w-suite

##
# DEV MODE: symlink `G3WSUITE_LOCAL_CODE_PATH` → `./code`
##
ifeq ($(ENV),dev)
  G3WSUITE_LOCAL_CODE_PATH := $(shell grep -E '^G3WSUITE_LOCAL_CODE_PATH=' .env.dev 2>/dev/null | cut -d'=' -f2- | tr -d '[:space:]')
  $(shell rm -rf ./code)
  $(info $(shell command -v wslpath >/dev/null && cmd.exe /c "mklink /J $$(wslpath -aw "./code") $$(wslpath -aw "$(G3WSUITE_LOCAL_CODE_PATH)")" || ln -s "$(G3WSUITE_LOCAL_CODE_PATH)" ./code))
endif

##
# Show available targets
#
# make help
##
help:
	@echo "\nUsage: make [target] ENV={dev|prod}\n"
	@echo "Available targets:\n"
	@awk '/^##?[[:space:]]/{sub(/^##?[[:space:]]/,""); h=h $$0 "\n"; next} /^[a-zA-Z0-9%_-]+:/ && $$0 !~ /^[a-zA-Z0-9%_-]+:=/{if(h){t=$$1; sub(/:.*/,"",t); if(t!="help"){sub(/\n+$$/,"",h); gsub(/\n/,"\n                     ",h); printf "\033[36m%-20s\033[0m %s\n\n",t,h}}; h=""; next} /^\t/{h=""}' $(MAKEFILE_LIST)

##
# Reload compose configuration
#
# make reload ENV=prod
# make reload ENV=dev
##
reload:
	$(DOCKER_COMPOSE) up -d --force-recreate --remove-orphans

##
# SSH login
#
# make run-g3wsuite ENV=dev
# make run-postgis ENV=dev
##
run-%:
	$(DOCKER_COMPOSE) start $*
	docker exec -it $$(docker ps | grep $* | head -1 | awk '{print $$1}') bash

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
	ENV=$(ENV) ID=demo ./scripts/makefile/db-restore.sh

##
# Backup databases
#
# make db-backup ID=name ENV=dev 
##
db-backup:
	ENV=$(ENV) ./scripts/makefile/db-backup.sh

##
# Restore databases
#
# make db-restore ID=name ENV=dev 
##
db-restore:
	$(DOCKER_COMPOSE) up -d --force-recreate
	ENV=$(ENV) ./scripts/makefile/db-restore.sh

##
# Run certbot
#
# make renew-ssl ENV=dev
##
renew-ssl:
	ENV=$(ENV) ./scripts/makefile/renew-ssl.sh
	$(DOCKER_COMPOSE) up -d nginx --force-recreate

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