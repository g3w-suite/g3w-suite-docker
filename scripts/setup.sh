


if [ -z "$(ls -A /code)" ]; then
   echo "Cloning g3w-admin branch ${G3W_SUITE_BRANCH:-dev} ..."
   git clone https://github.com/g3w-suite/g3w-admin.git --single-branch --depth 1 --branch ${G3W_SUITE_BRANCH:-dev} /code && \
   cd /code
fi

cp /requirements_rl.txt .

# Override settings
pip3 install -r requirements_rl.txt --break-system-packages
pip3 install -r requirements_huey.txt --break-system-packages

# Front end
#TODO make this as generic so that we can install as many plugins as possible
git submodule add -f https://github.com/g3w-suite/g3w-admin-frontend.git  g3w-admin/frontend


# Caching
pip3 install -r /code/g3w-admin/caching/requirements.txt --break-system-packages

# File manager
pip3 install -r /code/g3w-admin/filemanager/requirements.txt --break-system-packages

# Qplotly
pip3 install -r /code/g3w-admin/qplotly/requirements.txt --break-system-packages

# Openrouteservice
pip3 install -r /code/g3w-admin/openrouteservice/requirements.txt --break-system-packages

