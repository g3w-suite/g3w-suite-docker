.DEFAULT_GOAL := help

##
# Ensure: "Docker Desktop > Resources > WSL Integration"
##
ifeq ($(OS), Windows_NT)
  $(error make.exe not supported, please try again within a WSL shell: https://docs.docker.com/desktop/wsl/#enabling-docker-support-in-wsl-2-distros)
endif


##
# Set ENV when running: "make dev" or "make prod"
##
ifneq ($(filter dev prod,$(MAKECMDGOALS)),)
  ENV := $(firstword $(filter dev prod,$(MAKECMDGOALS)))
endif

##
# Read ENV from running container label: "com.g3wsuite.env_mode"
##
ifeq ($(ENV),)
  ENV := $(shell docker ps --filter "label=com.docker.compose.service=g3w-suite" --format '{{.Label "com.g3wsuite.env_mode"}}' 2>/dev/null | head -1)
endif

##
# Force ENV to lowercase
##
ENV := $(shell echo $(ENV) | tr '[:upper:]' '[:lower:]')

##
# Fallback to "prod" ("make reload")
##
ifeq ($(and $(filter reload,$(MAKECMDGOALS)),$(if $(ENV),,1)),1)
  ENV := prod
endif

##
# Check ENV (skipped for targets: "", "help", "docker-image", "deploy") 
##
ifeq ($(and $(MAKECMDGOALS),$(filter-out help docker-image deploy,$(MAKECMDGOALS)),$(if $(ENV),,1)),1)
  $(error ENV is not set.)
endif

$(info )
$(info $(if $(filter dev,$(ENV)),[33m🛠️  DEV,[31m🚀 PROD)[0m environment)
$(info )

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
# 🧙 Interactive setup wizard (copies .env.example → .env, configures variables, starts containers)
#
# make deploy
##
deploy:
	@bash ./scripts/makefile/deploy.sh

##
# 🔄 Recreate containers (DEV environment)
#
# make dev
# make dev reload
##
dev: reload

##
# 🔄 Recreate containers (PROD environment)
#
# make prod
# make prod reload
##
prod: reload

##
# 🔄 Recreate containers
#
# make reload
##
reload:
	$(DOCKER_COMPOSE) up -d --force-recreate --remove-orphans $(if $(filter dev,$(ENV)),--build)
ifeq ($(ENV),dev)
	docker image prune -f
endif

##
# 🔑 SSH login
#
# make run-g3w-suite
# make run-postgis
##
run-%:
	$(DOCKER_COMPOSE) start $*
	$(DOCKER_COMPOSE) exec $* bash

##
# 🚨 Nukes your database and reloads demo data
#
# make db-reset
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
# make db-backup ID=name
##
db-backup:
	ENV=$(ENV) ./scripts/makefile/db-backup.sh

##
# 📤 Restore database
#
# make db-restore ID=name
##
db-restore:
	$(DOCKER_COMPOSE) up -d --force-recreate
	ENV=$(ENV) ./scripts/makefile/db-restore.sh

##
# 🔐 Run certbot
#
# make renew-ssl
##
renew-ssl:
	ENV=$(ENV) ./scripts/makefile/renew-ssl.sh
	$(DOCKER_COMPOSE) up -d nginx --force-recreate

##
# 🧠 Memory profiling with memray (live attach to running gunicorn worker)
#
# make memray
##
memray:
	docker compose exec -it g3w-suite bash -c "/scripts/makefile/memray.sh"

##
# 🚀 Stress test with oha (2 simultaneous connections, 200 total requests)
#
# make stress
##
stress:
	@echo "Running stress test with Oha (2 simultaneous connections, 200 total requests)..."
	docker run --rm -it --network=g3w-suite-docker_internal ghcr.io/hatoo/oha -c 2 -n 200 http://g3w-suite:8000/

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