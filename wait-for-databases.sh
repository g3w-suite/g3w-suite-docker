#!/bin/bash

set -e

echo "test"

host="$1"
shift

until PGPASSWORD=${G3WSUITE_DATABASE_PASSWORD} psql -h "$host" -U ${G3WSUITE_DATABASE_USER} -d ${G3WSUITE_DATABASE_NAME} -P "pager=off" -c '\l'; do
  >&2 echo "${G3WSUITE_DATABASE_NAME} is unavailable - sleeping"
  sleep 1
done

>&2 echo "G3WSUITE databases are up - executing command"