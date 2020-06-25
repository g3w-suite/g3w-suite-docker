#!/bin/bash
# CMD to be run inside the g3w-suite docker, this script is
# volume-mounted (ro) in the docker compose as /cmd.sh

# Start XVfb
rm /tmp/.X99-lock
Xvfb :99 -screen 0 640x480x24 -nolisten tcp &
export DISPLAY=:99
export QGIS_SERVER_PARALLEL_RENDERING=1
# Build the suite
/code/ci_scripts/build_suite.sh
# Setup once
/code/ci_scripts/setup_suite.sh
# Start
cd /code/g3w-admin
gunicorn base.wsgi:application --limit-request-fields 0 --error-logfile - \
    --log-level=debug --timeout 120 --workers=${G3WSUITE_GUNICORN_NUM_WORKERS:-8} -b 0.0.0.0:8000
