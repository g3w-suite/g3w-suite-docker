


if [ -z "$(ls -A /code)" ]; then
   echo "Cloning g3w-admin branch ${G3W_SUITE_BRANCH:-v.3.6.x} ..."
   git clone https://github.com/g3w-suite/g3w-admin.git --single-branch --branch ${G3W_SUITE_BRANCH:-v.3.6.x} /code && \
   cd /code
fi

cp /requirements_rl.txt .

# Override settings
pip3 install -r requirements_rl.txt
pip3 install -r requirements_huey.txt

# Front end
#TODO make this as generic so that we can install as many plugins as possible
git submodule add -f https://github.com/g3w-suite/g3w-admin-frontend.git  g3w-admin/frontend


# Caching
pip3 install -r /code/g3w-admin/caching/requirements.txt

# File manager
pip3 install -r /code/g3w-admin/filemanager/requirements.txt

# Qplotly
pip3 install -r /code/g3w-admin/qplotly/requirements.txt

# Openrouteservice
pip3 install -r /code/g3w-admin/openrouteservice/requirements.txt

