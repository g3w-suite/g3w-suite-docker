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


# Activate the front end app settings

if [[ "${FRONTEND}" =~ [Tt][Rr][Uu][Ee] ]] ; then
  SETTINGS_LOCKFILE=/shared-volume/.settings.lockfile
  if [[ ! -f ${SETTINGS_LOCKFILE} ]]; then
    echo "FRONTEND = True"  >> /code/g3w-admin/base/settings/local_settings.py
    echo "FRONTEND_APP = 'frontend'" >> /code/g3w-admin/base/settings/local_settings.py
    touch ${SETTINGS_LOCKFILE}
  fi
fi

# Build the suite
/code/ci_scripts/build_suite.sh
# Setup once
/code/ci_scripts/setup_suite.sh

gunicorn base.wsgi:application \
    --limit-request-fields 0 \
    --error-logfile - \
    --log-level=debug \
    --timeout ${G3WSUITE_GUNICORN_TIMEOUT:-120} \
    --workers=${G3WSUITE_GUNICORN_NUM_WORKERS:-8} \
    --max-requests=${G3WSUITE_GUNICORN_MAX_REQUESTS:-200} \
    -b 0.0.0.0:8000
