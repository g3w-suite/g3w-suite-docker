#!/bin/bash
# Entrypoint for "g3w-suite" container
# ---------------------------------------

# Gis3W Sign
figlet -t "G3W-SUITE Docker by Gis3w"

# Start XVfb
if [[  -f /tmp/.X99-lock ]]; then
  rm /tmp/.X99-lock
fi
Xvfb ${DISPLAY:-:99} -screen 0 640x480x24 -nolisten tcp &

# Start
cd /code/g3w-admin

# DEV MODE
if [[ -z "${G3WSUITE_LOCAL_CODE_PATH}" ]] ; then
  # To get git properties loose on code overrides.
  git config --global --add safe.directory /code
  # hotfix for Python 11: https://stackoverflow.com/a/76469774
  export PIP_BREAK_SYSTEM_PACKAGES=1
  export PIP_ROOT_USER_ACTION=ignore
  # check python requirements  
  if [ ! -e "/shared-volume/setup_done" ]; then
    pip3 install -r /code/requirements.txt
  fi
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

# TODO: move this into a more appropriate location (eg. g3w-admin ?)
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

# Check Redis is started
wait-for-it -h ${G3WSUITE_REDIS_HOST:-redis} -p ${G3WSUITE_REDIS_PORT:-6379} -t 30

# Build the suite
/code/ci_scripts/build_suite.sh
# Setup once
/code/ci_scripts/setup_suite.sh

# DEV MODE
if [[ -z "${G3WSUITE_LOCAL_CODE_PATH}" ]] ; then
  python3 /code/g3w-admin/manage.py check_features_locked
  python3 /code/g3w-admin/manage.py delete_unused_files

  # hotfix for Ubuntu Jammy: https://github.com/pypa/setuptools/issues/3269#issuecomment-1254507377
  export DEB_PYTHON_INSTALL_LAYOUT=deb_system
fi

gunicorn base.wsgi:application -c /shared-volume/gunicorn.conf.py
