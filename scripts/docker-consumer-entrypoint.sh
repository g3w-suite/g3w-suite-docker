#!/bin/bash
# Entrypoint script for consumer images.
# --------------------------------------

if [[ "${G3WSUITE_RUN_HUEY}" =~ [Tt][Rr][Uu][Ee] ]] ; then

    cd /code/g3w-admin

    # Wait for the main suite to start
    wait-for-it -h g3w-suite -p 8000 -t 60

    cd /code/g3w-admin

    ls /usr/local/lib/python3.6/dist-packages/

    # Start the consumer
    /usr/bin/xvfb-run -a python3 manage.py run_huey

fi