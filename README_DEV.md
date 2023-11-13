# G3W-SUITE-DOCKER FOR DEVELOPMENT
Follow instructions are for development environment.

1. Copy `.env.example` file into `.env` and edit it: 
   * set `WEBGIS_DOCKER_SHARED_VOLUME` to a specific folder for permanent volume data;
   * set `G3WSUITE_DEBUG` to `True`;
   * set `G3WSUITE_LOCAL_CODE_PATH` with path to your local G3W-SUITE code location.

2. Run `docker compose -f docker-compose-dev.yml up -d`.
   1. If all went well G3W-SUITE is running in development mode on http://127.0.0.1:8000
  

## Additional notes

If you are working in a mixed setup (ie. a local [postgis](https://postgis.net/) instance + a [g3w-suite-docker](https://github.com/g3w-suite/g3w-suite-docker) container), you should add an `extra_hosts` directive within your `docker-compose-dev.yml` to make your local postgres databases accessible from both sides:

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
