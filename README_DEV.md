# G3W-SUITE-DOCKER FOR DEVELOPMENT
Follow instructions are for development environment.

1. Copy `.env.example` file into `.env` and edit it: 
   * set `WEBGIS_DOCKER_SHARED_VOLUME` to a specific folder for permanent volume data;
   * set `G3WSUITE_DEBUG` to `True`;
   * set `G3WSUITE_LOCAL_CODE_PATH` with path to your local G3W-SUITE code location.

2. Since the frontend modeul is not available in dev mode, it needs to be disabled in the settings 
   file of the docker project: config/g3w-suite/settings_docker.py

```python
    G3WADMIN_LOCAL_MORE_APPS = [
        'caching',
        'editing',
        'filemanager',
        'qplotly',
        # Uncomment if you wont activate the following module
        #'openrouteservice',
        'qtimeseries',
        # 'frontend'   <-- this needs to be commented
    ]
```

3. Run `docker compose -f docker-compose-dev.yml up -d`.
   1. If all went well G3W-SUITE is running in development mode on http://127.0.0.1:8000

## An example workflow to develop a suite plugin against a given g3w-suite version

Let's assume you need to develop a plugin for the v3.7.8 version of the suite. 
The plugin will be developed in a separate repository, let's call it `my-fantastic-plugin`.

### Step 1: Fork the docker project and set its version to the one you need

```bash
git clone https://github.com/moovida/g3w-suite-docker
cd g3w-suite-docker/
git remote add gis3w https://github.com/g3w-suite/g3w-suite-docker
git checkout v3.7.8 
git checkout -b v3.7.8_my-fantastic-plugin
git push origin v3.7.8_my-fantastic-plugin
```

in the docker-compose-dev.yml choose the right image to address (in this case the v3.7.x train):

```diff
    -    image: g3wsuite/g3w-suite:dev
    +    image: g3wsuite/g3w-suite:v3.7.x
```

### Step 2: Fork the admin project and set its version to the one you need

```bash
git clone https://github.com/moovida/g3w-admin
cd g3w-admin/
git remote add gis3w https://github.com/g3w-suite/g3w-admin
git checkout v3.7.8 
git checkout -b v3.7.8_my-fantastic-plugin
git push origin v3.7.8_my-fantastic-plugin
```

### Step 3: Configure the docker project

Copy the .env.example file and make sure you set the following vars:

```bash
    WEBGIS_DOCKER_SHARED_VOLUME=/SHARED_VOLUME/
    G3WSUITE_DEBUG=True
    G3WSUITE_LOCAL_CODE_PATH=/home/gis3w/g3w-admin/
```

### Step 4: Run the containers

start the docker containers:

```bash
    docker compose -f docker-compose-dev.yml up -d
```
if everythign works, stop it with 
```bash
   docker compose -f docker-compose-dev.yml down`
```

### Step 5: Add your plugin

Plugins are developed as django apps. First get the code in the right place as a git submodule:

If the repo is:

```
    https://github.com/g3w-suite/my-fantastic-plugin
```

adding the app as submodule is done as follows from within the g3w-admin project (not the docker one):

```bash
    cd g3w-admin/
    git submodule add https://github.com/g3w-suite/my-fantastic-plugin my-fantastic-plugin
```

Make sure you add your plugin to the `G3WADMIN_LOCAL_MORE_APPS` list in the `config/g3w-suite/settings_docker.py` file.

```python
    G3WADMIN_LOCAL_MORE_APPS = [
        'caching',
        'editing',
        'filemanager',
        'qplotly',
        'openrouteservice',
        'qtimeseries',
        'my-fantastic-plugin',
    ]
```

### Extra step: develop in debugging mode using vscode

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




## Additional notes

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
