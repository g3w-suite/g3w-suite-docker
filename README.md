# G3W-SUITE-DOCKER

[![Build G3W-SUITE image](https://github.com/g3w-suite/g3w-suite-docker/actions/workflows/build_and_push_main_image.yml/badge.svg)](https://github.com/g3w-suite/g3w-suite-docker/actions/workflows/build_and_push_main_image.yml)
[![Build dependencies](https://github.com/g3w-suite/g3w-suite-docker/actions/workflows/build_and_push_deps_ltr.yml/badge.svg)](https://github.com/g3w-suite/g3w-suite-docker/actions/workflows/build_and_push_deps_ltr.yml)

Scripts and recipes for deploying a full blown G3W-SUITE web-gis application with Docker Compose.

<details>

<summary><h2> ⬆️ How to upgrade from v3.7 to v3.8 </h2></summary>

Since **v3.8** PostgreSQL/PostGIS changed from **v11/2.5** to **v16/3.4**, to upgrade follow below steps:

```sh
# NB:
# • (ENV = dev)      → docker-compose-dev.yml
# • (ENV = prod)     → docker-compose.yml
# • (ENV = consumer) → docker-compose-consumer.yml

### BACKUP (v3.7.x) ###

docker compose up -f docker-compose-dev.yml up -d

git fetch
git checkout v3.8.x

make backup-db PG_VERSION=11 ENV=dev

### RESTORE (v3.8.x) ###

make reset-db
make restore-db PG_VERSION=11 ENV=dev

### OPTIONAL (delete old DB) ###

docker compose exec g3w-suite bash -c 'rm -r /shared-volume/11'
```
  
</details>

---

![Docker structure](docs/img/docker.png)


## Deploy

Create a file `.env` (or copy `.env.example` and rename it in `.env`) and place it in the main directory, the file
will contain the database credentials (change `<your password>`) and other settings:

```bash
# External hostname, for docker internal network aliases
WEBGIS_PUBLIC_HOSTNAME=demo.g3wsuite.it/

# Persistent data (projects, database, uploads), mounted into g3w-suite container at: `/shared-volume`
WEBGIS_DOCKER_SHARED_VOLUME=/tmp/shared-volume-g3w-suite

# DB setup
G3WSUITE_POSTGRES_USER_LOCAL=g3wsuite
G3WSUITE_POSTGRES_PASS=<your_password>
G3WSUITE_POSTGRES_DBNAME=g3wsuite
G3WSUITE_POSTGRES_HOST=postgis
G3WSUITE_POSTGRES_PORT=5432


# QGIS Server env variables
# To use PostgreSql Service, mounted into postgis container at: `./secrets/pg_service.conf`,
# ----------------------------------------------------
PGSERVICEFILE=/pg_service/pg_service.conf
```

Start docker containers:

```sh
docker-compose up -d
```

or, if you intend to use [huey](https://github.com/coleifer/huey) (batch processing)

```sh
docker-compose -f docker-compose-consumer.yml up -d
```

**NB:** at the very first start, have a lot of patience 😴 → the system must finalize the installation.

After some time the suite will be available at: http://localhost:8080 (user: `admin`, pass: `admin`)

![Login Page](docs/img/login_page.png)


## Docker image

Docker compose will usually download images from: https://hub.docker.com/u/g3wsuite 

A custom (local) docker image for the suite can be created with:

```bash
docker build -f Dockerfile.g3wsuite.dockerfile -t g3wsuite/g3w-suite:dev --no-cache .

# OPTIONAL:
# docker build -f Dockerfile.g3wsuite-deps.ltr.dockerfile -t g3wsuite/g3w-suite-deps-ltr:dev --no-cache .
```

The image is build on latest Ubuntu and QGIS LTR, following this execution order:

1. [Dockerfile.g3wsuite-deps.ltr.dockerfile](./Dockerfile.g3wsuite-deps.ltr.dockerfile) ← installs Ubuntu and QGIS LTR
2. [Dockerfile.g3wsuite.dockerfile](./Dockerfile.g3wsuite.dockerfile)  ← run "setup.sh" and "docker-entrypoint.sh"
3. [scripts/setup.sh](./scripts/setup.sh) ← install g3w-admin and some other python plugins
4. [scripts/docker-entrypoint.sh](./scripts/docker-entrypoint.sh) ← start gunicorn

### HTTPS

To enable https with LetsEncrypt::

- uncomment ssl section within `config/nginx/nginx.conf`
- update `WEBGIS_PUBLIC_HOSTNAME` environment variable within the `.env` and `config/nginx/nginx.conf` files
- launch `sudo make renew-ssl`
- make sure the certs are renewed by adding a cron job with `sudo crontab -e` and add the following line:
  `0 3 * * * /<path_to_your_docker_files>/run_certbot.sh`

### Caching

Tile cache can be configured and cleared per-layer through the webgis admin panel and lasts forever until it is disabled or cleared.

> Tip: enable cache on linestring and polygon layers.

### Editing

Editing module is active by default, to avoid simultaneous feature editing by two or more users, the editing module works with a feature lock system.
This locking system can remain active if users do not exit the editing state correctly, to avoid this it is advisable to activate a cron job on host machine that checks the features that have been locked for more than 4 hours and frees them:

```
0 */1 * * * docker exec g3w-suite-docker_g3w-suite_1 python3 /code/g3w-admin/manage.py check_features_locked
```

## Front-end App

Set the environment variable
```
FRONTEND=True
```
This will set the front end app as the default app

## Style customization

Templates can now be overridden by placing the overrides in the `config/g3w-suite/overrides/templates`, a Docker service restart is required to make the changes effective.

The logo is also overridden (through `config/g3w-suite/settings_docker.py` which is mounted as a volume), changes to the settings file require the Docker service to be restarted.

A custom CSS is added to the pages, the file is located in `config/g3w-suite/overrides/static/style.css` and can be modified directly, changes are effective immediately.

## Performances optimization

General rules (in no particular order: they are all mandatory):

1. set scale-dependent visibility for the entire layer or for some filtered features (example: show only major roads until at scale 1:1E+6)
2. when using rule-based/categorized classification or scale-dependent visibility create indexes on the column(s) involved in the rule expression (example: "create index idx_elec_penwell_ious on elec_penwell_ious (owner);" )
3. start the project with only a few layers turned on by default
4. do not turn on by default base-layers XYZ such as (Google base maps)
5. do not use rule-based/categorized rendering on layers with too many categories (example: elec_penwell_public_power), they are unreadable anyway
6. enable redering simplification for not-point layers, set it to `Distance` `1.2` and check `Enable provider simplification if available`

## PostgreSQL administration

Postgres is running into a Docker container, in order to access the container, you can follow the instruction below:

### Check the container name

```bash
$ docker ps | grep postgis
84ef6a8d23e6        g3wsuite/postgis:11.0-2.5       "/bin/sh -c /docker-…"   2 days ago          Up 2 days           0.0.0.0:5438->5432/tcp           g3wsuitedocker_postgis_1
```

In the above example the container name is `g3wsuitedocker_postgis_1`

### Log into the container

```bash
$ docker exec -it g3wsuitedocker_postgis_1 bash
```

### Become postgres user

```bash
root@84ef6a8d23e6:/# su - postgres
```

### Connect to postgis

```bash
postgres@84ef6a8d23e6:~$ psql
psql (11.2 (Debian 11.2-1.pgdg90+1))
Type "help" for help.

postgres=#
```

## Portainer usage

Portainer (https://www.portainer.io) is a docker-based web application used to edit and manage Docker applications in a simple and intuitive way.

Plese refer to the [Add new stack](https://docs.portainer.io/v/ce-2.9/user/docker/stacks/add) section to learn how to deploy the `docker-compose-consumer.yml` stack with Portainer (>= v2.1.1).

### Contributors
* Walter Lorenzetti - Gis3W ([@wlorenzetti](https://github.com/wlorenzetti))
* Alessandro Pasotti - ItOpen ([@elpaso](https://github.com/elpaso))
* Mazano - Kartoza ([@NyakudyaA](https://github.com/NyakudyaA))
