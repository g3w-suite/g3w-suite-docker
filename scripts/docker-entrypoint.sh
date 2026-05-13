#!/bin/bash
# Entrypoint for "g3w-suite" container
# ---------------------------------------

# Gis3W Sign
figlet -t "G3W-SUITE" && echo -e "v`git tag --sort=v:refname | tail -1 | sed 's/^v//'`\n"

echo -e "----------------------"
echo -e "DEV_MODE: ${DEV_MODE}"
echo -e "BATCH_PROCESSING: ${G3WSUITE_RUN_HUEY}"
echo -e "----------------------\n"

cd /code/g3w-admin

# HUEY CONSUMER
if [[ "${G3WSUITE_RUN_HUEY,,}" == "true" && "${G3WSUITE_CONSUMER}" == "0" ]]; then
  echo -e "STARTING G3WSUITE_CONSUMER"
  # wait for main "g3w-suite" service
  wait-for-it -h g3w-suite -p 8000 -t 60
  # start the "g3w-suite-consumer" service
  /usr/bin/xvfb-run -a python3 manage.py run_huey
  exit $?
elif [[ "${G3WSUITE_CONSUMER}" == "0" ]]; then
  echo -e "STOPPING G3WSUITE_CONSUMER"
  exit $?
fi

# Start XVfb
rm -f /tmp/.X99-lock
Xvfb ${DISPLAY:-:99} -screen 0 640x480x24 -nolisten tcp &

# TODO: move this into a more appropriate location (eg. g3w-admin ?)
if [ ! -f /shared-volume/gunicorn.conf.py ] || [[ "${DEV_MODE,,}" == "true" ]]; then
  # 1. inject a custom "gunicorn.conf.py"
  cat > /shared-volume/gunicorn.conf.py << EOF
import os

DEBUG = os.getenv('G3WSUITE_DEBUG', 'False') == 'True' # os.path.ismount('/code')

if DEBUG:
    try:
        import debugpy
        debugpy.listen(("0.0.0.0", 5678))
        print("--- Debugger listening on port 5678 ---")
    except ImportError:
        print("--- Debug.py not installed: skipping ---")
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
fi

# DEV MODE: install debugpy
if [[ "${DEV_MODE,,}" == "true" ]]; then
  uv pip install debugpy
fi

# DEV MODE: check python requirements
if  [[ "${DEV_MODE,,}" == "true" ]] && [[ ! -e "/shared-volume/setup_done" ]]; then
  uv pip install -r /code/requirements.txt
  uv pip install --user -v -r <(
    find -L /code/plugins -maxdepth 1 -mindepth 1 -not -path '*/.*' -type d | while read -r path; do
      git config --global --add safe.directory "$path"
      echo "-e $path"
    done
  )
fi

# wait for "redis" container
wait-for-it -h ${G3WSUITE_REDIS_HOST:-redis} -p ${G3WSUITE_REDIS_PORT:-6379} -t 30  

# emit → /shared-volume/build_done
/code/ci_scripts/build_suite.sh 

# emit → /shared-volume/setup_done
/code/ci_scripts/setup_suite.sh 

# DEV MODE: cleanup django database
if [[ "${DEV_MODE,,}" == "true" ]]; then
  python3 /code/g3w-admin/manage.py check_features_locked
  python3 /code/g3w-admin/manage.py delete_unused_files
fi

# start django app
gunicorn base.wsgi:application -c /shared-volume/gunicorn.conf.py