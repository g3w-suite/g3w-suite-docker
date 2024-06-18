#!/bin/bash
# Entrypoint script for Development purposes.
# -------------------------------------------

figlet -t "G3W-SUITE" && echo -e "v`git tag --sort=v:refname | tail -1 | sed 's/^v//'`\n"

# Start XVfb
if [[  -f /tmp/.X99-lock ]]; then
  rm /tmp/.X99-lock
fi
Xvfb :99 -screen 0 640x480x24 -nolisten tcp &
export DISPLAY=:99
export QGIS_SERVER_PARALLEL_RENDERING=1
# Start
cd /code/g3w-admin

# Build the suite
/code/ci_scripts/build_suite.sh
# Setup once
/code/ci_scripts/setup_suite.sh

# To get git properties loose on code overrides.
git config --global --add safe.directory /code

# Start Django server
gunicorn base.wsgi:application -c /shared-volume/gunicorn.conf.py
