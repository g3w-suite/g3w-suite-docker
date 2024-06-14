# G3W-SUITE-DOCKER FOR DEVELOPMENT
Follow instructions are for development environment.

1. Copy `.env.example` file into `.env` and edit it: 
   * set `WEBGIS_DOCKER_SHARED_VOLUME` to a specific folder for permanent volume data;
   * set `G3WSUITE_DEBUG` to `True`;
   * set `G3WSUITE_LOCAL_CODE_PATH` with path to your local G3W-SUITE code location.

2. Run `docker compose -f docker-compose-dev.yml up -d`. \*
   1. If all went well G3W-SUITE is running in development mode on http://127.0.0.1:8000

---
<sub> \* if necessary, comment out any missing installed modules from [G3WADMIN_LOCAL_MORE_APPS](./config/g3w-suite/settings_docker.py) list and then try again </sub>

<sub> \* if you customize [docker-compose-dev.yml](./docker-compose-dev.yml) (eg. by choosing a specific <code>image: <del>g3wsuite/g3w-suite:dev</del> g3wsuite/g3w-suite:v3.7.x</code>) you then apply them via: `docker compose -f docker-compose-dev.yml up -d --force-recreate` </sub> 


## Developing a python plugin (pip install)

Below you can find some sample plugins from which to take inspiration:

- https://github.com/g3w-suite/g3w-admin-ps-timeseries
- https://github.com/g3w-suite/g3w-admin-processing
- https://github.com/g3w-suite/g3w-admin-authjwt

For example, installing a plugin within the docker container (editable mode):

```
docker compose -f docker-compose-dev.yml exec g3w-suite mkdir -p /shared-volume/plugins
docker compose -f docker-compose-dev.yml exec g3w-suite git clone https://github.com/g3w-suite/g3w-admin-ps-timeseries
docker compose -f docker-compose-dev.yml exec g3w-suite pip3 install -v -e /shared-volume/plugins/qps_timeseries
```

**NB:** If the above seems wordy to you, you can also inject a custom script within: [scripts/docker-entrypoint-dev.sh](./scripts/docker-entrypoint-dev.sh)

## Developing a python plugin (git only)

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

Start the containers: 

```bash
    docker compose -f docker-compose-dev.yml up -d 
```

Stop the containers: 

```bash
    docker compose -f docker-compose-dev.yml down
```
    

## Additional notes

<details>
<summary> <h3> Debugging using vscode </h3> </summary>
To develop inside the container with Visual Studio Code, you need to avoid starting up the server when you start the container. To do so, change the last line of the docker-entrypoint-dev.sh from:

```bash
    python3 manage.py runserver 0.0.0.0:8000
```

to

```bash
    # python3 manage.py runserver 0.0.0.0:8000
    tail -f /dev/null
```

This will make sure that the environment for the server to run properly is set, but the server not started.

With the docker plugin of vscode installed, you can attach to the container and start the server manually.

Righ click on the running container and run **Attach Visual Studio Code**. 
Once inside the container run the suite using a newly created launch.json file that looks like:

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
</details>

<details>
<summary> <h3>Connecting to a local DB (PostGIS) </h3> </summary>

If you are working in a mixed setup (ie. a local [postgis](https://postgis.net/) instance + a [g3w-suite-docker](https://github.com/g3w-suite/g3w-suite-docker) container), you should add an `extra_hosts` directive within your `docker-compose-dev.yml` to make your local postgres databases accessible from both sides:

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


