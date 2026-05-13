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
# Delegate builds to buildx (for better performance)
##
export COMPOSE_BAKE=true

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
  WEBGIS_DOCKER_SHARED_VOLUME := $(shell grep -E '^WEBGIS_DOCKER_SHARED_VOLUME=' .env.dev 2>/dev/null | cut -d'=' -f2- | tr -d '[:space:]')
  $(shell rm ./code/plugins)
  $(shell rm -rf ./code)
  $(info $(shell command -v wslpath >/dev/null && cmd.exe /c "mklink /J $$(wslpath -aw "./code") $$(wslpath -aw "$(G3WSUITE_LOCAL_CODE_PATH)")" || ln -s "$(G3WSUITE_LOCAL_CODE_PATH)" ./code))
  $(info $(shell command -v wslpath >/dev/null && cmd.exe /c "mklink /J $$(wslpath -aw "./code/plugins") $$(wslpath -aw "$(WEBGIS_DOCKER_SHARED_VOLUME)/plugins")" || ln -s "$(WEBGIS_DOCKER_SHARED_VOLUME)/plugins" ./code/plugins))
endif

##
# 💡 Show available targets
#
# make help
##
help:
	@echo "\nUsage: make [target] ENV={dev|prod}\n"
	@echo "Available targets:\n"
	@awk '/^##?[[:space:]]/{sub(/^##?[[:space:]]/,""); h=h $$0 "\n"; next} /^[a-zA-Z0-9%_-]+:/ && $$0 !~ /^[a-zA-Z0-9%_-]+:=/{if(h){t=$$1; sub(/:.*/,"",t); if(t!="help"){sub(/\n+$$/,"",h); gsub(/\n/,"\n                     ",h); printf "\033[36m%-20s\033[0m %s\n\n",t,h}}; h=""; next} /^\t/{h=""}' $(MAKEFILE_LIST)

##
# 🔄 Reload compose configuration (force recreation)
#
# make reload ENV=prod
# make reload ENV=dev
##
reload:
	$(DOCKER_COMPOSE) up -d --force-recreate --remove-orphans $(if $(filter dev,$(ENV)),--build)
ifeq ($(ENV),dev)
	docker image prune -f
endif

##
# 🔑 SSH login
#
# make run-g3wsuite ENV=dev
# make run-postgis ENV=dev
##
run-%:
	$(DOCKER_COMPOSE) start $*
	docker exec -it $$(docker ps | grep $* | head -1 | awk '{print $$1}') bash

##
# 🚨 Nukes your database and reloads demo data
#
# make deb-reset ENV=dev
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
# 📥 Backup database
#
# make db-backup ID=name ENV=dev 
##
db-backup:
	ENV=$(ENV) ./scripts/makefile/db-backup.sh

##
# 📤 Restore database
#
# make db-restore ID=name ENV=dev 
##
db-restore:
	$(DOCKER_COMPOSE) up -d --force-recreate
	ENV=$(ENV) ./scripts/makefile/db-restore.sh

##
# 🔐 Run certbot
#
# make renew-ssl ENV=dev
##
renew-ssl:
	ENV=$(ENV) ./scripts/makefile/renew-ssl.sh
	$(DOCKER_COMPOSE) up -d nginx --force-recreate

##
# 🏗️  Build a docker image
#
#   make docker-image [v=<stage>:<tag>] [ENV_VARIABLES=value]
#
# Valid Stages (v):
#   suite (default), deps, deps-ltr, deps-mssql, oracle
#
# Examples:
#   make docker-image                             # Default (suite:dev)
#   make docker-image v=suite:v3.8.x              # Specific suite tag
#   make docker-image v=deps:dev                  # Dev dependencies
#   make docker-image v=deps-ltr:dev              # LTR dev dependencies
#   make docker-image v=deps-mssql:ltr-mssql      # MS SQL dependencies
#   make docker-image v=oracle:dev QGIS_DEPS_TAG=release-3_22 QGIS_TAG=final-3_22_7
##
_DOCKER_STAGE_suite      := suite
_DOCKER_STAGE_deps-ltr   := deps
_DOCKER_STAGE_deps       := deps
_DOCKER_STAGE_deps-mssql := deps
_DOCKER_STAGE_oracle     := qgis-oracle

_DOCKER_TAG_suite        := g3wsuite/g3w-suite
_DOCKER_TAG_deps-ltr     := g3wsuite/g3w-suite-deps-ltr
_DOCKER_TAG_deps         := g3wsuite/g3w-suite-deps
_DOCKER_TAG_deps-mssql   := g3wsuite/g3w-suite-deps
_DOCKER_TAG_oracle       := g3wsuite/g3w-suite-qgis-oracle

_DOCKER_ARGS_deps        := --build-arg QGIS_CHANNEL=ubuntu # ubuntu (latest) | ubuntu-ltr (LTR) 
_DOCKER_ARGS_deps-mssql  := --build-arg INSTALL_MSSQL=true  # adds MS SQL ODBC driver ⚠  By using INSTALL_MSSQL=true you agree to the Microsoft END USER LICENSE AGREEMENT (ACCEPT_EULA=Y)
_DOCKER_ARGS_oracle       = $(if $(QGIS_DEPS_TAG),--build-arg DOCKER_DEPS_TAG=$(QGIS_DEPS_TAG)) $(if $(QGIS_TAG),--build-arg QGIS_TAG=$(QGIS_TAG))

v     ?= suite
stage := $(word 1,$(subst :, ,$(v)))
tag   := $(if $(findstring :,$(v)),$(word 2,$(subst :, ,$(v))),dev)

docker-image:
	docker build --target $(_DOCKER_STAGE_$(stage)) \
		$(_DOCKER_ARGS_$(stage)) \
		-t $(_DOCKER_TAG_$(stage)):$(tag) --no-cache .

##
# 🗺️  Run QGIS Server with Oracle FCGI
#
# make run-oracle QGIS_TAG=final-3_22_7
# make run-oracle QGIS_TAG=final-3_22_7 QGIS_FCGI_PORT=9334
##
run-oracle:
	docker run -d --init --rm --name qgis-server-oracle \
		-p ${QGIS_FCGI_PORT:-9333}:9333 \
		-e QGIS_PREFIX_PATH=/usr \
		-e QGIS_SERVER_LOG_LEVEL=1 \
		-e QGIS_SERVER_LOG_STDERR=1 \
		-e QGIS_SERVER_PARALLEL_RENDERING=1 \
		-e QGIS_SERVER_MAX_THREADS=2 \
		-e QGIS_CUSTOM_CONFIG_PATH=/tmp \
		-e QGIS_AUTH_DB_DIR_PATH=/tmp \
		g3wsuite/g3w-suite-qgis-oracle:${QGIS_TAG:-final-3_22_7}