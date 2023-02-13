#!/usr/bin/env bash

if [ -z "$(ls -A /code)" ]; then
   echo "Cloning g3w-admin branch ${G3W_SUITE_BRANCH:-dev} ..."
   git clone https://github.com/g3w-suite/g3w-admin.git --single-branch --branch ${G3W_SUITE_BRANCH:-dev} /code && \
   cd /code
fi

cp /requirements_rl.txt .

# Override settings
pip3 install -r requirements_rl.txt
pip3 install -r requirements_huey.txt

# Front end
#TODO make this as generic so that we can install as many plugins as possible
git submodule add -f https://github.com/g3w-suite/g3w-admin-frontend.git  g3w-admin/frontend


# Install caching ; file manager, Qplotly Openrouteservice
array=(caching filemanager qplotly openrouteservice)
for i in "${array[@]}"; do
  # Sanity check for the directory existence
  if [[ -d /code/g3w-admin/${i} ]];then
      pip3 install -r /code/g3w-admin/"${i}"/requirements.txt
  fi
done


