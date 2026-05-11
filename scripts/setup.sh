# hotfix for Python 11: https://stackoverflow.com/a/76469774
export PIP_BREAK_SYSTEM_PACKAGES=1
export PIP_ROOT_USER_ACTION=ignore

if [ -z "$(ls -A /code)" ]; then
   echo "Cloning g3w-admin branch ${G3W_SUITE_BRANCH:-dev} ..."
   git clone https://github.com/g3w-suite/g3w-admin.git --single-branch --depth 1 --branch ${G3W_SUITE_BRANCH:-dev} /code && \
   cd /code
fi

# Front end
git submodule add -f https://github.com/g3w-suite/g3w-admin-frontend.git  g3w-admin/frontend

cp /requirements_rl.txt .

pip install -r requirements_rl.txt