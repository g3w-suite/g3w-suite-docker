#!/bin/bash
set -e


/usr/local/bin/invoke waitfordbs >> /usr/src/g3w-suite/invoke.log
echo "waitfordbs task done"

echo "running migrations"
/usr/local/bin/invoke migrations >> /usr/src/g3w-suite/invoke.log

exec $CMD