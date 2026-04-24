# G3W-SUITE-DOCKER

[![Build G3W-SUITE image](https://github.com/g3w-suite/g3w-suite-docker/actions/workflows/build_and_push_main_image.yml/badge.svg)](https://github.com/g3w-suite/g3w-suite-docker/actions/workflows/build_and_push_main_image.yml)
[![Build G3W-SUITE LTR dependencies](https://github.com/g3w-suite/g3w-suite-docker/actions/workflows/build_and_push_deps_ltr.yml/badge.svg)](https://github.com/g3w-suite/g3w-suite-docker/actions/workflows/build_and_push_deps_ltr.yml)

Run a self hosted web-gis application with Docker Compose

<details>

<summary><h2> ⬆️ How to upgrade your webgis</h2></summary>

To upgrade your containers (eg. `v3.10.x` → `v3.11.x`):

```sh
# NB:
# • (ENV = dev)      → .env + .env.dev
# • (ENV = prod)     → .env

### BACKUP (v3.10.x) ###

make reload ENV=prod

git fetch
git checkout v3.11.x

make db-backup ID=310 ENV=prod

### RESTORE (v3.11.x) ###

make db-restore ID=310 ENV=prod

### OPTIONAL (delete old DB) ###

docker compose exec g3w-suite bash -c 'rm -r /shared-volume/310'
docker compose exec g3w-suite bash -c 'rm -r /shared-volume/backup/310'
```
  
</details>

---

![Docker structure](docs/img/docker.png)


## 🌍 Deploying your webgis app

Install [docker compose](https://docs.docker.com/compose/install/).

Clone this repository:

```
git clone https://github.com/g3w-suite/g3w-suite-docker/
cd g3w-suite-docker
```

Create a `.env` file starting from [`.env.example`](./.env.example) and tailor it to your needs:

```diff
# CHANGE ME: PostGIS DB password

- G3WSUITE_POSTGRES_PASS='89#kL8y3D'
+ G3WSUITE_POSTGRES_PASS=<your__password>
```

And then start containers:

```sh
docker-compose up -d
```

**NB:** at the very first start, have a lot of patience 😴 → the system must finalize the installation. \*

After some time the suite will be available at:

- http://localhost:8080 (user: `admin`, pass: `admin`)

![Login Page](docs/img/login_page.png)

\* in case of faulty container (eg. the first time you didn't wait long enough before trying to access):

```sh
# 🚨 deletes all data
make db-reset ENV=prod
```

## 💻 How to access into a container 

1. login into a service

```sh
$ make run-postgis ENV=prod

# make run-g3w-suite ENV=prod
# make run-nginx ENV=prod
# make run-redis ENV=prod
```

2. perform your administrative tasks (eg. connect to postgis as "postgres" user):

```sh
root@84ef6a8d23e6:/# su - postgres

postgres@84ef6a8d23e6:~$ psql
psql (11.2 (Debian 11.2-1.pgdg90+1))
Type "help" for help.

postgres=#
```

## 🔒 HTTPS

To enable https with LetsEncrypt::

- uncomment ssl section within `config/nginx/nginx.conf`
- update `WEBGIS_PUBLIC_HOSTNAME` environment variable within the `.env` and `config/nginx/nginx.conf` files
- launch `sudo make renew-ssl`
- make sure the certs are renewed by adding a cron job with `sudo crontab -e` and add the following line:
  `0 3 * * * /<path_to_your_docker_files>/run_certbot.sh`

## 📦 Docker image

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

## 🎨 Style customization

- custom templates folder: `config/g3w-suite/overrides/templates` → a Docker service restart is required to make the changes effective.
- custom logo (see: [docs](https://g3w-suite.readthedocs.io/en/latest/settings.html#general-layout-settings)): `config/g3w-suite/settings_docker.py` → a Docker service restart is required to make the changes effective.
- custom CSS: `config/g3w-suite/overrides/static/style.css` → changes are effective immediately

## 🚀 Performance optimizations

1. set scale-dependent visibility for the entire layer or for some filtered features (example: show only major roads until at scale 1:1E+6)
2. when using rule-based/categorized classification or scale-dependent visibility create indexes on the column(s) involved in the rule expression (example: "create index idx_elec_penwell_ious on elec_penwell_ious (owner);" )
3. start the project with only a few layers turned on by default
4. do not turn on by default base-layers XYZ such as (Google base maps)
5. do not use rule-based/categorized rendering on layers with too many categories (example: elec_penwell_public_power), they are unreadable anyway
6. enable redering simplification for not-point layers, set it to `Distance` `1.2` and check `Enable provider simplification if available`
7. enable cache on linestring and polygon layers (tile cache can be configured and cleared per-layer through the webgis admin panel and lasts forever until it is disabled or cleared)
8. set a cron job on host machine that checks edited features that have been locked for more than 4 hours and frees them:
```
0 */1 * * * docker exec g3w-suite-docker_g3w-suite_1 python3 /code/g3w-admin/manage.py check_features_locked
```

## 🐋 Portainer usage

Portainer (https://www.portainer.io) is a docker-based web application used to edit and manage Docker applications in a simple and intuitive way.

Plese refer to the [Add new stack](https://docs.portainer.io/user/docker/stacks/add) section to learn how to deploy the `docker-compose.yml` stack with Portainer (>= v2.1.1).

## ♻️ Database backup / restore

```sh
# NB:
# • (ENV = dev)      → .env + .env.dev
# • (ENV = prod)     → .env

make reload ENV=prod

make db-backup ID=foo-backup ENV=prod
make db-restore ID=foo-backup ENV=prod
```

## 🛠️ Developers

<details>
<summary> 1. How to Develop </summary>

1. Copy `.env.example` file into `.env` and edit it: 
   * set `WEBGIS_DOCKER_SHARED_VOLUME=./shared-volume` (path to your local data folder);
   * set `G3WSUITE_DEBUG=True`;
   * set `G3WSUITE_LOCAL_CODE_PATH=../g3w-admin` (path to your local G3W-ADMIN repository).

2. Run `make reload ENV=dev`. \*
   1. If all went well G3W-SUITE is running in development mode on http://127.0.0.1:8000

---
<sub> \* if necessary, comment out any missing installed modules from [G3WADMIN_LOCAL_MORE_APPS](./config/g3w-suite/settings_docker.py) list and then try again </sub>

<sub> \* if you customize [docker-composev.yml](./docker-compose.yml) (eg. by choosing a specific <code>image: <del>g3wsuite/g3w-suite:dev</del> g3wsuite/g3w-suite:v3.7.x</code>) you then apply them via: `make reload ENV=dev` </sub> 

</details>

<details>
<summary> 2. Loading default demo </summary>

```
# 🚨 deletes all data
make db-restore ID=demo ENV=dev

# or (a custom backup):

# make db-backup  ID=foo-backup ENV=dev
# make db-restore ID=demo       ENV=dev
# ...
# make db-restore ID=foo-backup ENV=dev
```

</details>

<details>
<summary> 3. Developing a python plugin (pip install) </summary>

Below you can find some sample plugins from which to take inspiration:

- https://github.com/g3w-suite/g3w-admin-ps-timeseries
- https://github.com/g3w-suite/g3w-admin-processing
- https://github.com/g3w-suite/g3w-admin-authjwt

For example, installing a plugin within the docker container (editable mode):

```
make run-g3w-suite ENV=dev
mkdir -p /shared-volume/plugins
git clone https://github.com/g3w-suite/g3w-admin-ps-timeseries
pip3 install -v -e /shared-volume/plugins/qps_timeseries
exit
```

**NB:** If the above seems wordy to you, you can also inject a custom script within: [scripts/docker-entrypoint.sh](./scripts/docker-entrypoint.sh)

</details>

<details>
<summary> 4. Developing a python plugin (git only) </summary>

Below are the steps to develop a new Django app into g3w-admin (as git submodule).

```bash

## Fork g3w-suite (docker + admin)  ##

git clone https://github.com/YOUR-USERNAME/g3w-suite-docker
git clone https://github.com/YOUR-USERNAME/g3w-admin

## Create dev branches (v3.7.8_my-fantastic-plugin) ##

cd g3w-suite-docker
git remote add gis3w https://github.com/g3w-suite/g3w-suite-docker
git checkout v3.7.8 
git checkout -b v3.7.8_my-fantastic-plugin
git push origin v3.7.8_my-fantastic-plugin

cd g3w-admin
git remote add gis3w https://github.com/g3w-suite/g3w-admin
git checkout v3.7.8 
git checkout -b v3.7.8_my-fantastic-plugin
git push origin v3.7.8_my-fantastic-plugin

## Add your plugin into g3w-admin (as git submodule) ##

cd g3w-admin
git submodule add https://github.com/YOUR-USERNAME/my-plugin my-plugin
```

Now customize [.env](./.env) and [settings_docker.py](./config/g3w-suite/settings_docker.py) files to fit your needs, eg:

```bash
# .env
WEBGIS_DOCKER_SHARED_VOLUME=/SHARED_VOLUME/
G3WSUITE_DEBUG=True
G3WSUITE_LOCAL_CODE_PATH=/home/gis3w/g3w-admin/
```

```python
# settings_docker.py
G3WADMIN_LOCAL_MORE_APPS = [
  'caching',
  'editing',
  'filemanager',
  'qplotly',
  'openrouteservice',
  'qtimeseries',
  'my-plugin', # ← YOUR CUSTOM PLUGIN 
]
```

Reload the containers: 

```bash
    make reload ENV=dev
```

</details>

<details>
<summary> 5. Attach the python debugger (vscode) </summary>

You can suppress built-in server within `docker-entrypoint.sh`:

```bash
- gunicorn base.wsgi:application -c /shared-volume/gunicorn.conf.py
+ tail -f /dev/null
```

Attach to the container and start the server manually.

Righ click on the running container and run **Attach Visual Studio Code**. 

Once inside the container run the suite using a newly created `launch.json` file that looks like:

```json
    {
        "version": "0.2.0",
        "configurations": [
            {
                "name": "G3W-Suite dev debug",
                "type": "debugpy",
                "request": "launch",
                "args": [
                    "runserver",
                    "0.0.0.0:8000"
                ],
                "django": true,
                "autoStartBrowser": false,
                "program": "${workspaceFolder}/manage.py"
            }
        ]
    }
```

You should now be able to debug the suite with the common vscode tools.

**For more info:**

- https://code.visualstudio.com/docs/python/debugging
- https://code.visualstudio.com/docs/containers/overview

</details>

<details>
<summary> 6. Connecting to a local DB (PostGIS) </summary>

If you are working in a mixed setup (ie. a local [postgis](https://postgis.net/) instance + a [g3w-suite-docker](https://github.com/g3w-suite/g3w-suite-docker) container), you should add an `extra_hosts` directive within your `docker-compose.yml` to make your local postgres databases accessible from both sides:

![Connecting to a local postgress DB](https://github.com/g3w-suite/g3w-admin/assets/9614886/ade856d2-99ec-4024-ab0d-7c631cfa67e8)

```yaml

  g3w-suite:
    image: g3wsuite/g3w-suite:dev

    ...

    extra_hosts:
      - "postgis16:host-gateway"
```

taking care to edit your `hosts` file accordingly:

```sh
# Added for G3W-SUITE docker
127.0.0.1 postgis16
```

**For more info:**

- https://docs.docker.com/compose/compose-file/compose-file-v3/#extra_hosts

</details>


### Contributors

* GIS3W: [wlorenzetti](https://github.com/wlorenzetti), [raruto](https://github.com/Raruto)
* ItOpen: [elpaso](https://github.com/elpaso)
* Kartoza: [NyakudyaA](https://github.com/NyakudyaA)
* QTIBIA: [tudorbarascu](https://github.com/tudorbarascu)
