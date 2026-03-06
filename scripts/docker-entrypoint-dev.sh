#!/bin/bash
# Entrypoint script for Development purposes.
# -------------------------------------------

# To get git properties loose on code overrides.
git config --global --add safe.directory /code

figlet -t "G3W-SUITE" && echo -e "v`git tag --sort=v:refname | tail -1 | sed 's/^v//'`\n"

# Start XVfb
if [[  -f /tmp/.X99-lock ]]; then
  rm /tmp/.X99-lock
fi
Xvfb :99 -screen 0 640x480x24 -nolisten tcp &

export DISPLAY=:99
export QGIS_SERVER_PARALLEL_RENDERING=1

# hotfix for Python 11: https://stackoverflow.com/a/76469774
export PIP_BREAK_SYSTEM_PACKAGES=1
export PIP_ROOT_USER_ACTION=ignore

if [ ! -e "/shared-volume/setup_done" ]; then
  pip3 install -r /code/requirements.txt
fi

# Start
cd /code/g3w-admin

# Build the suite
/code/ci_scripts/build_suite.sh
# Setup once
/code/ci_scripts/setup_suite.sh

python3 /code/g3w-admin/manage.py check_features_locked
python3 /code/g3w-admin/manage.py delete_unused_files

# hotfix for Ubuntu Jammy: https://github.com/pypa/setuptools/issues/3269#issuecomment-1254507377
export DEB_PYTHON_INSTALL_LAYOUT=deb_system

# Start Django server
gunicorn base.wsgi:application -c /shared-volume/gunicorn.conf.py
