#!/bin/bash
# Entrypoint script fro deploy production
# ---------------------------------------

# Start XVfb
if [[  -f /tmp/.X99-lock ]]; then
  rm /tmp/.X99-lock
fi
Xvfb :99 -screen 0 640x480x24 -nolisten tcp &
export DISPLAY=:99
export QGIS_SERVER_PARALLEL_RENDERING=1
# Start
cd /code/g3w-admin

# When building in dev env you might want a clean build each time.
if [[ -z "${DEV}" ]]; then
  rm -rf /shared-volume/build_done
fi

# To get git properties loose on code overrides.
if [[ -z "${G3WSUITE_LOCAL_CODE_PATH}" ]] ; then
  git config --global --add safe.directory /code
fi

# Activate the front end app settings
if [[ "${FRONTEND}" =~ [Tt][Rr][Uu][Ee] ]] ; then
  SETTINGS_LOCKFILE=/shared-volume/.settings.lockfile
  if [[ ! -f ${SETTINGS_LOCKFILE} ]]; then
    echo "FRONTEND = True"  >> /code/g3w-admin/base/settings/local_settings.py
    echo "FRONTEND_APP = 'frontend'" >> /code/g3w-admin/base/settings/local_settings.py
    touch ${SETTINGS_LOCKFILE}
  fi
fi

# TODO: move this into a more appropriate location
if [ ! -f /shared-volume/gunicorn.conf.py ]; then
  cat > /shared-volume/gunicorn.conf.py << EOF
import os

limit_request_fields = 0
error_logfile        = '-'
log_level            = 'debug'
timeout              = os.getenv('G3WSUITE_GUNICORN_TIMEOUT', 120)
workers              = os.getenv('G3WSUITE_GUNICORN_NUM_WORKERS', 8)
max_requests         = os.getenv('G3WSUITE_GUNICORN_MAX_REQUESTS', 200)
bind                 = '0.0.0.0:8000'
reload               = False if os.getenv('G3WSUITE_DEBUG', 'False') == 'False' else True
EOF
fi

# Build the suite
/code/ci_scripts/build_suite.sh
# Setup once
/code/ci_scripts/setup_suite.sh

gunicorn base.wsgi:application -c /shared-volume/gunicorn.conf.py