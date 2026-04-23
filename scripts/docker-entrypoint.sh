#!/bin/bash
# Entrypoint for "g3w-suite" container
# ---------------------------------------

# Gis3W Sign
figlet -t "G3W-SUITE" && echo -e "v`git tag --sort=v:refname | tail -1 | sed 's/^v//'`\n"

echo -e "----------------------"
echo -e "IS_DEV: $(mountpoint -q /code && echo "True" || echo "False")"
echo -e "G3WSUITE_RUN_HUEY: ${G3WSUITE_RUN_HUEY}"
echo -e "G3WSUITE_CONSUMER: ${G3WSUITE_CONSUMER}"
echo -e "----------------------\n"

cd /code/g3w-admin

# HUEY CONSUMER
if [[ "${G3WSUITE_RUN_HUEY,,}" == "true" && "${G3WSUITE_CONSUMER}" == "0" ]]; then
  echo -e "START G3WSUITE_CONSUMER"
  # wait for main "g3w-suite" service
  wait-for-it -h g3w-suite -p 8000 -t 60
  # start the "g3w-suite-consumer" service
  /usr/bin/xvfb-run -a python3 manage.py run_huey
  exit $?
fi

# Start XVfb
rm -f /tmp/.X99-lock
Xvfb ${DISPLAY:-:99} -screen 0 640x480x24 -nolisten tcp &

# Activate the front end app settings
if [[ "${FRONTEND,,}" == "true" ]] ; then
  SETTINGS_LOCKFILE=/shared-volume/.settings.lockfile
  if [[ ! -f ${SETTINGS_LOCKFILE} ]]; then
    echo "FRONTEND = True"  >> /code/g3w-admin/base/settings/local_settings.py
    echo "FRONTEND_APP = 'frontend'" >> /code/g3w-admin/base/settings/local_settings.py
    touch ${SETTINGS_LOCKFILE}
  fi
fi

# TODO: move this into a more appropriate location (eg. g3w-admin ?)
if mountpoint -q /code || [ ! -f /shared-volume/gunicorn.conf.py ]; then
  # 1. install "debugpy"
  python3 -c "import debugpy" 2>/dev/null || python3 -m pip install debugpy
  
  # 2. inject a custom "gunicorn.conf.py"
  cat > /shared-volume/gunicorn.conf.py << EOF
import os, debugpy

DEBUG = os.getenv('G3WSUITE_DEBUG', 'False') == 'True' # os.path.ismount('/code')

if DEBUG:
    try:
        debugpy.listen(("0.0.0.0", 5678))
        print("--- Debugger listening on port 5678 ---")
    except Exception as e:
        print(f"Debugger error: {e}")

# gunicorn config
bind = '0.0.0.0:8000'
workers = os.getenv('G3WSUITE_GUNICORN_NUM_WORKERS', 8)
timeout = os.getenv('G3WSUITE_GUNICORN_TIMEOUT', 120)
max_requests = os.getenv('G3WSUITE_GUNICORN_MAX_REQUESTS', 200)

limit_request_fields = 0
error_logfile = '-'
log_level = 'debug' if DEBUG else 'info'
reload = DEBUG
EOF

  # 3. inject a custom "G3W-SUITE-DOCKER: Debugger" within local ".vscode/launch.json"
  python3 <<EOF
import json, os
path = "/code/.vscode/launch.json"

os.makedirs(os.path.dirname(path), exist_ok=True)

try:
    data = json.load(open(path))
except:
    data = {"version": "0.2.0", "configurations": []}

conf = {
    "name": "G3W-SUITE-DOCKER: Debugger",
    "type": "debugpy",
    "request": "attach",
    "connect": {"host": "localhost", "port": 5678},
    "pathMappings": [
        {
            "localRoot": "\${workspaceFolder}/g3w-admin",
            "remoteRoot": "/code/g3w-admin"
        }
    ],
    "justMyCode": False,
    "django": True
}

if not any(c.get("name") == conf["name"] for c in data["configurations"]):
    data.setdefault("configurations", []).append(conf)
    json.dump(data, open(path, "w"), indent=2)
EOF
fi

# Check Redis is started
wait-for-it -h ${G3WSUITE_REDIS_HOST:-redis} -p ${G3WSUITE_REDIS_PORT:-6379} -t 30

# DEV MODE: Check Python requirements  
if  mountpoint -q /code && [[ ! -e "/shared-volume/setup_done" ]]; then
  pip3 install -r /code/requirements.txt
fi

# Build the suite
/code/ci_scripts/build_suite.sh
# Setup once
/code/ci_scripts/setup_suite.sh

# DEV MODE: cleanup django database 
if mountpoint -q /code; then
  python3 /code/g3w-admin/manage.py check_features_locked
  python3 /code/g3w-admin/manage.py delete_unused_files
fi

gunicorn base.wsgi:application -c /shared-volume/gunicorn.conf.py
