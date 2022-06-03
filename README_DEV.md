# G3W-SUITE-DOCKER OFR DEVELOPMENT
Follow instructions are for development environment.

1. Copy `.env.example` file into `.env` and edit it: 
   * set `WEBGIS_DOCKER_SHARED_VOLUME` to a specific folder for permanent volume data;
   * set `G3WSUITE_DEBUG` to `True`;
   * set `G3WSUITE_LOCAL_CODE_PATH` with path to your local G3W-SUITE code location.

2. Run `docker compose -f docker-compose-dev.yml up -d`.
   1. If all went well G3W-SUITE is running in development mode on http://127.0.0.1:8000