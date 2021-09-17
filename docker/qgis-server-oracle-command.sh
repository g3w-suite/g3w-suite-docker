# Starts the QGIS server inside the container on port 9333

/usr/bin/xvfb-run \
    -s "-ac -screen 0 1280x1024x16 +extension GLX +render -noreset" \
    /usr/bin/spawn-fcgi \
        -u www-data \
        -g www-data \
        -d /usr/lib/qgis/ \
        -n \
        -p 9333 \
        -- \
        /usr/bin/qgis_mapserv.fcgi