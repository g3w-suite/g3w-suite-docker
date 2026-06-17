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


# DEV MODE: check python requirements
if  [[ "${DEV_MODE,,}" == "true" ]]; then
  pkgs=("-r" "/code/requirements.txt")
  # local plugins (editable install)
  for path in /shared-volume/plugins/*; do
    [[ -e "$path" && ! "$path" =~ /\.[^/]*$ ]] || continue
    if [[ -d "$path" ]]; then
      git config --global --add safe.directory "$path"
      # HOTFIX: for invalid specifier
      if [[ -f "$path/pyproject.toml" ]]; then
        sed -i 's/Development Status :: 3 - Beta/Development Status :: 4 - Beta/g' "$path/pyproject.toml"
      fi
      pkgs+=("-e" "$path")
    fi
  done
  uv pip install -v "${pkgs[@]}"
fi

# wait for "redis" container
wait-for-it -h ${G3WSUITE_REDIS_HOST:-redis} -p ${G3WSUITE_REDIS_PORT:-6379} -t 30  

# emit → /shared-volume/setup_done
/code/ci_scripts/setup_suite.sh

# DEV MODE: cleanup django database
if [[ "${DEV_MODE,,}" == "true" ]]; then
  python3 /code/g3w-admin/manage.py check_features_locked
  python3 /code/g3w-admin/manage.py delete_unused_files
fi

# start django app
if [[ "${G3WSUITE_WEBSERVER,,}" == "granian" ]]; then
  granian base.wsgi_docker:application \
    --interface wsgi
    --host 0.0.0.0 \
    --port 8000 \
    --workers "${G3WSUITE_GUNICORN_NUM_WORKERS:-8}" \
    --log-level "$( [[ "${G3WSUITE_DEBUG,,}" == "true" ]] && echo debug || echo info )" \
    $( [[ "${G3WSUITE_DEBUG,,}" == "true" ]] && echo "--reload" )
else
  gunicorn base.wsgi_docker:application \
    --bind=0.0.0.0:8000 \
    --workers="${G3WSUITE_GUNICORN_NUM_WORKERS:-8}" \
    --timeout="${G3WSUITE_GUNICORN_TIMEOUT:-120}" \
    --max-requests="${G3WSUITE_GUNICORN_MAX_REQUESTS:-200}" \
    --limit-request-fields=0 \
    --error-logfile=- \
    --log-level="$( [[ "${G3WSUITE_DEBUG,,}" == "true" ]] && echo debug || echo info )" \
    $( [[ "${G3WSUITE_DEBUG,,}" == "true" ]] && echo "--reload" )
fi