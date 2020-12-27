#!/bin/bash
# Entrypoint script

# Start XVfb
if [[  -f /tmp/.X99-lock ]]; then
  rm /tmp/.X99-lock
fi
Xvfb :99 -screen 0 640x480x24 -nolisten tcp &
export DISPLAY=:99
export QGIS_SERVER_PARALLEL_RENDERING=1
# Start
cd /code/g3w-admin

rm -rf /shared-volume/build_done

# Activate the front end app settings

if [[ ${FRONTEND_APP} =~ [Tt][Rr][Uu][Ee] ]] ; then
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


# Run migrations to activate the front end app based on env variable
if [[ ${FRONTEND_APP} =~ [Tt][Rr][Uu][Ee] ]]; then
  python3 manage.py makemigrations
  python3 manage.py migrate
  python3 manage.py collectstatic --noinput
fi

gunicorn base.wsgi:application --limit-request-fields 0 --error-logfile - \
    --log-level=debug --timeout 120 --workers=${G3WSUITE_GUNICORN_NUM_WORKERS:-8} -b 0.0.0.0:8000
